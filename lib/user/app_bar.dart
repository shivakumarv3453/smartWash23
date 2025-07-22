import 'package:flutter/material.dart';
import 'package:smart_wash/user/bookings/booking_list.dart';
import 'package:smart_wash/user/screens/calendar.dart';
import 'package:smart_wash/login/login.dart';
import 'package:smart_wash/admin/partner.dart';
import 'package:smart_wash/user/screens/dash.dart';
import 'package:smart_wash/user/screens/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_wash/user/screens/rating.dart';

custAppBar(BuildContext context, String title, {bool showBack = false, bool showMenu = false}) {
  return AppBar(
    backgroundColor: Colors.deepOrange,
    leading: showBack
        ? IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const Dash()),
                (Route<dynamic> route) => false,
              );
            },
          )
        : Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: IconButton(
              icon: const Icon(Icons.person_outline, 
                color: Colors.white,
                size: 24,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
          ),
    title: Center(
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 30,
          color: Colors.white,
        ),
      ),
    ),
    actions: showMenu ? [
      PopupMenuButton<String>(
        icon: const Icon(Icons.menu, color: Colors.white),
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        splashRadius: 1,
        tooltip: 'Menu',
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
          } else if (value == "Become a Partner") {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const PartnerPage()));
          } else if (value == "Feedback") {
            showRatingDialog(context);
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
            value: "Become a Partner",
            child: ListTile(
              leading: Icon(Icons.business),
              title: Text("Become a Partner"),
            ),
          ),
          const PopupMenuItem(
            value: "Feedback",
            child: ListTile(
              leading: Icon(Icons.rate_review),
              title: Text("Feedback"),
            ),
          ),
        ],
      ),
    ] : null,
  );
}