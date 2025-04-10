import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_wash/app_bar.dart';

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
              const Text(
                "10% cancellation fee will apply",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
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
    // Store context references first
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Authentication required')));
      return;
    }

    // Show loading dialog
    final loadingDialog = showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processing cancellation...'),
            ],
          ),
        ),
      ),
    );

    try {
      // Prepare update data according to rules
      final updateData = {
        'status': 'Cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        // Add user ID to help with debugging
        'lastUpdatedBy': currentUser.uid,
      };

      // Execute the update
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update(updateData);

      // Close dialogs and navigate
      await loadingDialog; // Ensure loading dialog is mounted
      navigator.pop(); // Close loading
      navigator.pop(); // Return to previous screen

      // Show success
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Booking cancelled successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );

    } on FirebaseException catch (e) {
      navigator.pop(); // Close loading

      final errorMessage = switch (e.code) {
        'permission-denied' => 'You do not have permission to cancel this booking',
        'not-found' => 'Booking not found',
        _ => 'Failed to cancel: ${e.message ?? 'Unknown error'}',
      };

      messenger.showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      debugPrint('Firestore error: ${e.code} - ${e.message}');

    } catch (e, stack) {
      navigator.pop(); // Close loading
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Unexpected error occurred'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Error: $e\n$stack');
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

  @override
  Widget build(BuildContext context) {
    final status = bookingData['status'] ?? 'Pending';

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

                  // Additional space if needed
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Cancel button (conditionally shown)
          if (status != 'Cancelled' && status != 'Completed')
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
      case 'pending':
        return Colors.orange;
      default:
        return Colors.blue;
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
