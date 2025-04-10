import 'package:flutter/material.dart';
import 'package:smart_wash/app_bar.dart';

class TotalBookingUser extends StatefulWidget {
  const TotalBookingUser({super.key});

  @override
  State<TotalBookingUser> createState() => _TotalBookingUserState();
}

class _TotalBookingUserState extends State<TotalBookingUser> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custAppBar(context, "Booking History"),
      body: const Center(child: Text("Total Booking History Page")),
    );
  }
}
