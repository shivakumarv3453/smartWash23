import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:smart_wash/constants/app_colors.dart';

class FeedbackInputForm extends StatefulWidget {
  final String bookingId;
  final String centerUid;

  const FeedbackInputForm({
    super.key,
    required this.bookingId,
    required this.centerUid,
  });

  @override
  State<FeedbackInputForm> createState() => _FeedbackInputFormState();
}

class _FeedbackInputFormState extends State<FeedbackInputForm> {
  double _rating = 0;
  final _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to submit feedback")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('bookingRatings')
          .doc(widget.bookingId)
          .set({
        'rating': _rating,
        'comment': _feedbackController.text,
        'submittedAt': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'centerUid': widget.centerUid,
        'bookingId': widget.bookingId,
      });

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({'hasFeedback': true});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Thanks for your feedback!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit feedback: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "How was your service?",
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        RatingBar.builder(
          initialRating: _rating,
          minRating: 1,
          allowHalfRating: true,
          itemSize: 32,
          itemPadding: const EdgeInsets.symmetric(horizontal: 4),
          itemBuilder: (context, _) => Icon(
            Icons.star_rounded,
            color:
                _rating > 0 ? AppColors.ratingActive : AppColors.ratingInactive,
          ),
          onRatingUpdate: (rating) => setState(() => _rating = rating),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _feedbackController,
          decoration: InputDecoration(
            hintText: "Tell us about your experience...",
            hintStyle:
                TextStyle(color: AppColors.textSecondary.withOpacity(0.6)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: AppColors.primaryLight.withOpacity(0.2),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: TextStyle(color: AppColors.textPrimary),
          maxLines: 4,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: _rating > 0 ? _submitFeedback : null,
            child: const Text(
              "Submit Feedback",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
