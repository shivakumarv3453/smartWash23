import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController centerController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController existingPasswordController =
      TextEditingController();

  final User? user = FirebaseAuth.instance.currentUser;
  bool isLoading = true;
  bool isEditing = false;
  bool isPasswordVisible = false;
  String? currentPassword;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _fetchAdminData();
    }
  }

  Future<void> _fetchAdminData() async {
    if (user == null) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Admin not authenticated"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      print("Fetching admin data for: ${user!.uid}");

      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('partners')
          .doc(user!.uid)
          .get();

      if (adminDoc.exists) {
        print("Admin document found.");

        Map<String, dynamic> adminData =
            adminDoc.data() as Map<String, dynamic>;

        nameController.text = adminData['name'] ?? '';
        emailController.text = adminData['email'] ?? '';
        mobileController.text = adminData['phone'] ?? '';
        locationController.text = adminData['location'] ?? '';
        centerController.text = adminData['center'] ?? '';
        currentPassword = adminData['adminPassword'];

        setState(() {
          isLoading = false;
        });
      } else {
        print("Admin document NOT found.");
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Admin profile not found."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error fetching profile data: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (user == null) return;
    if (passwordController.text.isNotEmpty) {
      _validateAndUpdatePassword();
    } else {
      await _saveProfileData();
    }
  }

  Future<void> _validateAndUpdatePassword() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Password Change"),
          content: TextField(
            controller: existingPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: "Enter existing password",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
              ),
              onPressed: () async {
                if (existingPasswordController.text == currentPassword) {
                  Navigator.pop(context);
                  await _saveProfileData(newPassword: passwordController.text);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Incorrect existing password"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveProfileData({String? newPassword}) async {
    try {
      Map<String, dynamic> updateData = {
        'name': nameController.text,
        'phone': mobileController.text,
        'location': locationController.text,
        'center': centerController.text,
      };
      if (newPassword != null) {
        updateData['adminPassword'] = newPassword;
      }
      await FirebaseFirestore.instance
          .collection('partners')
          .doc(user!.uid)
          .update(updateData);

      setState(() {
        isEditing = false;
        if (newPassword != null) {
          passwordController.text = "";
          existingPasswordController.text = "";
          currentPassword = newPassword;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating profile: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Admin Profile"),
          backgroundColor: Colors.deepOrange,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Partner Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: Icon(
              isEditing ? Icons.save : Icons.edit,
              color: Colors.white,
            ),
            onPressed: () {
              if (isEditing) {
                _updateProfile();
              } else {
                setState(() {
                  isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade400],
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.business,
                      size: 40,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nameController.text.isNotEmpty
                              ? nameController.text
                              : "Partner Name",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          centerController.text.isNotEmpty
                              ? centerController.text
                              : "Washing Center",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Profile Details
            Text(
              "Partner Information",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const Divider(height: 20),
            const SizedBox(height: 10),

            _buildFormField(
              controller: nameController,
              label: "Name",
              icon: Icons.person,
              enabled: isEditing,
            ),
            const SizedBox(height: 15),

            _buildFormField(
              controller: emailController,
              label: "Email",
              icon: Icons.email,
              enabled: false,
            ),
            const SizedBox(height: 15),

            _buildFormField(
              controller: mobileController,
              label: "Mobile",
              icon: Icons.phone,
              enabled: isEditing,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 15),

            _buildFormField(
              controller: locationController,
              label: "Location",
              icon: Icons.location_on,
              enabled: isEditing,
            ),
            const SizedBox(height: 15),

            _buildFormField(
              controller: centerController,
              label: "Center Name",
              icon: Icons.store,
              enabled: isEditing,
            ),
            const SizedBox(height: 15),

            _buildPasswordField(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
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
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: passwordController,
      enabled: isEditing,
      obscureText: !isPasswordVisible,
      decoration: InputDecoration(
        labelText: "New Password",
        prefixIcon: Icon(Icons.lock, color: Colors.blue.shade600),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.blue.shade600,
          ),
          onPressed: () =>
              setState(() => isPasswordVisible = !isPasswordVisible),
        ),
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
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}
