import 'package:smart_wash/user/screens/dash.dart';
import 'package:smart_wash/services/databse.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get the current user
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  // Sign in with email and password
  Future<void> signIn(
      BuildContext context, String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? userDetails = result.user;

      if (userDetails != null) {
        Map<String, dynamic> userInfoMap = {
          "email": userDetails.email,
          "name": userDetails.displayName,
          "imgUrl": userDetails.photoURL,
          "id": userDetails.uid
        };

        await DatabaseMethods()
            .addUser(userDetails.uid, userInfoMap)
            .then((value) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Dash()),
          );
        });
      }
    } catch (e) {
      print('Error during sign-in: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed to sign in: $e"),
      ));
    }
  }

  // Sign in with Google
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return; // User canceled the sign-in

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result =
          await _auth.signInWithCredential(credential);
      final User? userDetails = result.user;

      if (userDetails != null) {
        Map<String, dynamic> userInfoMap = {
          "email": userDetails.email,
          "name": userDetails.displayName,
          "imgUrl": userDetails.photoURL,
          "id": userDetails.uid
        };

        await DatabaseMethods()
            .addUser(userDetails.uid, userInfoMap)
            .then((value) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Dash()),
          );
        });
      }
    } catch (e) {
      print('Error during Google sign-in: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed to sign in with Google: $e"),
      ));
    }
  }
}
