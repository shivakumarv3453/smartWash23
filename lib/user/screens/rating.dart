import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void showRatingDialog(BuildContext context) {
  final TextEditingController descriptionController = TextEditingController();
  int starCount = 0;
  final User? user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    print("User not logged in.");
    return;
  }

  String? existingFeedbackId; // Stores the document ID if feedback exists

  // Fetch previous feedback before opening the dialog
  Future<void> fetchFeedback(Function setState) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('feedback')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var feedbackData = snapshot.docs.first.data() as Map<String, dynamic>;
        setState(() {
          existingFeedbackId = snapshot.docs.first.id;
          starCount = feedbackData['rating'] ?? 0;
          descriptionController.text = feedbackData['comment'] ?? "";
        });
      }
    } catch (e) {
      print("Error fetching feedback: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching feedback: $e")),
      );
    }
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          // Fetch feedback when dialog opens
          if (existingFeedbackId == null) {
            fetchFeedback(setState);
          }

          return AlertDialog(
            title: const Text('Rate the App'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Star Rating
                Row(
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < starCount ? Icons.star : Icons.star_border,
                        color: Colors.green,
                        size: 30,
                      ),
                      onPressed: () {
                        setState(() {
                          starCount = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 10),
                // Description Input
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'Write a description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  String username = user.displayName ?? "Anonymous";

                  if (existingFeedbackId == null) {
                    // No previous feedback, add new
                    await FirebaseFirestore.instance
                        .collection('feedback')
                        .add({
                      'userId': user.uid,
                      'username': username,
                      'rating': starCount,
                      'comment': descriptionController.text,
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                  } else {
                    // Update existing feedback
                    await FirebaseFirestore.instance
                        .collection('feedback')
                        .doc(existingFeedbackId)
                        .update({
                      'rating': starCount,
                      'comment': descriptionController.text,
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Feedback updated successfully!")),
                  );

                  Navigator.of(context).pop();
                },
                child: existingFeedbackId == null
                    ? const Text('Submit')
                    : const Text('Update'),
              ),
            ],
          );
        },
      );
    },
  );
}
