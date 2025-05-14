import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PaymentPage extends StatefulWidget {
  final String bookingId;
  final double amount; // in rupees

  const PaymentPage({super.key, required this.bookingId, required this.amount});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late Razorpay _razorpay;
  bool _isLoading = false;
  String _paymentMethod = ""; // To track payment method

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // No longer auto-trigger payment
    // Instead, show payment options
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _openRazorpayCheckout() async {
    setState(() {
      _isLoading = true;
      _paymentMethod = "razorpay";
    });

    final order = await _createOrderOnServer();
    if (order == null || order['id'] == null) {
      print('Order creation failed or order ID is missing');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create order')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    print('Opening Razorpay checkout with Order ID: ${order['id']}');

    var options = {
      'key': 'rzp_test_6JdX7oPFCEpYn7',
      'amount': widget.amount * 100, // Convert to paise
      'name': 'Smart Wash',
      'description': 'Booking for Wash',
      'order_id': order['id'],
      'prefill': {
        'contact': '9611227942',
        'email': 'shivakumarv3453@email.com',
      },
      'currency': 'INR',
      'theme': {'color': '#3399cc'}
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> initiateUpiPayment() async {
    setState(() {
      _isLoading = true;
      _paymentMethod = "upi_direct";
    });

    String upiId = "paytm.s10e5s0@pty";
    String merchantName = "Smart Wash";
    String transactionNote = "Car Wash Payment";
    String amount = (widget.amount / 100).toString();
    String transactionRef = "TXN${DateTime.now().millisecondsSinceEpoch}";

    final upiUrl = "upi://pay?pa=$upiId&pn=$merchantName&am=$amount&cu=INR&tn=$transactionNote&tr=$transactionRef";

    final uri = Uri.parse(upiUrl);

    try {
      if (await canLaunchUrl(uri)) {
        bool launched = await launchUrl(uri);
        if (launched) {
          // Give the user time to complete the payment in their UPI app
          // When they return, we'll ask them about the status

          // Wait for 3 seconds to let the UPI app take over
          await Future.delayed(const Duration(seconds: 3));

          // Now the payment flow is passed to UPI app
          // We'll show a confirmation dialog when they return
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            _showPaymentVerificationDialog();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to launch UPI app")),
            );
            setState(() {
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No UPI app found on device")),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Show a dialog to verify payment status
  void _showPaymentVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Payment Verification"),
          content: const Text("Did you complete the payment successfully?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleUpiPaymentSuccess();
              },
              child: const Text("Yes, Payment Complete"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleUpiPaymentFailure();
              },
              child: const Text("No, Payment Failed"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Try again"),
            ),
          ],
        );
      },
    );
  }

  // Handle UPI payment success
  void _handleUpiPaymentSuccess() async {
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
            Text('Updating payment status...'),
          ],
        ),
      ),
    );

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
        'status': 'Payment Method Confirmed (UPI)',
        'paymentStatus': 'success',
        'paymentId': 'direct_upi_${DateTime.now().millisecondsSinceEpoch}',
        'paymentMethod': 'UPI Direct',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop(); // Close the loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment Successful!')),
      );

      // Return to previous screen with success result
      Navigator.of(context).pop('success');
    } catch (e, stackTrace) {
      Navigator.of(context).pop(); // Close the loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment succeeded but failed to update status'),
          backgroundColor: Colors.orange,
        ),
      );
      debugPrint('Error: $e\n$stackTrace');
    }
  }

  // Handle UPI payment failure
  void _handleUpiPaymentFailure() async {
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
            Text('Updating payment status...'),
          ],
        ),
      ),
    );

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
        'status': 'Payment Failed',
        'paymentStatus': 'failed',
        'errorMessage': 'UPI payment cancelled or failed',
        'paymentMethod': 'UPI Direct',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop(); // Close the loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment Failed')),
      );

      // Return to previous screen with failure result
      Navigator.of(context).pop('failure');
    } catch (e, stackTrace) {
      Navigator.of(context).pop(); // Close the loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update payment status'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Error: $e\n$stackTrace');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

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
            Text('Updating payment status...'),
          ],
        ),
      ),
    );

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
        'status': 'Payment Method Confirmed (Online)',
        'paymentStatus': 'success',
        'paymentId': response.paymentId,
        'paymentMethod': 'Razorpay',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      navigator.pop(); // Close the loading dialog
      messenger.showSnackBar(
        const SnackBar(content: Text('Payment Successful!')),
      );
      navigator.pop('success'); // Return to previous screen with success result
    } catch (e, stackTrace) {
      navigator.pop(); // Close the loading dialog
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Payment succeeded but failed to update status'),
          backgroundColor: Colors.orange,
        ),
      );
      debugPrint('Error: $e\n$stackTrace');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

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
            Text('Updating payment status...'),
          ],
        ),
      ),
    );

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
        'status': 'Payment Failed',
        'paymentStatus': 'failed',
        'errorMessage': response.message ?? 'Unknown error',
        'paymentMethod': 'Razorpay',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      navigator.pop(); // Close the loading dialog
      messenger.showSnackBar(
        SnackBar(content: Text('Payment Failed: ${response.message}')),
      );
      navigator.pop('failure'); // Return with failure result
    } catch (e, stackTrace) {
      navigator.pop(); // Close the loading dialog
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to update payment status'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Error: $e\n$stackTrace');
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet: ${response.walletName}')),
    );
  }

  Future<Map<String, dynamic>?> _createOrderOnServer() async {
    try {
      final url =
      Uri.parse('https://smartwash-backend.onrender.com/create-order');

      print('Calling backend to create Razorpay order...');
      print('Amount (rupees): ${widget.amount}');
      print('Receipt: ${widget.bookingId}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': widget.amount * 100, // Convert to paise
          'currency': 'INR',
          'receipt': widget.bookingId,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Order created: ${data['id']}');
        return data;
      } else {
        print('Failed to create order: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception in _createOrderOnServer: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Options'),
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Processing payment request..."),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Booking ID:'),
                        Text(widget.bookingId),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount:'),
                        Text(
                          '₹${widget.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Payment Methods
            // Direct UPI Payment Option
            Card(
              child: InkWell(
                onTap: initiateUpiPayment,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.payment,
                          color: Colors.green.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pay with UPI',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Google Pay, PhonePe, Paytm, etc.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}