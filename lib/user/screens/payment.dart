import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../app_bar.dart';

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

    // Automatically trigger payment on page load
    Future.delayed(Duration.zero, () {
      _openCheckout();
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

  void _openCheckout() {
    var options = {
      'key': 'rzp_test_6JdX7oPFCEpYn7', // Replace with your Razorpay Test Key
      'amount': widget.amount,
      'name': 'Smart Wash',
      'description': 'Booking for Wash',
      'prefill': {
        'contact': '9611227942',
        'email': 'shivakumarv3453@email.com',
      },
      'currency': 'INR',
      'theme': {'color': '#3399cc'}
    };

    if (kIsWeb) {
      // Web checkout (optional)
      // _openWebCheckout();
    } else {
      _openMobileCheckout(options);
    }
  }

  void _openMobileCheckout(Map<String, dynamic> options) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custAppBar(context, "Payment"),
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
