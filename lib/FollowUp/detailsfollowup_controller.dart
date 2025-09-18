import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sales/Home/home.dart';

class LeadDetailsController extends GetxController {
  final String? leadId; // To receive leadId for existing leads

  LeadDetailsController({this.leadId});

  // Text Editing Controllers
  final nameController = TextEditingController();
  final placeController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final phone2Controller = TextEditingController();
  final nosController = TextEditingController();
  final remarkController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  // Rx Variables for reactive UI updates
  var selectedProductId = Rxn<String>();
  var selectedStatus = Rxn<String>();
  var selectedTime = Rxn<TimeOfDay>();
  var followUpDate = Rxn<DateTime>();
  var productImageUrl = Rxn<String>();
  var productIdList = <String>[].obs;
  final makerList = <Map<String, dynamic>>[].obs;
  final selectedMakerId = RxnString();
  final statusList = ['HOT', 'WARM', 'COOL'].obs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  var productStockMap = <String, int>{}.obs;
  var deliveryDate = Rxn<DateTime>();
  RxInt followUpCount = 0.obs;

  // New Rx variables for managing page state
  var isLoading = true.obs;
  var isEditing = false.obs; // Controls edit mode
  var isUpdateMode = false.obs; // True if editing an existing lead

  // Private variable to store the actual Firestore document ID of the lead
  String? _currentLeadDocId;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
    fetchMakers();

    if (leadId != null) {
      isUpdateMode.value = true;
      isEditing.value = false; // Start in view mode for existing leads
      initializeLeadDetails(leadId!);
    }
    ever(selectedStatus, (String? status) {
      if (status != 'HOT') {
        selectedMakerId.value = null;
      }
      if (status == 'HOT') {
        followUpDate.value = null;
      }
    });
    //count for UI display
    log("Current Lead Doc ID: $leadId");

