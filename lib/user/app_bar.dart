import 'package:flutter/material.dart';
import 'package:smart_wash/user/bookings/booking_list.dart';
import 'package:smart_wash/user/screens/calendar.dart';
import 'package:smart_wash/login/login.dart';
import 'package:smart_wash/admin/partner.dart';
import 'package:smart_wash/user/screens/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';

custAppBar(BuildContext context, String title, {bool showBack = false}) {
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
        onSelected: (value) async {
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
            // Sign out from Firebase
            await FirebaseAuth.instance.signOut();
            // Redirect to Login page after sign-out
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
              (Route<dynamic> route) =>
                  false, // This removes all previous routes
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
