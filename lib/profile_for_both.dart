// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:smart_wash/app_bar.dart';
// import 'package:smart_wash/partner_profile.dart';
// import 'package:smart_wash/tot_booking.dart';

// class ProfilePage extends StatefulWidget {
//   const ProfilePage({super.key});

//   @override
//   State<ProfilePage> createState() => _ProfilePageState();
// }

// class _ProfilePageState extends State<ProfilePage> {
//   bool isPartner = false; // Set this based on your user role logic
//   TextEditingController nameController = TextEditingController();
//   TextEditingController mobileController = TextEditingController();
//   TextEditingController locationController = TextEditingController();
//   User? user = FirebaseAuth.instance.currentUser;

//   @override
//   void initState() {
//     super.initState();
//     if (user != null) {
//       nameController.text = user!.displayName ?? "";
//       _fetchProfileData();
//     }
//   }

//   Future<void> _fetchProfileData() async {
//     DocumentSnapshot profileDoc = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(user!.uid)
//         .get();

//     if (profileDoc.exists) {
//       Map<String, dynamic> profileData =
//           profileDoc.data() as Map<String, dynamic>;
//       mobileController.text = profileData['mobile'] ?? "";
//       locationController.text = profileData['location'] ?? "";
//     }
//   }

//   Future<void> _updateProfile() async {
//     if (user != null) {
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user!.uid)
//           .update({
//         'name': nameController.text,
//         'mobile': mobileController.text,
//         'location': locationController.text,
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Profile updated successfully")),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: custAppBar(context, "Profile"),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (isPartner)
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text("Name: Partner's Name",
//                       style: TextStyle(fontSize: 18)),
//                   const Text("Washing Center: XYZ Car Wash",
//                       style: TextStyle(fontSize: 18)),
//                   const Text("Location: Some Street, Some City",
//                       style: TextStyle(fontSize: 18)),
//                   const Text("Contact: 123456789",
//                       style: TextStyle(fontSize: 18)),
//                   const Text("Total Services: 150",
//                       style: TextStyle(fontSize: 18)),
//                   const SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => const PartnerProfile()),
//                       );
//                     },
//                     child: const Text("View Partner Profile"),
//                   ),
//                 ],
//               )
//             else
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   TextField(
//                     controller: nameController,
//                     decoration: const InputDecoration(
//                       labelText: "Name",
//                       hintText: "Enter your name",
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   TextField(
//                     controller: mobileController,
//                     decoration: const InputDecoration(
//                       labelText: "Mobile",
//                       hintText: "Enter your mobile number",
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   TextField(
//                     controller: locationController,
//                     decoration: const InputDecoration(
//                       labelText: "Location",
//                       hintText: "Enter your location",
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: () {
//                       _updateProfile(); // Update profile info
//                     },
//                     child: const Text("Save Profile"),
//                   ),
//                   const SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => const TotalBookingUser()),
//                       );
//                     },
//                     child: const Text("View Booking History"),
//                   ),
//                 ],
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class PartnerProfile {
//   const PartnerProfile();
// }
