import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sales/Lead/lead_management_controller.dart';
import 'package:shimmer/shimmer.dart';

class LeadManagement extends StatelessWidget {
  const LeadManagement({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LeadManagementController());
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF014185),
        elevation: 0,
        title: Text(
          "Lead Management",
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.w600,
            fontSize: MediaQuery.of(context).size.height * 0.025,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Get.back();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(), // Ensures ordered focus traversal
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Personal Information Section
                buildSectionTitle("Personal Information", context),
                SizedBox(height: screenHeight * 0.014),

                FocusTraversalOrder(
                  order: const NumericFocusOrder(0),
                  child: buildTextField(
                    context,
                    "Full Name",

                    controller: controller.nameController,
                    validator: controller.validateName,
                    icon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                  ),
                ),

                Obx(() {
                  return buildDropdownWithOtherField<String>(
                    context,
                    label: "District",
                    controller: controller.districtController,
                    value: controller.selectedDistrict.value,
                    items: controller.districts,
                    icon: Icons.location_city_outlined,
                    onChanged: (val) {
                      controller.selectedDistrict.value = val;
                      controller.selectedTaluk.value = null; // reset taluk
                      controller.talukController
                          .clear(); // clear taluk textfield
                    },
                  );
                }),

                const SizedBox(height: 12),

                /// Taluk Dropdown (only visible if district selected)
                Obx(() {
                  if (controller.selectedDistrict.value == null) {
                    return const SizedBox.shrink();
                  }

                  return buildDropdownWithOtherField<String>(
                    context,
                    label: "Taluk",
                    controller: controller.talukController,
                    value: controller.selectedTaluk.value,
                    items: controller.taluks,
                    icon: Icons.map_outlined,
                    onChanged: (val) {
                      controller.selectedTaluk.value = val;
                    },
                  );
                }),
                SizedBox(height: screenHeight * 0.016),

                buildTextField(
                  context,
                  "Address",
                  controller: controller.addressController,
                  validator: controller.validateAddress,
                  icon: Icons.home_outlined,
                  maxLines: 3, // allow unlimited lines
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                ),

                // Contact Information Section
                SizedBox(height: screenHeight * 0.016),
                buildSectionTitle("Contact Information", context),
                SizedBox(height: screenHeight * 0.014),

                FocusTraversalOrder(
                  order: const NumericFocusOrder(3),
                  child: buildTextField(
                    context,
                    "Primary Phone",
                    controller: controller.phoneController,
                    validator: controller.validatePhone,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                ),

                FocusTraversalOrder(
                  order: const NumericFocusOrder(4),
                  child: buildTextField(
                    context,
                    "Secondary Phone (Optional)",
                    controller: controller.phone2Controller,
                    validator: controller.validatePhone2,
                    icon: Icons.phone_android_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                ),

                // Product Information Section
                SizedBox(height: screenHeight * 0.016),
                buildSectionTitle("Product Information", context),
                SizedBox(height: screenHeight * 0.014),

                FocusTraversalOrder(
                  order: const NumericFocusOrder(5),
                  child: Obx(() {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Modal trigger header
                        GestureDetector(
                          onTap: () {
                            _showProductSelectionModal(context, controller);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  (controller.selectedProductId.value == null ||
                                          controller
                                              .selectedProductId
                                              .value!
                                              .isEmpty)
                                      ? "-- Select Product --"
                                      : controller.selectedProductId.value!,
                                ),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),

                SizedBox(height: screenHeight * 0.016),
                Center(
                  child: Obx(() {
                    final imageUrl = controller.productImageUrl.value;
                    if (imageUrl == null || imageUrl.isEmpty) {
                      return Container(
                        width: screenHeight * 0.25,
                        height: screenHeight * 0.25,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_outlined,
                                size: 32,
                                color: Color(0xFF9CA3AF),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'No Image Available',
                                style: GoogleFonts.k2d(
                                  color: Color(0xFF6B7280),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: screenHeight * 0.25,
                        height: screenHeight * 0.25,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: screenHeight * 0.25,
                          height: screenHeight * 0.25,
                          color: const Color(0xFFF9FAFB),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: screenHeight * 0.25,
                          height: screenHeight * 0.25,
                          color: const Color(0xFFF9FAFB),
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Color(0xFF9CA3AF),
                            size: 32,
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                Obx(() {
                  final productId = controller.selectedProductId.value;
                  if (productId == null) return const SizedBox();
                  return buildStockStatus(productId, screenHeight, controller);
                }),
                SizedBox(height: screenHeight * 0.016),

                FocusTraversalOrder(
                  order: const NumericFocusOrder(6),
                  child: buildTextFieldForNumber(
                    context,
                    "Quantity (NOS)",
                    controller: controller.nosController,
                    validator: controller.validateNos,
                    textInputAction: TextInputAction.next,
                  ),
                ),

                FocusTraversalOrder(
                  order: const NumericFocusOrder(7),
                  child: buildTextField(
                    context,
                    "Remarks (Optional)",
                    controller: controller.remarkController,
                    icon: Icons.note_outlined,
                    maxLines: 2,
                    textInputAction: TextInputAction.next,
                  ),
                ),

                // Order Status Section
                SizedBox(height: screenHeight * 0.014),
                buildSectionTitle("Order Status", context),
                SizedBox(height: screenHeight * 0.014),

                FocusTraversalOrder(
                  order: const NumericFocusOrder(8),
                  child: Obx(
                    () => buildDropdownField(
                      context,
                      label: "Status",
                      value: controller.selectedStatus.value,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text("-- Select Status --"),
                        ),
                        ...controller.statusList.map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        ),
                      ],
                      onChanged: controller.selectedProductId.value != null
                          ? (value) => controller.selectedStatus.value =
                                value as String?
                          : null,
                      validator: (value) =>
                          value == null ? 'Status is required' : null,
                      icon: Icons.flag_outlined,
                      isEnabled: controller.selectedProductId.value != null,
                      disabledHint: "Select a product first",
                    ),
                  ),
                ),

                Obx(() {
                  final status = controller.selectedStatus.value;
                  final isEnabled =
                      controller.selectedProductId.value != null &&
                      controller.selectedStatus.value == 'HOT';
                  if (status != 'HOT' &&
                      controller.selectedMakerId.value != null) {
                    controller.selectedMakerId.value = null;
                  }
                  final isLoading =
                      controller.makerList.isEmpty &&
                      !controller.makerList.isNull;

                  if (isLoading) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    );
                  }
                  if (status == "COOL" || status == "WARM") {
                    return const SizedBox.shrink();
                  }

                  return FocusTraversalOrder(
                    order: const NumericFocusOrder(9),
                    child: buildDropdownField(
                      context,
                      label: "Maker",
                      value: controller.selectedMakerId.value,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text("-- Select Maker --"),
                        ),
                        ...controller.makerList.map((maker) {
                          return DropdownMenuItem<String>(
                            value: maker['id'],
                            child: Text(maker['name']),
                          );
                        }).toList(),
                      ],
                      onChanged: isEnabled
                          ? (value) => controller.selectedMakerId.value =
                                value as String?
                          : null,
                      validator: (value) =>
                          value == null &&
                              controller.selectedStatus.value == 'HOT'
                          ? 'Please select a maker'
                          : null,
                      icon: Icons.engineering_outlined,
                      isEnabled: isEnabled,
                      disabledHint: controller.selectedProductId.value == null
                          ? "Select a product first"
                          : "Maker is only needed for HOT status",
                    ),
                  );
                }),

                Obx(() {
                  final status = controller.selectedStatus.value;

                  //  only show for HOT orders, adjust if needed
                  if (status != "HOT") {
                    return const SizedBox.shrink();
                  }

                  return FocusTraversalOrder(
                    order: const NumericFocusOrder(11),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        focusColor: Colors.transparent,
                        onTap: () async {
                          DateTime today = DateTime.now();
                          DateTime onlyDate = DateTime(
                            today.year,
                            today.month,
                            today.day,
                          );

                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate:
                                controller.deliveryDate.value ?? onlyDate,
                            firstDate: onlyDate,
                            lastDate: DateTime(2035),
                          );

                          if (picked != null) {
                            controller.deliveryDate.value = picked;
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFD1D5DB)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.local_shipping_outlined,
                                size: 20,
                                color: Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  controller.deliveryDate.value == null
                                      ? "Select Delivery Date"
                                      : DateFormat('dd-MM-yyyy').format(
                                          controller.deliveryDate.value!,
                                        ),
                                  style: GoogleFonts.k2d(
                                    fontSize: 14,
                                    color: controller.deliveryDate.value == null
                                        ? const Color(0xFF6B7280)
                                        : const Color(0xFF111827),
                                  ),
                                ),
                              ),
                              if (controller.deliveryDate.value != null)
                                GestureDetector(
                                  onTap: () =>
                                      controller.deliveryDate.value = null,
                                  child: const Icon(
                                    Icons.clear,
                                    color: Color(0xFF9CA3AF),
                                    size: 18,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                Obx(() {
                  final selectedStatus = controller.selectedStatus.value;

                  if (selectedStatus != "COOL" && selectedStatus != "WARM") {
                    return const SizedBox.shrink();
                  }

                  return FocusTraversalOrder(
                    order: const NumericFocusOrder(10),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        focusColor: Colors.transparent,
                        onTap: () async {
                          DateTime today = DateTime.now();
                          DateTime onlyDate = DateTime(
                            today.year,
                            today.month,
                            today.day,
                          );

                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate:
                                controller.followUpDate.value ?? onlyDate,
                            firstDate: onlyDate,
                            lastDate: DateTime(2030),
                          );

                          if (picked != null) {
                            controller.followUpDate.value = picked;
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFD1D5DB)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 20,
                                color: Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  controller.followUpDate.value == null
                                      ? "Select Follow-up Date"
                                      : DateFormat('dd-MM-yyyy').format(
                                          controller.followUpDate.value!,
                                        ),
                                  style: GoogleFonts.k2d(
                                    fontSize: 14,
                                    color: controller.followUpDate.value == null
                                        ? const Color(0xFF6B7280)
                                        : const Color(0xFF111827),
                                  ),
                                ),
                              ),
                              if (controller.followUpDate.value != null)
                                GestureDetector(
                                  onTap: () =>
                                      controller.followUpDate.value = null,
                                  child: const Icon(
                                    Icons.clear,
                                    color: Color(0xFF9CA3AF),
                                    size: 18,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                SizedBox(height: screenHeight * 0.014),
                Obx(() {
                  final selectedStatus = controller.selectedStatus.value;

                  //  Show only if Cool or Warm
                  if (selectedStatus != "COOL" && selectedStatus != "WARM") {
                    return const SizedBox.shrink();
                  }

                  return FocusTraversalOrder(
                    order: const NumericFocusOrder(10),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        focusColor: Colors.transparent,
                        onTap: () async {
                          var pickedTime = await showTimePicker(
                            context: context,
                            initialTime:
                                controller.selectedTime.value ??
                                TimeOfDay.now(),
                          );

                          if (pickedTime != null) {
                            controller.selectedTime.value = pickedTime;
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFD1D5DB)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 20,
                                color: Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  controller.selectedTime.value == null
                                      ? "Select Follow-up Time"
                                      : controller.selectedTime.value!.format(
                                          context,
                                        ),
                                  style: GoogleFonts.k2d(
                                    fontSize: 14,
                                    color: controller.selectedTime.value == null
                                        ? const Color(0xFF6B7280)
                                        : const Color(0xFF111827),
                                  ),
                                ),
                              ),
                              if (controller.selectedTime.value != null)
                                GestureDetector(
                                  onTap: () {
                                    controller.selectedTime.value = null;
                                    controller.followUpDate.value = null;
                                  },
                                  child: const Icon(
                                    Icons.clear,
                                    color: Color(0xFF9CA3AF),
                                    size: 18,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: Obx(() {
                        final isEnabled =
                            controller.isSaveButtonEnabled() &&
                            !controller.isSaving.value;

                        return ElevatedButton.icon(
                          onPressed: isEnabled ? controller.saveLead : null,
                          icon: controller.isSaving.value
                              ? SizedBox(
                                  width: screenHeight * 0.018,
                                  height: screenHeight * 0.018,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  Icons.save_outlined,
                                  size: screenHeight * 0.02,
                                ),
                          label: Text(
                            controller.isSaving.value ? "Saving..." : "Save",
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            textStyle: GoogleFonts.k2d(
                              fontSize: screenHeight * 0.016,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(() {
                        final isEnabled =
                            controller.isOrderButtonEnabled() &&
                            !controller.isOrdering.value;

                        return ElevatedButton.icon(
                          onPressed: isEnabled ? controller.placeOrder : null,
                          icon: controller.isOrdering.value
                              ? SizedBox(
                                  width: screenHeight * 0.018,
                                  height: screenHeight * 0.018,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  Icons.shopping_cart_outlined,
                                  size: screenHeight * 0.02,
                                ),
                          label: Text(
                            controller.isOrdering.value
                                ? "Placing..."
                                : "Order Now",
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            textStyle: GoogleFonts.k2d(
                              fontSize: screenHeight * 0.016,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.017),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProductSelectionModal(BuildContext context, dynamic controller) {
    var isInitialLoading = true.obs;
    var searchQuery = ''.obs; // Reactive search query
    var filteredProductList = <String>[].obs; // Reactive filtered list

    // Initialize filtered list and prefetch images
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (controller.productIdList.isEmpty) {
        await controller.fetchProducts();
      }
      if (controller.productIdList.isNotEmpty) {
        filteredProductList.assignAll(
          controller.productIdList.where((item) => item != null).toList(),
        );
        final itemsToPrefetch = controller.productIdList
            .take(5)
            .where(
              (item) =>
                  item != null && !controller.productImageMap.containsKey(item),
            )
            .toList();
        for (var item in itemsToPrefetch) {
          await controller.fetchProductImage(item);
        }
        isInitialLoading.value = false;
      } else {
        isInitialLoading.value = false;
      }
    });

    // Update filtered list when search query changes
    ever(searchQuery, (String query) {
      print('Search query: $query'); // Debug
      if (query.isEmpty) {
        filteredProductList.assignAll(
          controller.productIdList.where((item) => item != null).toList(),
        );
      } else {
        filteredProductList.assignAll(
          controller.productIdList
              .where(
                (item) =>
                    item != null &&
                    item.toString().toLowerCase().contains(query.toLowerCase()),
              )
              .toList(),
        );
      }
      print('Filtered list length: ${filteredProductList.length}'); // Debug
    });

    // Sync controller.searchController with searchQuery
    controller.searchController?.addListener(() {
      if (controller.searchController != null) {
        searchQuery.value = controller.searchController.text;
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => FocusTraversalOrder(
          order: const NumericFocusOrder(5),
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        controller.selectedProductId?.value?.isEmpty ?? true
                            ? "Select Product"
                            : controller.selectedProductId!.value ?? "",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          controller.searchController?.clear();
                          searchQuery.value = '';
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: controller.searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: Obx(
                        () => searchQuery.value.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  controller.searchController?.clear();
                                  searchQuery.value = '';
                                },
                              )
                            : const SizedBox.shrink(),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (value) {
                      searchQuery.value = value; // Update reactively
                    },
                  ),
                ),
                const Divider(height: 1),
                // Shimmer or product list
                if (isInitialLoading.value)
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: 10,
                      itemBuilder: (context, index) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: filteredProductList.isEmpty
                        ? const Center(
                            child: Text(
                              'No products found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification.metrics.pixels >=
                                      notification.metrics.maxScrollExtent -
                                          100 &&
                                  !controller.isFetching.value &&
                                  controller.hasMore.value) {
                                controller.fetchProducts();
                              }
                              return false;
                            },
                            child: ListView.builder(
                              controller: scrollController,
                              itemCount:
                                  filteredProductList.length +
                                  (controller.hasMore.value ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == filteredProductList.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                }

                                final item = filteredProductList[index];

                                if (!controller.productImageMap.containsKey(
                                  item,
                                )) {
                                  controller.fetchProductImage(item);
                                }

                                final imageUrl = controller.getProductImage(
                                  item,
                                );
                                final hasImage = imageUrl.isNotEmpty;

                                return GestureDetector(
                                  onTap: () {
                                    controller.selectedProductId.value = item;
                                    controller.productImageUrl.value = imageUrl;
                                    searchQuery.value = '';
                                    Navigator.pop(context);
                                  },
                                  onLongPress: () {
                                    if (hasImage) {
                                      Get.dialog(
                                        Dialog(
                                          child: InteractiveViewer(
                                            child: CachedNetworkImage(
                                              imageUrl: imageUrl,
                                              fit: BoxFit.contain,
                                              placeholder: (_, __) =>
                                                  const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                              errorWidget: (_, __, ___) =>
                                                  const Icon(
                                                    Icons.broken_image,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        hasImage
                                            ? CachedNetworkImage(
                                                imageUrl: imageUrl,
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.cover,
                                                placeholder: (_, __) =>
                                                    Shimmer.fromColors(
                                                      baseColor:
                                                          Colors.grey[300]!,
                                                      highlightColor:
                                                          Colors.grey[100]!,
                                                      child: Container(
                                                        width: 40,
                                                        height: 40,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                errorWidget: (_, __, ___) =>
                                                    const Icon(
                                                      Icons.broken_image,
                                                    ),
                                              )
                                            : Shimmer.fromColors(
                                                baseColor: Colors.grey[300]!,
                                                highlightColor:
                                                    Colors.grey[100]!,
                                                child: Container(
                                                  width: 40,
                                                  height: 40,
                                                  color: Colors.white,
                                                ),
                                              ),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(item)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      controller.searchController?.clear();
      searchQuery.value = '';
      controller.showProductDropdown.value = false;
    });
  }
}

Widget buildSectionTitle(String title, context) {
  final screenHeight = MediaQuery.of(context).size.height;

  return Text(
    title,
    style: GoogleFonts.k2d(
      fontSize: screenHeight * 0.018,
      fontWeight: FontWeight.w600,
      color: Color(0xFF111827),
      letterSpacing: 0.3,
    ),
  );
}

Widget buildStockStatus(
  String productId,
  double screenHeight,
  dynamic controller,
) {
  final stock = controller.productStockMap[productId] ?? 0;

  String statusText;
  Color statusColor;
  IconData statusIcon;

  if (stock > 10) {
    statusText = '$stock in Stock';
    statusColor = const Color(0xFF10B981);
    statusIcon = Icons.check_circle_outline;
  } else if (stock > 0) {
    statusText = 'Only $stock left!';
    statusColor = const Color(0xFFF59E0B);
    statusIcon = Icons.warning_amber_outlined;
  } else {
    statusText = 'Out of Stock';
    statusColor = const Color(0xFFEF4444);
    statusIcon = Icons.error_outline;
  }

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 12),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: statusColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: statusColor.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(statusIcon, color: statusColor, size: 18),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: GoogleFonts.k2d(
            fontSize: screenHeight * 0.018,

            fontWeight: FontWeight.w500,
            color: statusColor,
          ),
        ),
      ],
    ),
  );
}

Widget buildTextField(
  context,
  String label, {
  TextEditingController? controller,
  String? Function(String?)? validator,
  IconData? icon,
  TextInputType? keyboardType,
  int maxLines = 1,
  TextInputAction? textInputAction,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textInputAction: textInputAction ?? TextInputAction.next,
      style: GoogleFonts.k2d(
        fontSize: MediaQuery.of(context).size.height * 0.017,
        color: Color(0xFF111827),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.k2d(fontSize: 14, color: Color(0xFF6B7280)),
        prefixIcon: icon != null
            ? Icon(icon, size: 20, color: const Color(0xFF6B7280))
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
      ),
    ),
  );
}

Widget buildDropdownField<T>(
  BuildContext context, {
  required String label,
  required T? value,
  required List<DropdownMenuItem<T>> items,
  required void Function(T?)? onChanged,
  String? Function(T?)? validator,
  IconData? icon,
  bool isEnabled = true,
  String? disabledHint,
  bool isExpanded = true,
}) {
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;

  final fontSize = screenHeight * 0.017;
  final labelFontSize = screenHeight * 0.018;
  final iconSize = screenHeight * 0.025;
  final verticalPadding = screenHeight * 0.015;
  final horizontalPadding = screenWidth * 0.04;

  return Padding(
    padding: EdgeInsets.only(bottom: screenHeight * 0.02),
    child: DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: isEnabled ? onChanged : null,
      validator: validator,
      style: GoogleFonts.k2d(
        fontSize: fontSize,
        color: isEnabled ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.k2d(
          fontSize: labelFontSize,
          color: isEnabled ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
        ),
        prefixIcon: icon != null
            ? Icon(
                icon,
                size: iconSize,
                color: isEnabled
                    ? const Color(0xFF6B7280)
                    : const Color(0xFF9CA3AF),
              )
            : null,
        contentPadding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isEnabled
                ? const Color(0xFFD1D5DB)
                : const Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        filled: true,
        fillColor: isEnabled
            ? const Color(0xFFF9FAFB)
            : const Color(0xFFF3F4F6),
      ),
      disabledHint: disabledHint != null
          ? Text(
              disabledHint,
              style: GoogleFonts.k2d(
                fontSize: fontSize,
                color: const Color(0xFF9CA3AF),
              ),
            )
          : null,
      dropdownColor: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      isExpanded: isExpanded,
    ),
  );
}

Widget buildDropdownWithOtherField<T>(
  BuildContext context, {
  required String label,
  required TextEditingController controller,
  required T? value,
  required List<T> items,
  required void Function(T?) onChanged,
  String? Function(T?)? validator,
  IconData? icon,
  bool isEnabled = true,
  bool isExpanded = true,
  String otherLabel = 'OTHERS',
  double order = 1, // For FocusTraversalOrder
}) {
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;

  final fontSize = screenHeight * 0.017;
  final labelFontSize = screenHeight * 0.018;
  final iconSize = screenHeight * 0.025;
  final verticalPadding = screenHeight * 0.015;
  final horizontalPadding = screenWidth * 0.04;

  // Combine items + Other option
  final List<T> finalItems = [...items, otherLabel as T];

  return FocusTraversalOrder(
    order: NumericFocusOrder(order),
    child: StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<T>(
              value: value,
              items: finalItems
                  .map(
                    (item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(item.toString()),
                    ),
                  )
                  .toList(),
              onChanged: isEnabled
                  ? (val) {
                      setState(() {
                        onChanged(val);
                        if (val?.toString() != otherLabel) {
                          controller.text = val?.toString() ?? '';
                        } else {
                          controller.clear();
                        }
                      });
                    }
                  : null,
              validator: (val) {
                if (val == null) {
                  return 'Please select ${label.toLowerCase()}';
                }
                if (val.toString() == otherLabel &&
                    (controller.text.trim().isEmpty)) {
                  return 'Please enter ${label.toLowerCase()}';
                }
                return null;
              },

              style: GoogleFonts.k2d(
                fontSize: fontSize,
                color: isEnabled
                    ? const Color(0xFF111827)
                    : const Color(0xFF9CA3AF),
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: GoogleFonts.k2d(
                  fontSize: labelFontSize,
                  color: isEnabled
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF9CA3AF),
                ),
                prefixIcon: icon != null
                    ? Icon(
                        icon,
                        size: iconSize,
                        color: isEnabled
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF9CA3AF),
                      )
                    : null,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isEnabled
                        ? const Color(0xFFD1D5DB)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF3B82F6),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFEF4444)),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFEF4444),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: isEnabled
                    ? const Color(0xFFF9FAFB)
                    : const Color(0xFFF3F4F6),
              ),
              dropdownColor: Colors.white,
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              isExpanded: isExpanded,
            ),
            const SizedBox(height: 8),
            if (value?.toString() == otherLabel)
              TextFormField(
                controller: controller,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Enter $label',
                  labelStyle: GoogleFonts.k2d(fontSize: labelFontSize),
                  prefixIcon: const Icon(Icons.edit, size: 20),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                ),
                validator: (val) {
                  if (value?.toString() == otherLabel && val!.trim().isEmpty) {
                    return 'Please enter $label';
                  }
                  return null;
                },
              ),
          ],
        );
      },
    ),
  );
}

Widget buildTextFieldForNumber(
  context,
  String label, {
  TextEditingController? controller,
  String? Function(String?)? validator,
  TextInputAction? textInputAction,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      keyboardType: TextInputType.number,
      controller: controller,
      validator: validator,
      textInputAction: textInputAction ?? TextInputAction.next,
      style: GoogleFonts.k2d(
        fontSize: MediaQuery.of(context).size.height * 0.016,
        color: Color(0xFF111827),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.k2d(fontSize: 14, color: Color(0xFF6B7280)),
        prefixIcon: const Icon(
          Icons.numbers_outlined,
          size: 20,
          color: Color(0xFF6B7280),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
      ),
    ),
  );
}
