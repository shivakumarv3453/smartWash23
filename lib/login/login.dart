import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smart_wash/admin/admin_dashboard.dart';
import 'package:smart_wash/login/signup.dart';
import 'package:smart_wash/login/forget_password.dart';
import 'package:smart_wash/user/screens/dash.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

String hashPassword(String password) {
  return sha256.convert(utf8.encode(password)).toString();
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isPasswordVisible = false;
  bool isAdminLogin = false;

  // ✅ Google Sign-In logic
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      print("✅ Google sign-in successful");
      // Optionally save to Firestore (if you need to track users)
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'name': userCredential.user!.displayName ?? '',
          'email': userCredential.user!.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Google Sign-In Successful!"),
      ));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Dash()),
      );
    } catch (e) {
      print("❌ Google sign-in failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In failed: $e")),
      );
    }
  }

  Future<void> loginUser() async {
    try {
      if (isAdminLogin) {
        await loginAdmin();
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Login Successful!"),
        ));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Dash()),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message ?? "An error occurred."),
      ));
    }
  }
  // Future<void> loginUser() async {
  //   try {
  //     FocusScope.of(context).unfocus();

  //     // Show loading dialog
  //     showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (context) => const Center(child: CircularProgressIndicator()),
  //     );

  //     // Authenticate with Firebase
  //     UserCredential userCredential =
  //         await FirebaseAuth.instance.signInWithEmailAndPassword(
  //       email: emailController.text.trim(),
  //       password: passwordController.text.trim(),
  //     );

  //     // Check user role
  //     final isAdmin = await _checkIfAdmin(userCredential.user!.uid);
  //     final isRegularUser = await _checkIfRegularUser(userCredential.user!.uid);

  //     // Close loading dialog
  //     Navigator.of(context).pop();

  //     if (isAdminLogin && isAdmin) {
  //       // Admin login successful
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) =>
  //               AdminDashboard(adminUid: userCredential.user!.uid),
  //         ),
  //       );
  //     } else if (!isAdminLogin && isRegularUser) {
  //       // Regular user login successful
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(builder: (context) => const Dash()),
  //       );
  //     } else {
  //       // Role mismatch
  //       await FirebaseAuth.instance.signOut();
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //             content: Text(isAdminLogin
  //                 ? 'This account is not registered as admin'
  //                 : 'Please use admin login for this account')),
  //       );
  //     }
  //   } on FirebaseAuthException catch (e) {
  //     Navigator.of(context).pop(); // Close loading dialog
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text(e.message ?? "Authentication failed")),
  //     );
  //   } catch (e) {
  //     Navigator.of(context).pop(); // Close loading dialog
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Error: ${e.toString()}")),
  //     );
  //   }
  // }

  // Future<bool> _checkIfAdmin(String uid) async {
  //   final doc =
  //       await FirebaseFirestore.instance.collection('partners').doc(uid).get();
  //   return doc.exists;
  // }

  // Future<bool> _checkIfRegularUser(String uid) async {
  //   final doc =
  //       await FirebaseFirestore.instance.collection('users').doc(uid).get();
  //   return doc.exists;
  // }

  Future<void> loginAdmin() async {
    try {
      FocusScope.of(context).unfocus();

      // First authenticate with Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Then verify they're actually a partner
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('partners')
          .doc(userCredential.user!.uid)
          .get();

      if (adminDoc.exists) {
        // Successful partner login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminDashboard(adminUid: adminDoc.id),
          ),
        );
      } else {
        // Not actually a partner - sign them out
        await FirebaseAuth.instance.signOut();
        throw Exception("Not a registered partner");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Login failed: ${e.toString()}"),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 70.0),
            const Text("Welcome Back!",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 30.0,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10.0),
            const Text("Login to continue",
                style: TextStyle(color: Colors.white70, fontSize: 18.0)),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(isAdminLogin ? "Admin Login" : "User Login",
                          style: TextStyle(color: Colors.white)),
                      value: isAdminLogin,
                      onChanged: (bool value) {
                        setState(() {
                          isAdminLogin = value;
                        });
                      },
                    ),
                    TextFormField(
                      controller: emailController,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter your email' : null,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Email",
                        hintStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.email, color: Colors.white70),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    TextFormField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter your password' : null,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Password",
                        hintStyle: const TextStyle(color: Colors.white70),
                        prefixIcon:
                            const Icon(Icons.lock, color: Colors.white70),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ForgotPassword())),
                        child: const Text("Forgot Password?",
                            style: TextStyle(
                                color: Colors.redAccent, fontSize: 16.0)),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus(); // Hide keyboard
                        if (_formKey.currentState!.validate()) {
                          loginUser();
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text("Login",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    /// ✅ Google Sign-In Button
                    GestureDetector(
                      onTap: signInWithGoogle,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image(
                                image: AssetImage(
                                    'assets/images/google.jpeg'), // Make sure to add the image in your assets
                                height: 35.0,
                                width: 35.0,
                              ),
                              SizedBox(
                                  width: 15.0), // Space between logo and text
                              Text(
                                "Sign in with Google",
                                style: TextStyle(
                                  color: Color.fromARGB(255, 0, 0, 0),
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?",
                            style:
                                TextStyle(fontSize: 16.0, color: Colors.white)),
                        const SizedBox(width: 5.0),
                        GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SignUp())),
                          child: const Text("Sign Up",
                              style: TextStyle(
                                  color: Colors.amber, fontSize: 18.0)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
