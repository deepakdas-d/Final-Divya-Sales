import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LostLeadsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final leads = <DocumentSnapshot>[].obs;
  final searchQuery = ''.obs;
  final isLoading = true.obs; // Added for shimmer effect
  final isFetchingMoreLeads = false.obs;
  final hasMoreLeads = true.obs;

  DocumentSnapshot? lastDocument;

  @override
  void onInit() {
    super.onInit();
    fetchLeads();
  }

  Future<void> fetchLeads({bool loadMore = false}) async {
    if (loadMore) {
      if (isFetchingMoreLeads.value || !hasMoreLeads.value) return;
    }

    try {
      if (!loadMore) {
        lastDocument = null;
        hasMoreLeads.value = true;
        isLoading.value = true; // Set loading true for initial fetch
      }
      if (loadMore) {
        isFetchingMoreLeads.value = true;
      }

      Query query = _firestore
          .collection('Leads')
          .where('isArchived', isEqualTo: true) // ✅ archived leads
          .where(
            'salesmanID',
            isEqualTo: FirebaseAuth.instance.currentUser!.uid,
          )
          .orderBy('followUpDate', descending: false)
          .limit(20);

      // ✅ Search filter
      if (searchQuery.value.isNotEmpty) {
        final q = searchQuery.value.trim().toLowerCase();
        query = _firestore
            .collection('Leads')
            .where('isArchived', isEqualTo: true)
            .where(
              'salesmanID',
              isEqualTo: FirebaseAuth.instance.currentUser!.uid,
            )
            .orderBy('name')
            .startAt([q])
            .endAt([q + '\uf8ff'])
            .limit(20);
      }

      if (loadMore && lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        if (loadMore) {
          leads.addAll(snapshot.docs);
        } else {
          leads.assignAll(snapshot.docs);
        }
        lastDocument = snapshot.docs.last;
      } else {
        hasMoreLeads.value = false;
      }
    } catch (e) {
      Get.snackbar(
        'Oops!',
        'Failed to load leads: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false; // Reset loading state
      if (loadMore) {
        isFetchingMoreLeads.value = false;
      }
    }
  }
}
