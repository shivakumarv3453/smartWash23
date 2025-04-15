import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_wash/admin/app_bar2.dart';

class ViewBookingsPage extends StatefulWidget {
  final String adminUid;
  const ViewBookingsPage({super.key, required this.adminUid});

  @override
  State<ViewBookingsPage> createState() => _ViewBookingsPageState();
}

class _ViewBookingsPageState extends State<ViewBookingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: custAppBarr(
        context,
        "Booking Requests",
        adminUid: widget.adminUid,
        hideNotificationIcon: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("bookings")
              .where("centerUid", isEqualTo: widget.adminUid)
              .orderBy("timestamp", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error loading bookings",
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 18,
                  ),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.car_repair,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No bookings available",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            var bookings = snapshot.data!.docs;
            return ListView.separated(
              itemCount: bookings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                var doc = bookings[index];
                final data = doc.data() as Map<String, dynamic>;
                final isNew = data['notificationSent'] == true;
                final timestamp = data['timestamp'] as Timestamp?;
                final dateTime = timestamp?.toDate();
                final formattedDate = dateTime != null
                    ? "${dateTime.day}/${dateTime.month}/${dateTime.year}"
                    : data['date'] ?? "N/A";

                // Determine status color
                Color statusColor = Colors.grey;
                if (data['status'].toString().startsWith("Confirmed")) {
                  statusColor = Colors.green;
                } else if (data['status'] == "Rejected") {
                  statusColor = Colors.red;
                } else if (data['status'] == "Pending") {
                  statusColor = Colors.orange;
                }

                return GestureDetector(
                  onTap: () {
                    _showStatusOptions(context, doc.id);
                  },
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: isNew ? Colors.blue[50] : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Car Type row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${data["carType"]}",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Service: ${data["washType"]} (${data["serviceType"]})",
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                  Icons.person, "${data["userName"] ?? "N/A"}"),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                  Icons.phone, "${data["userPhone"] ?? "N/A"}"),
                              const SizedBox(height: 8),
                              _buildInfoRow(Icons.location_on,
                                  "${data["userLocation"] ?? "N/A"}"),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildDateTimeInfo(
                                      Icons.calendar_today, formattedDate),
                                  _buildDateTimeInfo(
                                      Icons.access_time, "${data["time"]}"),
                                ],
                              ),
                            ],
                          ),
                          // Status and menu button in top-right
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "${data["status"]}",
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  iconSize: 20,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  color: Colors.deepOrange,
                                  onPressed: () {
                                    _showStatusOptions(context, doc.id);
                                  },
                                ),
                              ],
                            ),
                          ),
                          // Notification dot
                          if (isNew)
                            const Positioned(
                              right: 40,
                              top: 4,
                              child: CircleAvatar(
                                radius: 6,
                                backgroundColor: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.deepOrange),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  void _showStatusOptions(BuildContext context, String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Update Status",
          style: TextStyle(color: Colors.deepOrange),
        ),
        content: const Text("Select the new status for this booking"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            onPressed: () async {
              await _updateStatus(
                  context, bookingId, "Confirmed - Awaiting Payment");
              Navigator.pop(context);
            },
            child: const Text(
              "Confirm",
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              await _updateStatus(context, bookingId, "Rejected");
              Navigator.pop(context);
            },
            child: const Text("Reject", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(
      BuildContext context, String bookingId, String status) async {
    try {
      // First update the status
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'status': status});

      // Then update the notificationSent field separately
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'notificationSent': false});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Status updated to $status"),
          backgroundColor: status == "Confirmed" ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update status: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
