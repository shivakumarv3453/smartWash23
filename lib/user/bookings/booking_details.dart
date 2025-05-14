import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_wash/constants/app_colors.dart';
import 'package:smart_wash/user/app_bar.dart';
import 'package:smart_wash/user/screens/feedback_display.dart';
import 'package:smart_wash/user/screens/feedback_error_widget.dart';
import 'package:smart_wash/user/screens/feedback_input_form.dart';

class BookingDetailsScreen extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const BookingDetailsScreen({
    super.key,
    required this.bookingId,
    required this.bookingData,
  });

  void _showCancelConfirmation(BuildContext context) {
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

  Widget _buildDetailRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: valueStyle ?? const TextStyle(fontSize: 16),
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
            Text('Confirming COD payment...'),
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
        'paymentStatus': 'pending', // Payment will be collected on delivery
        'lastUpdatedBy': currentUser.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      navigator.pop(); // Close the loading dialog
      messenger.showSnackBar(
        const SnackBar(content: Text('COD payment confirmed successfully')),
      );
    } catch (e, stackTrace) {
      navigator.pop(); // Close the loading dialog
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to confirm COD payment'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Error: $e\n$stackTrace');
    }
  }

  Future<void> _confirmOnlinePayment(BuildContext context) async {
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
            Text('Confirming online payment...'),
          ],
        ),
      ),
    );

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': 'Payment Method Confirmed (Online)',
        'paymentMethod': 'Online',
        'paymentStatus': 'paid', // Online payment is already received
        'lastUpdatedBy': currentUser.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      navigator.pop(); // Close the loading dialog
      messenger.showSnackBar(
        const SnackBar(content: Text('Online payment confirmed successfully')),
      );
    } catch (e, stackTrace) {
      navigator.pop(); // Close the loading dialog
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to confirm online payment'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Error: $e\n$stackTrace');
    }
  }
  @override
  Widget build(BuildContext context) {
    final rawStatus = bookingData['status'] ?? 'Pending';
    final centerUid = bookingData['centerUid'];

    // Customize status label for user
    final status = rawStatus == 'Confirmed - Awaiting Payment'
        ? 'Confirmed - Proceed with Payment'
        : rawStatus;

    return Scaffold(
      appBar: custAppBar(context, 'Booking Details'),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookingData = snapshot.data!.data() as Map<String, dynamic>;
          final rawStatus = bookingData['status'] ?? 'Pending';
          final centerUid = bookingData['centerUid'];
          final double price = (bookingData['price'] is Map)
              ? ((bookingData['price'] as Map)['price'] is String
              ? double.parse((bookingData['price'] as Map)['price'])
              : (bookingData['price'] as Map)['price']?.toDouble() ?? 0.0)
              : (bookingData['price'] is String
              ? double.parse(bookingData['price'])
              : (bookingData['price']?.toDouble() ?? 0.0));
          final paymentMethod = bookingData['paymentMethod'] ?? 'Not specified';

          // Customize status label for user
          final status = rawStatus == 'Confirmed - Awaiting Payment'
              ? 'Confirmed - Proceed with Payment'
              : rawStatus;

          return Column(
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
                      _buildDetailRow("Wash Type", bookingData['washType'] ?? 'N/A'),
                      _buildDetailRow("Service", bookingData['serviceType'] ?? 'N/A'),
                      _buildDetailRow("Date", bookingData['date'] ?? 'N/A'),
                      _buildDetailRow("Time", bookingData['time'] ?? 'N/A'),

                      // Price and Payment Method section
                      const SizedBox(height: 16),
                      const Text(
                        "PAYMENT INFORMATION",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Divider(height: 16),
                      _buildDetailRow(
                        "Total Amount",
                        "₹${price.toString()}",
                        valueStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                          fontSize: 16,
                        ),
                      ),
                      _buildDetailRow(
                        "Payment Method",
                        _formatPaymentMethod(paymentMethod),
                        valueStyle: TextStyle(
                          color: paymentMethod == 'COD'
                              ? Colors.orange[700]
                              : Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      // Customer details section
                      const SizedBox(height: 16),
                      const Text(
                        "CUSTOMER DETAILS",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Divider(height: 16),
                      _buildDetailRow("Name", bookingData['userName'] ?? 'N/A'),
                      _buildDetailRow("Phone", bookingData['userPhone'] ?? 'N/A'),
                      _buildDetailRow("Location", bookingData['userLocation'] ?? 'N/A'),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Action buttons section
              if (status != 'Cancelled' &&
                  status != 'Completed' &&
                  status != 'Rejected' &&
                  status != 'Service Done')
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

              // Feedback section
              if (status == 'Service Done')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: AppColors.primaryLight,
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('bookingRatings')
                          .doc(bookingId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) return const FeedbackErrorWidget();

                        final hasFeedback = snapshot.hasData && snapshot.data!.exists;
                        final feedbackData = hasFeedback
                            ? snapshot.data!.data() as Map<String, dynamic>
                            : null;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Your Experience",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (!hasFeedback)
                              FeedbackInputForm(
                                bookingId: bookingId,
                                centerUid: centerUid,
                              )
                            else
                              FeedbackDisplay(
                                rating: feedbackData?['rating'] ?? 0.0,
                                comment: feedbackData?['comment'] ?? '',
                                bookingId: bookingId,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

              // Proceed with payment button
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
                            return Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                              backgroundColor: Colors.transparent,
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Select Payment Method",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      "Choose how you'd like to pay for the service",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // COD Option
                                    InkWell(
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        _confirmCODPayment(context);
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade200),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade50,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.account_balance_wallet_outlined,
                                                color: Colors.orange,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            const Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Pay after Service",
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    "Pay after the service completion",
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(
                                              Icons.chevron_right,
                                              color: Colors.grey,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Online Payment Option
                                    InkWell(
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        Navigator.of(context)
                                            .pushNamed('/payment', arguments: {
                                          'bookingId': bookingId,
                                          'amount': price,
                                        }).then((result) {
                                          if (result == 'success') {
                                            _confirmOnlinePayment(context);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Payment not completed'),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade200),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.credit_card,
                                                color: Colors.blue,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            const Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Online Payment",
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    "Pay securely with card/UPI",
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(
                                              Icons.chevron_right,
                                              color: Colors.grey,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    // Cancel Button
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      style: TextButton.styleFrom(
                                        minimumSize: const Size(double.infinity, 48),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text(
                                        "Cancel",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

// Helper method to format payment method display
  String _formatPaymentMethod(String method) {
    switch (method) {
      case 'COD':
        return 'Pay after Service';
      case 'Online':
        return 'Online Payment';
      case 'Wallet':
        return 'Wallet Balance';
      default:
        return method;
    }
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
      case 'Confirmed - Proceed with Payment':
        return Colors.blue.shade800;
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
