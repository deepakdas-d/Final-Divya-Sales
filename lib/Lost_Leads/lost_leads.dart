import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sales/Lost_Leads/Individual_Lead_Lost.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:sales/Home/home.dart';
import 'lost_leads_controller.dart';

class LostLeads extends StatelessWidget {
  const LostLeads({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LostLeadsController());

    return WillPopScope(
      onWillPop: () async {
        Get.off(() => Home());
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Get.off(() => Home()),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          title: Text(
            'Lost Leads',
            style: GoogleFonts.oswald(
              fontWeight: FontWeight.w600,
              fontSize: MediaQuery.of(context).size.height * 0.025,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF014185),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: RefreshIndicator(
          onRefresh: () => controller.fetchLeads(),
          backgroundColor: Colors.blue,
          color: Colors.white,
          child: Column(
            children: [
              // 🔍 Search bar
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Obx(() {
                  return TextField(
                    onChanged: (value) {
                      controller.searchQuery.value = value;
                      controller.fetchLeads();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by name, phone, address, ID...',
                      hintStyle: GoogleFonts.k2d(
                        fontSize: MediaQuery.of(context).size.height * 0.015,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: controller.searchQuery.value.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                controller.searchQuery.value = '';
                                controller.fetchLeads();
                              },
                            )
                          : const SizedBox.shrink(),
                    ),
                  );
                }),
              ),
              const Divider(height: 1),
              // 📋 Leads List
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return ListView.builder(
                      itemCount: 10, // Show 10 shimmer placeholders
                      itemBuilder: (context, index) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: double.infinity,
                                            height: 16,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            width: 100,
                                            height: 12,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  height: 12,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  if (controller.leads.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.05,
                          ),
                          Text(
                            'No lost leads found',
                            style: GoogleFonts.k2d(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.05,
                          ),
                          Text(
                            'Try adjusting your search',
                            style: GoogleFonts.k2d(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (scrollInfo.metrics.pixels ==
                              scrollInfo.metrics.maxScrollExtent &&
                          controller.hasMoreLeads.value &&
                          !controller.isFetchingMoreLeads.value) {
                        controller.fetchLeads(loadMore: true);
                      }
                      return false;
                    },
                    child: ListView.builder(
                      itemCount:
                          controller.leads.length +
                          (controller.isFetchingMoreLeads.value ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == controller.leads.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        final doc = controller.leads[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildListTile(context, data);
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: InkWell(
        onTap: () => Get.to(() => LeadDetailPage(leadData: data)),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with Icon and Type Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Container
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.archive,
                      color: Colors.red[600],
                      size: MediaQuery.of(context).size.height * 0.022,
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                  // Main Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Type Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                data['name'] ?? 'No Name',
                                style: GoogleFonts.k2d(
                                  fontWeight: FontWeight.w600,
                                  fontSize:
                                      MediaQuery.of(context).size.height *
                                      0.018,
                                  color: Colors.black87,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            // Type Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Lost Lead',
                                style: GoogleFonts.k2d(
                                  color: Colors.red[700],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.01,
                        ),
                        // Date and ID Row
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              data['followUpDate'] != null
                                  ? DateFormat('dd/MM/yyyy').format(
                                      (data['followUpDate'] as Timestamp)
                                          .toDate(),
                                    )
                                  : 'N/A',
                              style: GoogleFonts.k2d(
                                fontSize:
                                    MediaQuery.of(context).size.height * 0.014,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Bottom Row with Additional Info
              Row(
                children: [
                  // Status Badge
                  const Spacer(),
                  // Place
                  if (data['place'] != null &&
                      data['place'].toString().isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            data['place'].toString(),
                            style: GoogleFonts.k2d(
                              fontSize:
                                  MediaQuery.of(context).size.height * 0.012,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Arrow Icon
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
