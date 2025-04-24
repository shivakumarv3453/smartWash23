import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentPage extends StatefulWidget {
  final String bookingId;
  final int amount; // in paise

  const PaymentPage({super.key, required this.bookingId, required this.amount});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _openMobileCheckout(); // Trigger immediately
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _openMobileCheckout() async {
    final order = await _createOrderOnServer();
    if (order == null || order['id'] == null) {
      print('Order creation failed or order ID is missing');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create order')),
      );
      return;
    }

    print('Opening Razorpay checkout with Order ID: ${order['id']}');

    var options = {
      'key': 'rzp_test_6JdX7oPFCEpYn7',
      'amount': widget.amount,
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
        'paymentMethod': 'Online',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      navigator.pop(); // Close the loading dialog
      messenger.showSnackBar(
        const SnackBar(content: Text('Payment Successful!')),
      );
      navigator.pop(context); // Return to previous screen
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
        'paymentMethod': 'Online',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      navigator.pop(); // Close the loading dialog
      messenger.showSnackBar(
        SnackBar(content: Text('Payment Failed: ${response.message}')),
      );
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
      print('Amount (paise): ${widget.amount}');
      print('Receipt: ${widget.bookingId}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': widget.amount,
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
      appBar: AppBar(title: Text('Payment')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Redirecting to payment gateway..."),
          ],
        ),
      ),
    );
  }
}
