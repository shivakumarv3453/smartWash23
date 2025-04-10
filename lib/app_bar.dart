import 'package:flutter/material.dart';
import 'package:smart_wash/booking_list.dart';
import 'package:smart_wash/calendar.dart';
import 'package:smart_wash/login.dart';
import 'package:smart_wash/admin/partner.dart';
import 'package:smart_wash/profile.dart'; // Add this import

custAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: Colors.deepOrange,
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
        icon: const Icon(Icons.menu),
        onSelected: (value) {
          if (value == "Calendar") {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const CalendarPage()));
          } else if (value == "Your Bookings") {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const BookingListScreen()),
            );
          } else if (value == "Profile") {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const ProfilePage()));
          } else if (value == "Become a Partner") {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const PartnerPage()));
          } else if (value == "Logout") {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Login()));
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
            // NEW ITEM
            value: "Your Bookings",
            child: ListTile(
              leading: Icon(Icons.book),
              title: Text("Your Bookings"),
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
            value: "Become a Partner",
            child: ListTile(
              leading: Icon(Icons.business),
              title: Text("Become a Partner"),
            ),
          ),
          const PopupMenuItem(
              value: "Logout",
              child: ListTile(
                leading: Icon(Icons.logout),
                title: Text("Logout"),
              ))
        ],
      ),
    ],
  );
}