    if (leadId != null) {
      log("Current Lead Doc ID: $leadId");
      _loadFollowUpCount();
    }
  }

  Future<void> _loadFollowUpCount() async {
    log("➡️ Loading followUpCount for $leadId");
    final count = await fetchFollowUpCount(leadId!);
    followUpCount.value = count; // 🔥 assign here
    log("✅ Updated followUpCount.value = ${followUpCount.value}");
  }

  // Method to fetch and populate lead details for an existing lead
  Future<void> initializeLeadDetails(String leadFirebaseDocId) async {
    try {
      isLoading.value = true;
      final leadDoc = await _firestore
          .collection('Leads')
          .doc(leadFirebaseDocId)
          .get();

      if (leadDoc.exists) {
        _currentLeadDocId = leadDoc.id; // Store the document ID
        final data = leadDoc.data()!;

        nameController.text = data['name'] ?? '';
        placeController.text = data['place'] ?? '';
        addressController.text = data['address'] ?? '';
        phoneController.text = data['phone1'] ?? '';
        phone2Controller.text = data['phone2'] ?? '';
        nosController.text = data['nos']?.toString() ?? '';
        remarkController.text = data['remark'] ?? '';

        selectedProductId.value = data['productID'] as String?;
        selectedStatus.value = data['status'] as String?;
        selectedMakerId.value = data['makerId'] as String?;
        followUpCount.value = data['followUpCount'] ?? 0;

        if (data['followUpDate'] != null) {
          followUpDate.value = (data['followUpDate'] as Timestamp).toDate();
        } else {
          followUpDate.value = null;
        }

        if (selectedProductId.value != null) {
          await fetchProductImage(selectedProductId.value!);
        }
      } else {
        Get.snackbar(
          'Oops!',
          'Lead not found!',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        Get.back();
      }
    } catch (e) {
      Get.snackbar(
        'Oops!',
        'Failed to load lead details: $e',
        backgroundColor: Colors.white,
        colorText: Colors.red,
      );
      Get.back();
    } finally {
      isLoading.value = false;
    }
  }

  // Toggle between view and edit modes
  void toggleEditing() {
    if (isEditing.value) {
      // If currently editing, try to save
      saveLead();
    }
    isEditing.value = !isEditing.value;
  }

  Future<void> fetchMakers() async {
    try {
      makerList.clear(); // Clear existing data
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'maker')
          .get();

      makerList.value = snapshot.docs.map((doc) {
        return {'id': doc.id, 'name': doc['name'] ?? 'Unknown'};
      }).toList();

      if (makerList.isEmpty) {
        Get.snackbar(
          'Warning',
          'No makers found',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Oops!',
        'Failed to load makers: $e',
        backgroundColor: Colors.white,
        colorText: Colors.red,
      );
    }
  }

  Future<void> fetchProducts() async {
    try {
      final snapshot = await _firestore.collection('products').get();

      final products = <String>[];
      final stockMap = <String, int>{};

      for (var doc in snapshot.docs) {
        final id = doc.data()['id']?.toString() ?? doc.id;
        final stock = doc.data()['stock'] ?? 0;
        products.add(id);
        stockMap[id] = stock;
      }

      productIdList.assignAll(products);
      productStockMap.assignAll(stockMap);

      // debugPrint('Fetched product IDs: $products');
      // debugPrint('Fetched product stock: $stockMap');
    } catch (e) {
      Get.snackbar(
        'Oops!',
        'Oops! fetching products: $e',
        backgroundColor: Colors.white,
        colorText: Colors.red,
      );
    }
  }

  Future<void> fetchProductImage(String productId) async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('id', isEqualTo: productId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('No document found for product ID: $productId');
        productImageUrl.value = null;
        return;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      final imageUrl = data['imageUrl'] as String?;
      debugPrint('Fetched imageUrl for $productId: $imageUrl');

      productImageUrl.value = imageUrl;
    } catch (e) {
      debugPrint('Oops! fetching image for $productId: $e');
      productImageUrl.value = null;
      Get.snackbar(
        'Oops!',
        'Oops! loading image: $e',
        backgroundColor: Colors.white,
        colorText: Colors.red,
      );
    }
  }

  Future<String> _generateLeadsId() async {
    final snapshot = await _firestore
        .collection('Leads')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    int lastNumber = 0;

    if (snapshot.docs.isNotEmpty) {
      final lastId = snapshot.docs.first.data()['leadId'] as String?;
      if (lastId != null && lastId.startsWith('LEA')) {
        final numberPart = int.tryParse(lastId.replaceAll('LEA', '')) ?? 0;
        lastNumber = numberPart;
      }
    }

    final newNumber = lastNumber + 1;
    return 'LEA${newNumber.toString().padLeft(5, '0')}';
  }

  Future<int> fetchFollowUpCount(String docId) async {
    log("➡️ Starting fetchFollowUpCount for docId: $docId");

    try {
      log("📌 Fetching document from Firestore...");
      final docSnapshot = await FirebaseFirestore.instance
          .collection('Leads')
          .doc(docId)
          .get();

      log("📌 Document fetched. Exists: ${docSnapshot.exists}");

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        log("📌 Document data: $data");

        if (data != null && data.containsKey('followUpCount')) {
          final count = data['followUpCount'] ?? 0;
          log("✅ followUpCount found: $count");
          return count;
        } else {
          log("⚠️ No 'followUpCount' field found in document");
        }
      } else {
        log("⚠️ Document does not exist");
      }

      return 0; // default if not found
    } catch (e, stack) {
      log("❌ Error fetching followUpCount: $e");
      log("Stacktrace: $stack");
      return 0;
    }
  }

  Future<void> saveLead() async {
    if (!formKey.currentState!.validate()) {
      Get.snackbar(
        'Oops!',
        'Please fill all required fields correctly',
        backgroundColor: Colors.white,
        colorText: Colors.red,
      );
      return;
    }

    if (selectedStatus.value != 'HOT' && followUpDate.value == null) {
      Get.snackbar(
        'Oops!',
        'Please select follow-up date for WARM/COOL status',
        backgroundColor: Colors.white,
        colorText: Colors.red,
      );
      return;
    }

    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('id', isEqualTo: selectedProductId.value)
          .limit(1)
          .get();

      String productIdFromDoc;

      if (querySnapshot.docs.isEmpty) {
        // Fallback: use the selectedProductId.value directly
        productIdFromDoc = selectedProductId.value!;
      } else {
        final productDoc = querySnapshot.docs.first;
        productIdFromDoc = productDoc['id'];
      } // This is the 'id' field inside the document

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Get.snackbar(
          'Oops!',
          'User not logged in',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      final userId = currentUser.uid;

      // Get the current followUpCount if updating
      int newFollowUpCount = 0;
      if (isUpdateMode.value && _currentLeadDocId != null) {
        // Fetch current lead data to get the existing followUpCount
        final currentLeadDoc = await _firestore
            .collection('Leads')
            .doc(_currentLeadDocId)
            .get();

        if (currentLeadDoc.exists) {
          // Increment the existing count
          newFollowUpCount = (currentLeadDoc.data()?['followUpCount'] ?? 0) + 1;
        }
      }

      Map<String, dynamic> leadData = {
        'name': nameController.text,
        'place': placeController.text,
        'address': addressController.text,
        'phone1': phoneController.text,
        'phone2': phone2Controller.text.isNotEmpty
            ? phone2Controller.text
            : null,
        'productID': productIdFromDoc,
        'nos': int.tryParse(nosController.text) ?? 0,
        'remark': remarkController.text.isNotEmpty
            ? remarkController.text
            : null,
        'status': selectedStatus.value,
        'followUpDate': followUpDate.value != null
            ? Timestamp.fromDate(followUpDate.value!)
            : null,
        'followUpTime': selectedTime.value != null
            ? "${selectedTime.value!.hour.toString().padLeft(2, '0')}:${selectedTime.value!.minute.toString().padLeft(2, '0')}"
            : "",
        'salesmanID': userId,
        'isArchived': false,
        'followUpCount': newFollowUpCount, // Add the follow-up count
        'lastFollowUp': Timestamp.now(), // Add timestamp of last follow-up
      };

      if (isUpdateMode.value && _currentLeadDocId != null) {
        log('Updating lead with data: $_currentLeadDocId');
        // Update existing lead
        await _firestore
            .collection('Leads')
            .doc(_currentLeadDocId)
            .update(leadData);
        Get.snackbar(
          'Success',
          'Lead updated successfully!',
          backgroundColor: Colors.white,
          colorText: Color(0xFF014185),
        );
      } else {
        // Create new lead
        final leadId = await _generateLeadsId();
        leadData['leadId'] = leadId;
        leadData['createdAt'] = Timestamp.now();
        leadData['followUpCount'] = 0; // Start with 0 for new leads
        await _firestore.collection('Leads').add(leadData);
        Get.snackbar(
          'Success',
          'New lead created successfully!',
          backgroundColor: Colors.white,
          colorText: Color(0xFF014185),
        );
        clearForm(); // Clear form after creating a new lead
      }
      isEditing.value = false;
      // Switch back to view mode after saving
    } catch (e) {
      Get.snackbar(
        'Oops!',
        'Oops! saving lead: $e',
        backgroundColor: Colors.white,
        colorText: Colors.red,
      );
      debugPrint('Oops! saving lead: $e');
    }
  }

  Future<String> getOrCreateCustomerId({
    required String name,
    required String phone,
    required String place,
    required String address,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('Customers')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // ✅ Return existing customerId
        final existingCustomerId = snapshot.docs.first.data()['customerId'];
        return existingCustomerId;
      }

      // ❌ No existing customer, create a new one
      final newCustomerId = await generateCustomerId();
      await _firestore.collection('Customers').add({
        'customerId': newCustomerId,
        'name': name,
        'phone': phone,
        'place': place,
        'address': address,
        'createdAt': Timestamp.now(),
      });

      return newCustomerId;
    } catch (e) {
      Get.snackbar(
        'Oops!',
        'Failed to get or create customer: $e',
        backgroundColor: Colors.white,
        colorText: Color(0xFF014185),
      );
      rethrow;
    }
  }

  Future<String> generateCustomerId() async {
    final snapshot = await _firestore
        .collection('Customers')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    int lastNumber = 0;
    if (snapshot.docs.isNotEmpty) {
      final lastId = snapshot.docs.first.data()['customerId'] as String?;
      if (lastId != null && lastId.startsWith('CUS')) {
        final numberPart = int.tryParse(lastId.replaceAll('CUS', '')) ?? 0;
        lastNumber = numberPart;
      }
    }

    final newNumber = lastNumber + 1;
    return 'CUS${newNumber.toString().padLeft(5, '0')}';
  }

  Future<void> placeOrder(String leadDocId) async {
    if (!formKey.currentState!.validate() || selectedMakerId.value == null) {
      Get.snackbar(
        'Oops!',
        'Please fill all required fields correctly',
        backgroundColor: Colors.white,
        colorText: Colors.red,
      );
      return;
    }

    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('id', isEqualTo: selectedProductId.value)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        Get.snackbar(
          'Oops!',
          'Selected product not found',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final productDoc = querySnapshot.docs.first;
      final docId = productDoc.id;
      final productId = productDoc['id'];
      final currentStock = productDoc['stock'];

      final orderedQuantity = int.tryParse(nosController.text) ?? 0;
      if (orderedQuantity <= 0) {
        Get.snackbar(
          'Oops!',
          'Invalid number of items ordered',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (currentStock > 0) {
        final updatedStock = currentStock - orderedQuantity;
        await _firestore.collection('products').doc(docId).update({
          'stock': updatedStock,
        });
        productStockMap[selectedProductId.value!] = updatedStock;
      }

      final newOrderId = await generateCustomOrderId();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Get.snackbar(
          'Oops!',
          'User not logged in',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      final customerId = await getOrCreateCustomerId(
        name: nameController.text,
        phone: phoneController.text,
        place: placeController.text,
        address: addressController.text,
      );

      final userId = currentUser.uid;

      await _firestore.collection('Orders').add({
        'orderId': newOrderId,
        'name': nameController.text,
        'place': placeController.text,
        'address': addressController.text,
        'phone1': phoneController.text,
        'phone2': phone2Controller.text.isNotEmpty
            ? phone2Controller.text
            : null,
        'productID': productId,
        'nos': orderedQuantity,
        'remark': remarkController.text.isNotEmpty
            ? remarkController.text
            : null,
        'status': selectedStatus.value,
        'makerId': selectedMakerId.value,
        'followUpDate': followUpDate.value != null
            ? Timestamp.fromDate(followUpDate.value!)
            : null,
        'salesmanID': userId,
        'deliveryDate': deliveryDate.value != null
            ? Timestamp.fromDate(deliveryDate.value!)
            : null,
        'createdAt': Timestamp.now(),
        'order_status': "pending",
        'cancel': false,
        'customerId': customerId,
      });
      final makerId = selectedMakerId.value;

      // ✅ Delete from Leads collection using the correct doc ID
      await _firestore.collection('Leads').doc(leadDocId).delete();
      await _firestore.collection('users').doc(userId).set({
        'totalLeads': FieldValue.increment(-1),
      }, SetOptions(merge: true));
      await _firestore.collection('users').doc(userId).set({
        'totalOrders': FieldValue.increment(1),
      }, SetOptions(merge: true));
      await _firestore.collection('users').doc(makerId).set({
        'totalOrders': FieldValue.increment(1),
        'pendingOrders': FieldValue.increment(1),
      }, SetOptions(merge: true));

      Get.snackbar(
        'Success',
        'Order placed successfully',
        backgroundColor: Colors.white,
        colorText: Color(0xFF014185),
      );
      clearForm();

      Get.offAll(Home());
    } catch (e) {
      Get.snackbar(
        'Oops!',
        'Oops! placing order: $e',
        backgroundColor: Colors.white,
        colorText: Colors.red,
      );
    }
  }

  Future<String> generateCustomOrderId() async {
    final snapshot = await _firestore
        .collection('Orders')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    int lastNumber = 0;

    if (snapshot.docs.isNotEmpty) {
      final lastId = snapshot.docs.first.data()['orderId'] as String?;
      if (lastId != null && lastId.startsWith('ORD')) {
        final numberPart = int.tryParse(lastId.replaceAll('ORD', '')) ?? 0;
        lastNumber = numberPart;
      }
    }

    final newNumber = lastNumber + 1;
    return 'ORD${newNumber.toString().padLeft(5, '0')}';
  }

  // Adjusted button enablement logic
  bool isOrderButtonEnabled() {
    // Only enable if in view mode for an existing lead (if you want to restrict ordering to saved leads only)
    // or if creating a new lead with HOT status
    return selectedStatus.value == 'HOT' &&
        isEditing.value &&
        selectedMakerId.value != null;
  }

  void clearForm() {
    nameController.clear();
    placeController.clear();
    addressController.clear();
    phoneController.clear();
    phone2Controller.clear();
    nosController.clear();
    remarkController.clear();

    selectedProductId.value = null;
    selectedStatus.value = null;
    selectedMakerId.value = null;
    followUpDate.value = null;
    productImageUrl.value = null;
    isUpdateMode.value = false; // Reset to creation mode
    isEditing.value = true; // For new leads, editing is allowed by default
    _currentLeadDocId = null; // Clear the current lead ID
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) return 'Name is required';
    if (value.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? validatePlace(String? value) {
    if (value == null || value.isEmpty) return 'Place is required';
    return null;
  }

  String? validateAddress(String? value) {
    if (value == null || value.isEmpty) return 'Address is required';
    if (value.length < 5) return 'Address must be at least 5 characters';
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';

    // Allow optional +, and length 10 to 15 digits
    final regex = RegExp(r'^\+?[0-9]{10,15}$');

    if (!regex.hasMatch(value)) {
      return 'Enter a valid phone number (10–15 digits)';
    }

    return null;
  }

  String? validatePhone2(String? value) {
    if (value == null || value.isEmpty) return null; // Optional field

    if (value == phoneController.text) {
      return 'Phone 2 should be different from Phone 1';
    }

    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Enter a valid 10-digit phone number';
    }

    return null;
  }

  String? validateNos(String? value) {
    if (value == null || value.isEmpty) return 'Quantity (NOS) is required';
    final int? nos = int.tryParse(value);
    if (nos == null || nos <= 0) return 'Enter a valid number greater than 0';
    return null;
  }

  Future<void> archiveDocument(String leadDocId) async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    try {
      await _firestore.collection('Leads').doc(leadDocId).update({
        'isArchived': true,
      });
      final userRef = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);

        if (!snapshot.exists) return;

        final currentLeads = (snapshot.data()?['totalLeads'] ?? 0) as int;

        if (currentLeads > 0) {
          transaction.update(userRef, {'totalLeads': FieldValue.increment(-1)});
        } else {
          // ensure it stays at 0
          transaction.update(userRef, {'totalLeads': 0});
        }
      });

      Get.snackbar(
        'Success',
        'Lead archived successfully',
        backgroundColor: Colors.white,
        colorText: Colors.red,
      );
      Navigator.of(
        Get.context!,
      ).pop(); // Optional: pop the screen after archiving
    } catch (e) {
      Get.snackbar(
        'Oops!',
        'Failed to archive lead: $e',
        backgroundColor: Colors.white,
        colorText: Colors.red,
      );
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    placeController.dispose();
    addressController.dispose();
    phoneController.dispose();
    phone2Controller.dispose();
    nosController.dispose();
    remarkController.dispose();
    // Dispose balance controller
    super.onClose();
  }
}
