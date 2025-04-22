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
  bool isLoading = false;
  bool isGoogleLoading = false;
  bool isForgotPasswordLoading = false;

  Future<void> signInWithGoogle() async {
    try {
      setState(() => isGoogleLoading = true);
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => isGoogleLoading = false);
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google Sign-In Successful!")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Dash()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In failed: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => isGoogleLoading = false);
    }
  }

  Future<void> loginUser() async {
    try {
      setState(() => isLoading = true);
      if (isAdminLogin) {
        await loginAdmin();
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login Successful!")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Dash()),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "An error occurred.")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> loginAdmin() async {
    try {
      FocusScope.of(context).unfocus();
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('partners')
          .doc(userCredential.user!.uid)
          .get();

      if (adminDoc.exists) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminDashboard(adminUid: adminDoc.id),
          ),
        );
      } else {
        await FirebaseAuth.instance.signOut();
        throw Exception("Not a registered partner");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: ${e.toString()}")),
      );
    }
  }

  Future<void> navigateToForgotPassword() async {
    try {
      setState(() => isForgotPasswordLoading = true);
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ForgotPassword()),
      );
    } finally {
      if (mounted) setState(() => isForgotPasswordLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 250, 249),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 70.0),
            const Text(
              "Welcome Back!",
              style: TextStyle(
                color: Colors.deepOrange,
                fontSize: 30.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10.0),
            const Text(
              "Login to continue",
              style: TextStyle(color: Colors.deepOrange, fontSize: 18.0),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        isAdminLogin ? "Admin Login" : "User Login",
                        style: const TextStyle(color: Colors.deepOrange),
                      ),
                      value: isAdminLogin,
                      activeColor: Colors.deepOrange,
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
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: "Email",
                        hintStyle: const TextStyle(color: Colors.black45),
                        prefixIcon:
                            const Icon(Icons.email, color: Colors.deepOrange),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.deepOrange),
                            borderRadius:
                                BorderRadius.all(Radius.circular(18))),
                        focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.deepOrange, width: 2),
                            borderRadius:
                                BorderRadius.all(Radius.circular(18))),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    TextFormField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter your password' : null,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: "Password",
                        hintStyle: const TextStyle(color: Colors.black45),
                        prefixIcon:
                            const Icon(Icons.lock, color: Colors.deepOrange),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.deepOrange,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                        enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.deepOrange),
                            borderRadius:
                                BorderRadius.all(Radius.circular(18))),
                        focusedBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.deepOrange, width: 2),
                            borderRadius:
                                BorderRadius.all(Radius.circular(18))),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Align(
                      alignment: Alignment.centerRight,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: isForgotPasswordLoading
                              ? null
                              : navigateToForgotPassword,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                            child: isForgotPasswordLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.deepOrange,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Forgot Password?",
                                    style: TextStyle(
                                      color: Colors.deepOrange,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: isLoading
                            ? null
                            : () {
                                FocusScope.of(context).unfocus();
                                if (_formKey.currentState!.validate()) {
                                  loginUser();
                                }
                              },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Login",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: isGoogleLoading ? null : signInWithGoogle,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: isGoogleLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image(
                                        image: AssetImage(
                                            'assets/images/google.jpeg'),
                                        height: 35.0,
                                        width: 35.0,
                                      ),
                                      SizedBox(width: 15.0),
                                      Text(
                                        "Sign in with Google",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account?",
                          style:
                              TextStyle(fontSize: 16.0, color: Colors.black87),
                        ),
                        const SizedBox(width: 5.0),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: isLoading
                                ? null
                                : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => SignUp()),
                                    ),
                            child: Text(
                              "Sign Up",
                              style: TextStyle(
                                  color: isLoading
                                      ? Colors.grey
                                      : Colors.deepOrange,
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
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
