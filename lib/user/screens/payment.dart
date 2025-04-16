// import 'dart:js' as js;
// import 'package:flutter/material.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';
// import 'package:smart_wash/user/app_bar.dart';

// class PaymentPage extends StatefulWidget {
//   final String bookingId;
//   final int amount; // Amount in paise (₹250 = 25000)

//   const PaymentPage({super.key, required this.bookingId, required this.amount});

//   @override
//   State<PaymentPage> createState() => _PaymentPageState();
// }

// class _PaymentPageState extends State<PaymentPage> {
//   late Razorpay _razorpay;

//   @override
//   void initState() {
//     super.initState();
//     _razorpay = Razorpay();

//     // Listeners for Razorpay events
//     _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
//     _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
//     _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
//   }

//   @override
//   void dispose() {
//     _razorpay.clear();
//     super.dispose();
//   }

//   // Function to initiate Razorpay checkout
//   void openCheckout() {
//     var options = {
//       'key': 'rzp_test_YourApiKeyHere', // Replace with your Test API Key
//       'amount': widget.amount, // Amount in paise (e.g., ₹250 = 25000)
//       'currency': 'INR',
//       'name': 'Smart Wash',
//       'description': 'Car Wash Booking',
//       'image': 'https://yourlogo.png', // optional logo url
//       'prefill': {
//         'name': 'Customer Name',
//         'email': 'customer@example.com',
//         'contact': '9123456780',
//       },
//       'theme': {'color': '#3399cc'}
//     };

//     try {
//       _razorpay.open(options);
//     } catch (e) {
//       print('Error: $e');
//     }
//   }

//   void _handlePaymentSuccess(PaymentSuccessResponse response) {
//     // Payment successful, you can now handle the response
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Payment Successful!')),
//     );
//     Navigator.pop(context); // Go back to booking list or show success screen
//   }

//   void _handlePaymentError(PaymentFailureResponse response) {
//     // Payment failed, handle the error
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Payment Failed: ${response.message}')),
//     );
//   }

//   void _handleExternalWallet(ExternalWalletResponse response) {
//     // Handle external wallet payment
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('External Wallet: ${response.walletName}')),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: custAppBar(context, "Payment"),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: openCheckout, // This will trigger the Razorpay checkout
//           child: Text(
//               "Pay ₹${widget.amount / 100}"), // Display amount as ₹500 if amount = 50000 (₹500)
//         ),
//       ),
//     );
//   }
// }

// above code for payment on web

// payment on android
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:smart_wash/user/app_bar.dart';

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
      'key': 'rzp_test_YourApiKeyHere', // Replace with your Razorpay Test Key
      'amount': widget.amount, // in paise
      'name': 'Smart Wash',
      'description': 'Booking for Wash',
      'prefill': {
        'contact': '9876543210',
        'email': 'testuser@email.com',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custAppBar(context, "Payment"),
      body: Center(
        child: ElevatedButton(
          onPressed: _openCheckout,
          child: const Text("Proceed to Pay"),
        ),
      ),
    );
  }
}
