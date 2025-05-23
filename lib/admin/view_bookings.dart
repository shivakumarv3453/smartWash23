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
            bookings.sort((a, b) {
              String statusA = (a.data() as Map<String, dynamic>)['status'] ?? '';
              String statusB = (b.data() as Map<String, dynamic>)['status'] ?? '';

              if (statusA == "Payment Method Confirmed (COD)" && statusB != "Payment Method Confirmed (COD)") {
                return -1;
              } else if (statusB == "Payment Method Confirmed (Online)" && statusA != "Payment Method Confirmed (Online)") {
                return 1;
              } else {
                Timestamp tsA = (a.data() as Map<String, dynamic>)['timestamp'] ?? Timestamp(0, 0);
                Timestamp tsB = (b.data() as Map<String, dynamic>)['timestamp'] ?? Timestamp(0, 0);
                return tsB.compareTo(tsA);
              }
            });

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
                final price = (data['price'] is Map
                    ? (data['price'] as Map)['price']
                    : data['price']) ?? 0;

                // Determine status color
                Color statusColor = Colors.grey;
                if (data['status'].toString().startsWith("Confirmed")) {
                  statusColor = Colors.blue;
                } else if (data['status'] == "Rejected") {
                  statusColor = Colors.red;
                } else if (data['status'] == "Pending") {
                  statusColor = Colors.orange;
                } else if (data['status'] == "Service Done") {
                  statusColor = Colors.grey[800]!;
                } else if (data['status'] == "Payment Method Confirmed (COD)" ||
                    data['status'] == "Payment Method Confirmed (Online)") {
                  statusColor = Colors.green;
                }

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: isNew ? Colors.blue[50] : Colors.white,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showBookingDetails(context, doc),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "${data["carType"]} • ${data["serviceType"]}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "${data["status"]}",
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${data["washType"]}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${data["userName"] ?? "N/A"}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.access_time_outlined,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${data["time"]}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.currency_rupee,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "$price",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (data['status'] == "Service Done" && data['hasFeedback'] == true) ...[
                                const Spacer(),
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('bookingRatings')
                                      .where('bookingId', isEqualTo: doc.id)
                                      .snapshots(),
                                  builder: (context, ratingSnapshot) {
                                    if (ratingSnapshot.hasData && ratingSnapshot.data!.docs.isNotEmpty) {
                                      final ratingData = ratingSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                                      final rating = ratingData['rating'] ?? 0;
                                      return Row(
                                        children: [
                                          const Icon(
                                            Icons.star_outlined,
                                            size: 16,
                                            color: Colors.amber,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            rating.toString(),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                    return const SizedBox();
                                  },
                                ),
                              ],
                            ],
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

  void _showBookingDetails(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final price = (data['price'] is Map
        ? (data['price'] as Map)['price']
        : data['price']) ?? 0;
    final timestamp = data['timestamp'] as Timestamp?;
    final dateTime = timestamp?.toDate();
    final formattedDate = dateTime != null
        ? "${dateTime.day}/${dateTime.month}/${dateTime.year}"
        : data['date'] ?? "N/A";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Center(
                child: Text(
                  "Booking Details",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow("Car Type", data["carType"]),
              _buildDetailRow("Service Type", data["serviceType"]),
              _buildDetailRow("Wash Type", data["washType"]),
              _buildDetailRow("Price", "price"),
              _buildDetailRow("Date", formattedDate),
              _buildDetailRow("Time", data["time"]),
              _buildDetailRow("Customer Name", data["userName"] ?? "N/A"),
              _buildDetailRow("Phone", data["userPhone"] ?? "N/A"),
              _buildDetailRow("Location", data["userLocation"] ?? "N/A"),
              if (data['status'] == "Service Done" && data['hasFeedback'] == true) ...[
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookingRatings')
                      .where('bookingId', isEqualTo: doc.id)
                      .snapshots(),
                  builder: (context, ratingSnapshot) {
                    if (ratingSnapshot.hasData && ratingSnapshot.data!.docs.isNotEmpty) {
                      final ratingData = ratingSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                      final rating = ratingData['rating'] ?? 0;
                      final comment = ratingData['comment'] ?? "No comment provided";
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Customer Feedback:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              for (int i = 0; i < 5; i++)
                                Icon(
                                  i < rating ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 24,
                                ),
                              const SizedBox(width: 8),
                              Text(
                                "$rating/5",
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            comment,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ],
              const SizedBox(height: 24),
              if (data['status'] != "Service Done" &&
                  data['status'] != "Cancelled" &&
                  data['status'] != "Rejected")
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _showStatusOptions(context, doc.id, data['status'], "");
                    },
                    child: const Text(
                      "Update Status",
                      style: TextStyle(
                        fontSize: 16,color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
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

  void _showUserRatingDialog(BuildContext context, String bookingId) {
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('bookingRatings')
            .get(), // Get ALL ratings
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              content: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return AlertDialog(
              title: const Text("Error"),
              content: Text("Error fetching rating data: ${snapshot.error}"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return AlertDialog(
              title: const Text("No Ratings Found"),
              content: const Text("No ratings available in the database."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            );
          }

          // Filter ratings by either bookingId field OR document ID
          var allRatings = snapshot.data!.docs;

          var bookingRatings = allRatings.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            // Match either bookingId field OR document ID
            return data['bookingId'] == bookingId || doc.id == bookingId;
          }).toList();

          if (bookingRatings.isEmpty) {
            return AlertDialog(
              title: const Text("No Ratings Found"),
              content: Text("No user feedback available for this booking."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            );
          }

          // Now display the found ratings
          return AlertDialog(
            title: const Text(
              "User Ratings",
              style: TextStyle(color: Colors.deepOrange),
            ),
            content: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: bookingRatings.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  var data =
                      bookingRatings[index].data() as Map<String, dynamic>;
                  var rating = data['rating'] ?? 0;
                  var userFeedback = data['comment'] ?? "No comment provided.";
                  var timestamp = data['submittedAt'] as Timestamp?;
                  var dateTime = timestamp?.toDate();
                  var formattedDate = dateTime != null
                      ? "${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}"
                      : "Date not available";

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 0; i < 5; i++)
                              Icon(
                                i < rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 18,
                              ),
                            Text(
                              " ($rating/5)",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "\"$userFeedback\"",
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showStatusOptions(
    BuildContext context,
    String bookingId,
    String status,
    String centerUid, // This parameter isn't used currently
  ) {
    // Prevent modifying bookings with Service Done or Cancelled status
    if (status.trim().toLowerCase() == "service done" ||
        status.trim().toLowerCase() == "cancelled") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Status '$status' cannot be modified."),
          backgroundColor: Colors.grey[700],
        ),
      );
      return; // Don't show status options dialog if status is Service Done or Cancelled
    }

    // COD status options (Payment Method Confirmed (COD))
    if (status.trim().toLowerCase() ==
            "payment method confirmed (cod)".toLowerCase() ||
        status.trim().toLowerCase() ==
            "payment method confirmed (online)".toLowerCase()) {
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
                backgroundColor: Colors.grey[800],
              ),
              onPressed: () async {
                await _updateStatus(context, bookingId, "Service Done");
                Navigator.pop(context);
                // Show user ratings dialog - if available
                _showUserRatingDialog(context, bookingId);
              },
              child: const Text("Service Done",
                  style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await _updateStatus(context, bookingId, "Cancelled");
                Navigator.pop(context);
              },
              child:
                  const Text("Cancel", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      // Other statuses options
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
            // Only show Confirm button if status is NOT already "Confirmed - Awaiting Payment"
            if (status.trim().toLowerCase() !=
                "confirmed - awaiting payment".toLowerCase())
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () async {
                  await _updateStatus(
                    context,
                    bookingId,
                    "Confirmed - Awaiting Payment",
                  );
                  Navigator.pop(context);
                },
                child: const Text("Confirm",
                    style: TextStyle(color: Colors.white)),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await _updateStatus(context, bookingId, "Rejected");
                Navigator.pop(context);
              },
              child:
                  const Text("Reject", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _updateStatus(
      BuildContext context, String bookingId, String status) async {
    try {
      // Update the status
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'status': status});

      // Optional: Update the status color to reflect changes (if necessary)
      Color statusColor;
      if (status == "Service Done") {
        statusColor = Colors.grey[800]!; // Dark gray color
      } else if (status == "Confirmed - Awaiting Payment") {
        statusColor = Colors.green;
      } else if (status == "Cancelled") {
        statusColor = Colors.red;
      } else {
        statusColor = Colors.orange;
      }

      // Update the notificationSent field if necessary
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'notificationSent': false});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Status updated to $status"),
          backgroundColor: statusColor,
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
