import 'package:flutter/material.dart';
import 'package:smart_wash/user/screens/calendar.dart';
import 'package:smart_wash/login/login.dart';
import 'package:smart_wash/admin/partner_profile.dart';

int _unreadNotifications =
    3; // You can update this dynamically from Firebase or state

void _showNotificationsDialog(BuildContext context, int count) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Notifications"),
      content: Text("You have $count unread notifications."),
      actions: [
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
  int unreadCount = 0, // <-- Add this
}) {
  return AppBar(
    backgroundColor: Colors.deepOrange,
    automaticallyImplyLeading: showBack,
    title: Center(
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 30,
          color: Colors.white,
        ),
      ),
    ),
    actions: [
      Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _showNotificationsDialog(context, unreadCount),
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
                  style: const TextStyle(fontSize: 12, color: Colors.white),
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
              MaterialPageRoute(builder: (context) => const CalendarPage()),
            );
          } else if (value == "Profile") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminProfilePage()),
            );
          } else if (value == "Logout") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
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
}
