import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _submitFeedback() async {
    String feedbackText = _feedbackController.text.trim();
    if (feedbackText.isNotEmpty) {
      await _firestore.collection('feedbacks').add({
        'feedback': feedbackText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _feedbackController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feedback submitted successfully!')),
      );
    }
  }

  void _showEditRatingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Edit Rating"),
          content: const Text("Do you want to edit your existing rating?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _showRatingInputDialog(); // Show rating input dialog
              },
              child: const Text("Edit"),
            ),
          ],
        );
      },
    );
  }

  void _showRatingInputDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Edit Your Rating"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select a new rating:"),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      Icons.star,
                      color: Colors.yellow,
                    ),
                    onPressed: () {
                      // Handle rating update logic here
                      Navigator.of(context)
                          .pop(); // Close dialog after selection
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Feedback'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditRatingDialog, // Opens edit rating dialog
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Feedback',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your feedback here...',
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _submitFeedback,
              child: Text('Submit'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('feedbacks')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  var feedbackDocs = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: feedbackDocs.length,
                    itemBuilder: (context, index) {
                      var feedbackData =
                          feedbackDocs[index].data() as Map<String, dynamic>;
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          title:
                              Text(feedbackData['feedback'] ?? 'No feedback'),
                          subtitle: Text(
                              feedbackData['timestamp']?.toDate().toString() ??
                                  ''),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
