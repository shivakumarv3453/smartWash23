import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_wash/admin/view_bookings.dart';
import 'package:smart_wash/user/screens/calendar.dart';
import 'package:smart_wash/login/login.dart';
import 'package:smart_wash/admin/partner_profile.dart';

int _unreadNotifications =
    3; // You can update this dynamically from Firebase or state

void _showNotificationsDialog(BuildContext context, String adminUid) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Notifications"),
      content: const Text("You have new booking notifications."),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Close dialog first

            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewBookingsPage(adminUid: adminUid!),
                ),
              );
            });
          },
          child: const Text("View"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    ),
  );
}

PreferredSizeWidget custAppBarr(
  BuildContext context,
  String title, {
  bool showBack = true,
  String? adminUid,
}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(kToolbarHeight),
    child: StreamBuilder<QuerySnapshot>(
      stream: (adminUid != null)
          ? FirebaseFirestore.instance
              .collection('bookings')
              .where('centerUid', isEqualTo: adminUid)
              .where('notificationSent', isEqualTo: true)
              .snapshots()
          : const Stream.empty(),
      builder: (context, snapshot) {
        int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return AppBar(
          backgroundColor: Colors.deepOrange,
          automaticallyImplyLeading: showBack,
          title: Center(
            child: Text(
              title,
              style: const TextStyle(fontSize: 30, color: Colors.white),
            ),
          ),
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () async {
                    if (unreadCount == 0) {
                      // Show 'no new notifications' dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Notifications"),
                          content: const Text("No new booking notifications."),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("OK"),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    // Show new notifications dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Notifications"),
                        content:
                            const Text("You have new booking notifications."),
                        actions: [
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context); // Close dialog first

                              // Wait for the frame to finish
                              WidgetsBinding.instance
                                  .addPostFrameCallback((_) async {
                                // Mark notifications as read
                                final bookings = await FirebaseFirestore
                                    .instance
                                    .collection('bookings')
                                    .where('centerUid', isEqualTo: adminUid)
                                    .where('notificationSent', isEqualTo: true)
                                    .get();

                                for (var doc in bookings.docs) {
                                  await doc.reference
                                      .update({'notificationSent': false});
                                }

                                // Navigate to bookings page
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ViewBookingsPage(adminUid: adminUid!),
                                  ),
                                );
                              });
                            },
                            child: const Text("View"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Close"),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.red,
                      child: Text(
                        '$unreadCount',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu),
              onSelected: (value) {
                if (value == "Calendar") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CalendarPage()),
                  );
                } else if (value == "Profile") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AdminProfilePage()),
                  );
                } else if (value == "Logout") {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: "Calendar",
                  child: ListTile(
                    leading: Icon(Icons.calendar_today_outlined),
                    title: Text("Calendar"),
                  ),
                ),
                const PopupMenuItem(
                  value: "Profile",
                  child: ListTile(
                    leading: Icon(Icons.person),
                    title: Text("Profile"),
                  ),
                ),
                const PopupMenuItem(
                  value: "Logout",
                  child: ListTile(
                    leading: Icon(Icons.logout),
                    title: Text("Logout"),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}
