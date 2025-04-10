import 'package:flutter/material.dart';
import 'package:smart_wash/calendar.dart';
import 'package:smart_wash/login.dart';
import 'package:smart_wash/admin/partner_profile.dart';

custAppBarr(BuildContext context, String title, {bool showBack = true}) {
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
      PopupMenuButton<String>(
        icon: const Icon(Icons.menu), // Hamburger icon
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
