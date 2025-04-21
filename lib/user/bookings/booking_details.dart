import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_wash/user/app_bar.dart';
// import 'package:smart_wash/user/screens/payment.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class BookingDetailsScreen extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const BookingDetailsScreen({
    super.key,
    required this.bookingId,
    required this.bookingData,
  });

  void _showCancelConfirmation(BuildContext context) {
    // Check if the booking status is confirmed before showing the cancellation fee
    // final isConfirmed = bookingData['status'] == 'Confirmed';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Cancel Booking?",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              // if (isConfirmed)
              //   const Text(
              //     "10% cancellation fee will apply",
              //     textAlign: TextAlign.center,
              //     style: TextStyle(fontSize: 16),
              //   ),
              const SizedBox(height: 8),
              Text(
                "${bookingData['center']} • ${bookingData['date']}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Go Back"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _cancelBooking(context);
              },
              child: const Text("Confirm Cancellation"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelBooking(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Authentication required')),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing cancellation...'),
          ],
        ),
      ),
    );

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': 'Cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'lastUpdatedBy': currentUser.uid,
      });
      navigator.pop(); // Close the loading dialog
      navigator.pop(); // Go back to previous screen
      messenger.showSnackBar(
        const SnackBar(content: Text('Booking cancelled successfully')),
      );
    } catch (e, stackTrace) {
      navigator.pop(); // Close the loading dialog
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to cancel booking'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Error: $e\n$stackTrace');
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCODPayment(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Authentication required')),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Updating payment method...'),
          ],
        ),
      ),
    );

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': 'Payment Method Confirmed (COD)',
        'paymentMethod': 'COD',
        'lastUpdatedBy': currentUser.uid,
      });

      navigator.pop(); // close loading
      messenger.showSnackBar(
        const SnackBar(content: Text('Payment method confirmed as COD')),
      );
    } catch (e, stackTrace) {
      navigator.pop(); // close loading
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to confirm payment method'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Error: $e\n$stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawStatus = bookingData['status'] ?? 'Pending';
    // final hasFeedback = bookingData['feedback'] != null;
    final centerUid =
        bookingData['centerUid']; // if bookingData is a Map from Firestore

    // Customize status label for user
    final status = rawStatus == 'Confirmed - Awaiting Payment'
        ? 'Confirmed - Proceed with Payment'
        : rawStatus;
    return Scaffold(
      appBar: custAppBar(context, 'Booking Details'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with status
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getStatusBackgroundColor(status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          color: _getStatusColor(status),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(status),
                                  fontSize: 14,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                bookingData['center'] ?? 'Unknown Center',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Booking details section
                  const Text(
                    "BOOKING DETAILS",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Divider(height: 16),
                  _buildDetailRow("Car Type", bookingData['carType'] ?? 'N/A'),
                  _buildDetailRow(
                      "Wash Type", bookingData['washType'] ?? 'N/A'),
                  _buildDetailRow(
                      "Service", bookingData['serviceType'] ?? 'N/A'),
                  _buildDetailRow("Date", bookingData['date'] ?? 'N/A'),
                  _buildDetailRow("Time", bookingData['time'] ?? 'N/A'),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          // Cancel button (conditionally shown)
          if (status != 'Cancelled' &&
              status != 'Completed' &&
              status != 'Rejected')
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.close, size: 20),
                  label: const Text(
                    "Cancel Booking",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.red.shade100),
                    ),
                  ),
                  onPressed: () => _showCancelConfirmation(context),
                ),
              ),
            ),
          if (status == 'Service Done')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.purple.shade100),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Use StreamBuilder to listen for changes to the feedback
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('bookingRatings')
                          .doc(bookingId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return const Text('Error loading feedback');
                        }

                        final hasFeedback =
                            snapshot.hasData && snapshot.data!.exists;
                        final feedbackData = hasFeedback
                            ? snapshot.data!.data() as Map<String, dynamic>
                            : null;
                        final existingRating = feedbackData?['rating'] ?? 0.0;
                        final existingComment = feedbackData?['comment'] ?? '';

                        if (!hasFeedback) {
                          // Show rating UI only if no feedback exists
                          return Column(
                            children: [
                              const Center(
                                child: Text(
                                  "Rate Our Service",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              RatingBar.builder(
                                initialRating: 0,
                                minRating: 1,
                                allowHalfRating: true,
                                itemCount: 5,
                                itemBuilder: (context, _) =>
                                    const Icon(Icons.star, color: Colors.amber),
                                onRatingUpdate: (rating) {
                                  // Handle rating update
                                },
                              ),
                              const SizedBox(height: 8),
                              const Text("Leave your feedback here."),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  // Show dialog to submit feedback
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      final TextEditingController
                                          feedbackController =
                                          TextEditingController();
                                      double newRating = 0;

                                      return AlertDialog(
                                        title: const Text("Leave Feedback"),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            RatingBar.builder(
                                              initialRating: 0,
                                              minRating: 1,
                                              allowHalfRating: true,
                                              itemCount: 5,
                                              itemBuilder: (context, _) =>
                                                  const Icon(Icons.star,
                                                      color: Colors.amber),
                                              onRatingUpdate: (rating) {
                                                newRating = rating;
                                              },
                                            ),
                                            const SizedBox(height: 8),
                                            TextField(
                                              controller: feedbackController,
                                              decoration: const InputDecoration(
                                                hintText:
                                                    "Type your feedback here...",
                                              ),
                                              maxLines: 4,
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text("Cancel"),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              // Ensure user is logged in
                                              final user = FirebaseAuth
                                                  .instance.currentUser;
                                              if (user == null) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          "Please log in to submit feedback.")),
                                                );
                                                return;
                                              }
                                              try {
                                                final feedbackText =
                                                    feedbackController.text;
                                                // Add new feedback in Firestore
                                                await FirebaseFirestore.instance
                                                    .collection(
                                                        'bookingRatings')
                                                    .doc(bookingId)
                                                    .set({
                                                  'rating': newRating,
                                                  'comment': feedbackText,
                                                  'submittedAt': FieldValue
                                                      .serverTimestamp(),
                                                  'userId': user.uid,
                                                  'centerUid': centerUid,
                                                  'bookingId': bookingId,
                                                });

                                                // Update booking document to mark feedback as submitted
                                                await FirebaseFirestore.instance
                                                    .collection('bookings')
                                                    .doc(bookingId)
                                                    .update(
                                                        {'hasFeedback': true});

                                                Navigator.pop(
                                                    context); // Close dialog
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          "Thanks for your feedback!")),
                                                );
                                              } catch (e) {
                                                // Handle errors
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(
                                                          "Failed to submit feedback: $e")),
                                                );
                                              }
                                            },
                                            child: const Text("Submit"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: const Text("Submit Feedback"),
                              ),
                            ],
                          );
                        } else {
                          // Show update UI only if feedback exists
                          return Column(
                            children: [
                              const Text(
                                "Your Rating",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              RatingBar.builder(
                                initialRating: existingRating,
                                minRating: 1,
                                allowHalfRating: true,
                                itemCount: 5,
                                itemBuilder: (context, _) => const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                                ignoreGestures:
                                    true, // Make rating bar non-interactive
                                onRatingUpdate:
                                    (rating) {}, // Empty callback since we're just displaying
                              ),
                              const SizedBox(height: 8),
                              Text("Your Feedback: $existingComment"),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  // Show dialog to update feedback
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      final TextEditingController
                                          feedbackController =
                                          TextEditingController(
                                              text: existingComment);
                                      double updatedRating = existingRating;

                                      return AlertDialog(
                                        title: const Text("Update Feedback"),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            RatingBar.builder(
                                              initialRating: existingRating,
                                              minRating: 1,
                                              allowHalfRating: true,
                                              itemCount: 5,
                                              itemBuilder: (context, _) =>
                                                  const Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                              ),
                                              onRatingUpdate: (rating) {
                                                updatedRating = rating;
                                              },
                                            ),
                                            const SizedBox(height: 8),
                                            TextField(
                                              controller: feedbackController,
                                              decoration: const InputDecoration(
                                                hintText:
                                                    "Type your feedback here...",
                                              ),
                                              maxLines: 4,
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text("Cancel"),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              // Ensure user is logged in
                                              final user = FirebaseAuth
                                                  .instance.currentUser;
                                              if (user == null) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          "Please log in to submit feedback.")),
                                                );
                                                return;
                                              }
                                              try {
                                                final feedbackText =
                                                    feedbackController.text;
                                                // Update feedback in Firestore
                                                await FirebaseFirestore.instance
                                                    .collection(
                                                        'bookingRatings')
                                                    .doc(bookingId)
                                                    .update({
                                                  'rating': updatedRating,
                                                  'comment': feedbackText,
                                                  'submittedAt': FieldValue
                                                      .serverTimestamp(),
                                                });

                                                Navigator.pop(
                                                    context); // Close dialog
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          "Thanks for updating your feedback!")),
                                                );
                                              } catch (e) {
                                                // Handle errors
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(
                                                          "Failed to update feedback: $e")),
                                                );
                                              }
                                            },
                                            child: const Text("Submit"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: const Text("Update Feedback"),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          // Proceed with payment button (if booking is in Confirmed state)
          if (status.toString().startsWith('Confirmed'))
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.payment, size: 20),
                  label: const Text(
                    "Proceed with Payment",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.blue.shade100),
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Select Payment Method"),
                          content: const Text(
                              "Choose how you'd like to pay for the service."),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // close dialog
                                _confirmCODPayment(context); // call function
                              },
                              child: const Text("Pay After Service (COD)"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // close dialog
                                // Razorpay integration to be done later
                                Navigator.pushNamed(
                                  context,
                                  '/payment',
                                  arguments: {
                                    'bookingId': bookingId,
                                    'amount': 1,
                                  },
                                );
                              },
                              child: const Text("Proceed with Online Payment"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      case 'Service Done':
        return Colors.grey[800]!;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Color _getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green.shade50;
      case 'cancelled':
        return Colors.grey.shade100;
      case 'pending':
        return Colors.orange.shade50;
      default:
        return Colors.blue.shade50;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'pending':
        return Icons.pending;
      default:
        return Icons.info;
    }
  }
}
