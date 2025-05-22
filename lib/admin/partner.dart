import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:smart_wash/user/app_bar.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../user/screens/dash.dart';

String hashPassword(String password) {
  return sha256.convert(utf8.encode(password)).toString();
}

class PartnerPage extends StatefulWidget {
  const PartnerPage({super.key});

  @override
  State<PartnerPage> createState() => _PartnerPageState();
}

class _PartnerPageState extends State<PartnerPage> {
  final TextEditingController _adminPasswordController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _centerNameController = TextEditingController();
  bool _isLoading = false;


  final User? user = FirebaseAuth.instance.currentUser;
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  void fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot profileDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (profileDoc.exists && mounted) {
        Map<String, dynamic> data = profileDoc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['username'] ?? "";
          _emailController.text = user.email ?? "";
          _phoneController.text = data['mobile'] ?? "";
        });
      }
    }
  }

  void _handleSubmit() async {
    setState(() {
      _isLoading = true;
    });
    if (_selectedLocation == null ||
        _adminPasswordController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _centerNameController.text.isEmpty ||
        _phoneController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All fields are required, and the phone number must be 10 digits."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check for duplicate center+location
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('partners')
        .where('center', isEqualTo: _centerNameController.text.trim())
        .where('location', isEqualTo: _selectedLocation)
        .get();

    if (snapshot.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("A partner already exists with this center name and location."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Save partner data under a new unique document ID
      String newUid = FirebaseFirestore.instance.collection('partners').doc().id;
      await _savePartnerData(newUid);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _savePartnerData(String uid) async {
    String hashedPassword = hashPassword(_adminPasswordController.text);

    await FirebaseFirestore.instance.collection('partners').doc(uid).set({
      'name': _nameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'location': _selectedLocation,
      'center': _centerNameController.text,
      'adminPassword': hashedPassword,
      'uid': uid,
      'onSiteEnabled': false,
      'atCenterEnabled': false,
      'washTypes': {
        'Standard': true,
        'Premium': true,
        'Ultra-Premium': true,
      },
      'disabled_dates': [],
      'disabled_time_slots': {
        '11:00 AM': false,
        '2:00 PM': false,
        '4:00 PM': false,
        '6:00 PM': false,
        '8:00 PM': false,
      },
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Thank you, ${_nameController.text}! Your application has been submitted."),
        backgroundColor: Colors.green,
      ),
    );

    await Future.delayed(Duration(seconds: 1));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Dash()),
    );

  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        appBar: custAppBar(context, "Become a Partner"),
        body: _isLoading
          ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vibrant welcome card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.handshake,
                          size: 40, color: Colors.white),
                      const SizedBox(height: 15),
                      const Text(
                        "Become a Partner",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "An exclusive feature offering from Smart Wash. "
                        "If you have your own washing center, fill the details below "
                        "to partner with us!",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // Form fields with improved styling
                Text(
                  "Partner Information",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 15),

                _buildFormField(_nameController, "Your Name", Icons.person),
                const SizedBox(height: 15),

                _buildFormField(_emailController, "Email", Icons.email),
                const SizedBox(height: 15),

                _buildFormField(
                  _phoneController,
                  "Phone",
                  Icons.phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(10),
                    FilteringTextInputFormatter.digitsOnly
                  ],
                ),
                const SizedBox(height: 15),

                _buildDropdownField(),
                const SizedBox(height: 15),

                _buildFormField(_centerNameController, "Washing Center Name",
                    Icons.car_repair),
                const SizedBox(height: 15),

                _buildFormField(
                  _adminPasswordController,
                  "Admin Password",
                  Icons.lock,
                  obscureText: true,
                ),
                const SizedBox(height: 30),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      _handleSubmit();
                    },
                    child: const Text(
                      "SUBMIT APPLICATION",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: "Select Location",
        prefixIcon: Icon(Icons.location_on, color: Colors.blue.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: ["Banashankari", "JP Nagar", "Jayanagar"].map((location) {
        return DropdownMenuItem(
          value: location,
          child: Text(location),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedLocation = value),
      borderRadius: BorderRadius.circular(12),
      icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade600),
    );
  }
}
