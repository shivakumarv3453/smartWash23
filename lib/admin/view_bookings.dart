import 'dart:async';

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
  int _unreadCount = 0;
  late StreamSubscription<QuerySnapshot> _bookingsSubscription;

  @override
  void initState() {
    super.initState();
    _setupBookingsListener();
  }

  void _setupBookingsListener() {
    _bookingsSubscription = FirebaseFirestore.instance
        .collection('bookings')
        .where('centerUid', isEqualTo: widget.adminUid)
        .where('notificationSent', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _unreadCount = snapshot.docs.length;
      });
    });
  }

  Future<void> _markAsRead(String bookingId) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .update({'notificationSent': false});
  }

  @override
  void dispose() {
    _bookingsSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          custAppBarr(context, "Booking Requests", unreadCount: _unreadCount),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("bookings")
            .where("centerUid", isEqualTo: widget.adminUid)
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error.toString()}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No bookings available"));
          }

          var bookings = snapshot.data!.docs;
          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              var doc = bookings[index];
              final data = doc.data() as Map<String, dynamic>;
              final isNew = data['notificationSent'] == true;
              final timestamp = data['timestamp'] as Timestamp?;
              final dateTime = timestamp?.toDate();
              final formattedDate = dateTime != null
                  ? "${dateTime.day}/${dateTime.month}/${dateTime.year}"
                  : data['date'] ?? "N/A";

              return GestureDetector(
                onTap: () {
                  if (isNew) _markAsRead(doc.id);
                  _showStatusOptions(context, doc.id);
                },
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: isNew ? Colors.blue.shade50 : null,
                  child: Stack(
                    children: [
                      ListTile(
                        title: Text("${data["carType"]} - ${data["washType"]}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Service: ${data["serviceType"]}"),
                            Text("Date: $formattedDate"),
                            Text("Time: ${data["time"]}"),
                            Text("Status: ${data["status"]}"),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            if (isNew) _markAsRead(doc.id);
                            _showStatusOptions(context, doc.id);
                          },
                        ),
                      ),
                      if (isNew)
                        const Positioned(
                          right: 8,
                          top: 8,
                          child: CircleAvatar(
                            radius: 6,
                            backgroundColor: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showStatusOptions(BuildContext context, String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Status"),
        actions: [
          TextButton(
            onPressed: () => _updateStatus(context, bookingId, "Confirmed"),
            child: const Text("Confirm"),
          ),
          TextButton(
            onPressed: () => _updateStatus(context, bookingId, "Cancelled"),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(
      BuildContext context, String bookingId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection("bookings")
          .doc(bookingId)
          .update({"status": status});
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update status: $e")),
      );
    }
  }
}
