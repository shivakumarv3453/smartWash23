import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentPage extends StatefulWidget {
  final String bookingId;
  final int amount; // in paise (₹250 = 25000)

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

    // Automatically trigger payment on page load for web
    Future.delayed(Duration.zero, () {
      if (kIsWeb) {
        _openWebCheckout(); // Web checkout
      } else {
        _openMobileCheckout(); // Mobile checkout
      }
    });

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // // Web checkout implementation
  void _openWebCheckout() async {
    final order = await _createOrderOnServer();

    if (order == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create order')),
      );
      return;
    }

    final options = {
      'key': 'rzp_test_6JdX7oPFCEpYn7',
      'amount': widget.amount,
      'name': 'Smart Wash',
      'description': 'Booking for Wash',
      'order_id': order['id'], // 👈 Very important for web
      'prefill': {
        'contact': '9611227942',
        'email': 'shivakumarv3453@email.com',
      },
      'currency': 'INR',
      'theme': {'color': '#3399cc'}
    };

    // Open Razorpay checkout in web view
    html.window.open('https://checkout.razorpay.com/v1/checkout.js',
        'Razorpay Payment', 'width=500, height=600');

    html.window.postMessage(options, '*');
  }

  // Mobile checkout implementation
  void _openMobileCheckout() async {
    final order = await _createOrderOnServer();

    if (order == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create order')),
      );
      return;
    }

    var options = {
      'key': 'rzp_test_6JdX7oPFCEpYn7',
      'amount': widget.amount,
      'name': 'Smart Wash',
      'description': 'Booking for Wash',
      'order_id': order['id'], // 👈 Required for Razorpay server integration
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
      debugPrint('Razorpay Error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment Successful!')),
    );
    Navigator.pop(context);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('External Wallet Selected: ${response.walletName}')),
    );
  }

  Future<Map<String, dynamic>?> _createOrderOnServer() async {
    try {
      final url = Uri.parse(
          'http://127.0.0.1:3000/create-order'); // Use actual backend URL if deployed

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': widget.amount,
          'currency': 'INR',
          'receipt': widget.bookingId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
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
