import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveBooking({
    required String carType,
    required String washType,
    required String serviceType,
    required String date,
    required String time,
  }) async {
    try {
      String userId =
          FirebaseAuth.instance.currentUser!.uid; // Get logged-in user ID
      await _db.collection("bookings").add({
        "userId": userId,
        "carType": carType,
        "washType": washType,
        "serviceType": serviceType,
        "date": date,
        "time": time,
        "status": "Pending"
      });

      print("Booking saved successfully!");
    } catch (e) {
      print("Error saving booking: $e");
    }
  }
}
