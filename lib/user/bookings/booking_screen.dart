import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BookingScreen extends StatelessWidget {
  final String centerUid;
  final String selectedCarType;
  final String selectedCenter;
  final String selectedWashType;
  final String selectedServiceType;
  final String selectedDate;
  final String selectedTime;

  const BookingScreen({
    super.key,
    required this.centerUid,
    required this.selectedCenter,
    required this.selectedCarType,
    required this.selectedWashType,
    required this.selectedServiceType,
    required this.selectedDate,
    required this.selectedTime,
  });

  Future<void> _saveBooking(BuildContext context) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final bookingData = {
        'centerUid': centerUid,
        'center': selectedCenter,
        'carType': selectedCarType,
        'washType': selectedWashType,
        'serviceType': selectedServiceType,
        'date': selectedDate,
        'time': selectedTime,
        'status': 'Pending',
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      };

      print("📝 Attempting to save booking data: $bookingData");

      final docRef = await FirebaseFirestore.instance
          .collection('bookings')
          .add(bookingData);
      print("✅ Booking stored in Firebase with ID: ${docRef.id}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Booking Submitted Successfully!")),
      );

      // Navigate back after booking confirmation
      Future.delayed(Duration(seconds: 1), () {
        Navigator.pop(context);
      });
    } catch (e) {
      print("❌ Error saving booking: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting booking. Try again!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Center UID in BookingScreen: $centerUid");

    return Scaffold(
      appBar: AppBar(title: Text("Confirm Booking")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "You are booking for: \nCar: $selectedCarType\nWash Type: $selectedWashType\nService: $selectedServiceType\nDate: $selectedDate\nTime: $selectedTime",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _saveBooking(context),
              child: const Text("Confirm & Book"),
            ),
          ],
        ),
      ),
    );
  }
}
