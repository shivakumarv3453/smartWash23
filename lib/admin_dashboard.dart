import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_wash/app_bar2.dart';
import 'package:smart_wash/manage_time_slot.dart';
// import 'package:smart_wash/manage_wash_types.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'login.dart';

class AdminDashboard extends StatefulWidget {
  final String adminUid;

  const AdminDashboard({super.key, required this.adminUid});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

Future<List<String>> fetchServiceTypes(dynamic widget) async {
  try {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('partners')
        .doc(widget.adminUid)
        .get();

    if (!snapshot.exists ||
        !snapshot.data().toString().contains('service_types')) {
      return [];
    }

    List<String> serviceTypes =
        List<String>.from(snapshot['service_types'] ?? []);
    return serviceTypes;
  } catch (error) {
    print("Error fetching service types: $error");
    return [];
  }
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool onSiteEnabled = true;
  bool atCenterEnabled = true;

  void showManagementDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('partners')
              .doc(widget.adminUid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AlertDialog(
                title: Text("Manage $title"),
                content: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return AlertDialog(
                title: Text("Error"),
                content: Text("Failed to load $title data."),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return AlertDialog(
                title: Text("Manage $title"),
                content: Text("No data available."),
              );
            }

            var data = snapshot.data!.data() as Map<String, dynamic>;

            // Update the outer state variables directly from Firestore
            onSiteEnabled = data["onSiteEnabled"] ?? false;
            atCenterEnabled = data["atCenterEnabled"] ?? false;

            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: Text("Manage $title"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SwitchListTile(
                        title: Text("Enable On-Site Washing"),
                        value: onSiteEnabled,
                        onChanged: (value) async {
                          await FirebaseFirestore.instance
                              .collection('partners')
                              .doc(widget.adminUid)
                              .update({'onSiteEnabled': value});
                          setDialogState(() => onSiteEnabled = value);
                          setState(() =>
                              onSiteEnabled = value); // update outer state too
                        },
                      ),
                      SwitchListTile(
                        title: Text("Enable At-Center Washing"),
                        value: atCenterEnabled,
                        onChanged: (value) async {
                          await FirebaseFirestore.instance
                              .collection('partners')
                              .doc(widget.adminUid)
                              .update({'atCenterEnabled': value});
                          setDialogState(() => atCenterEnabled = value);
                          setState(() => atCenterEnabled =
                              value); // update outer state too
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: Text("Close"),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void openManageWashTypesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('partners')
              .doc(widget.adminUid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                title: Text("Manage Wash Types"),
                content: Center(child: CircularProgressIndicator()),
              );
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const AlertDialog(
                title: Text("Manage Wash Types"),
                content: Text("No wash type data found."),
              );
            }

            Map<String, dynamic> data =
                snapshot.data!.data() as Map<String, dynamic>;
            Map<String, dynamic> washTypes =
                Map<String, dynamic>.from(data['washTypes'] ??
                    {
                      "Standard": true,
                      "Premium": true,
                      "Ultra-Premium": true,
                    });

            return StatefulBuilder(builder: (context, setDialogState) {
              return AlertDialog(
                title: Text("Manage Wash Types"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: washTypes.entries.map((entry) {
                    return SwitchListTile(
                      title: Text(entry.key),
                      value: entry.value,
                      onChanged: (newValue) {
                        washTypes[entry.key] = newValue;
                        FirebaseFirestore.instance
                            .collection('partners')
                            .doc(widget.adminUid)
                            .update({'washTypes': washTypes});
                        setDialogState(() {});
                      },
                    );
                  }).toList(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("Close"),
                  )
                ],
              );
            });
          },
        );
      },
    );
  }

  final bool _isAdmin = true;

  @override
  void initState() {
    super.initState();
    fetchAdminSettings();
    if (_isAdmin) {
      requestNotificationPermission(widget.adminUid);
    }
  }

  Future<void> requestNotificationPermission(String adminUid) async {
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Push notifications allowed');

      // Get the FCM token
      String? token = await FirebaseMessaging.instance.getToken();
      print("📲 FCM Token: $token");

      // Save the token to Firestore
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('partners')
            .doc(adminUid)
            .update({'fcmToken': token});
        print('✅ FCM token saved to Firestore');
      }
    } else {
      print('❌ Push notifications permission denied');
    }
  }

  void fetchAdminSettings() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('partners')
        .doc(widget.adminUid)
        .get();

    if (doc.exists) {
      setState(() {
        onSiteEnabled = doc['onSiteEnabled'] ?? true;
        atCenterEnabled = doc['atCenterEnabled'] ?? true;
      });
    }
  }

  void updateServiceStatus() async {
    await FirebaseFirestore.instance
        .collection('partners')
        .doc(widget.adminUid)
        .update({
      'onSiteEnabled': onSiteEnabled,
      'atCenterEnabled': atCenterEnabled,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.adminUid.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "Access denied. Invalid admin UID.",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Login()),
        );
        return false;
      },
      child: Scaffold(
        appBar: custAppBarr(context, "Admin Dashboard", showBack: false),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    DashboardItem(
                      title: "Manage Wash Types",
                      icon: Icons.car_crash,
                      onTap: () {
                        openManageWashTypesDialog(context);
                      },
                    ),
                    DashboardItem(
                      title: "Manage Service Types",
                      icon: Icons.build,
                      onTap: () =>
                          showManagementDialog(context, "Service Types"),
                    ),
                    DashboardItem(
                      title: "Manage Time Slots",
                      icon: Icons.access_time,
                      onTap: () => showDialog(
                        context: context,
                        builder: (context) =>
                            ManageTimeSlotsPopup(adminUid: widget.adminUid),
                      ),
                    ),
                    DashboardItem(
                      title: "View Bookings",
                      icon: Icons.list,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewBookingsPage(
                                adminUid: widget.adminUid), // Pass adminUid
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const DashboardItem({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(2, 2),
            ),
          ],
        ),
        margin: EdgeInsets.all(8),
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.deepPurple),
            SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ViewBookingsPage extends StatelessWidget {
  final String adminUid;
  const ViewBookingsPage({super.key, required this.adminUid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custAppBarr(context, "Booking Requests"),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("bookings")
            .where("centerUid", isEqualTo: adminUid)
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

          // Sort documents by timestamp if needed (client-side fallback)
          var bookings = snapshot.data!.docs;
          bookings.sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['timestamp'];
            final bTime = (b.data() as Map<String, dynamic>)['timestamp'];
            return bTime?.compareTo(aTime ?? Timestamp.now()) ?? 0;
          });

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              var doc = bookings[index];
              final data = doc.data() as Map<String, dynamic>;

              // Convert timestamp to readable format if needed
              final timestamp = data['timestamp'] as Timestamp?;
              final dateTime = timestamp?.toDate();
              final formattedDate = dateTime != null
                  ? "${dateTime.day}/${dateTime.month}/${dateTime.year}"
                  : data['date'] ?? "N/A";

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
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
                    onPressed: () => _showStatusOptions(context, doc.id),
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
