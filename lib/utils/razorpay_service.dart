// // lib/razorpay_service.dart
//
// import 'package:razorpay_flutter/razorpay_flutter.dart';
//
// class RazorpayService {
//   Razorpay _razorpay;
//
//   RazorpayService() {
//     _razorpay = Razorpay();
//
//     _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
//     _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
//     _razorpay.on(Razorpay.EVENT_PAYMENT_CANCELLED, _handlePaymentCancel);
//   }
//
//   void openCheckout() {
//     var options = {
//       'key': 'your_razorpay_key', // Replace with your Razorpay key
//       'amount': 25000, // Amount in paisa (₹250 = 25000)
//       'name': 'Smart Wash Service',
//       'description': 'Payment for washing service',
//       'prefill': {
//         'name': 'Customer Name',
//         'email': 'customer@example.com',
//         'contact': '1234567890',
//       },
//     };
//
//     try {
//       _razorpay.open(options);
//     } catch (e) {
//       print('Error in opening Razorpay checkout: $e');
//     }
//   }
//
//   void _handlePaymentSuccess(PaymentSuccessResponse response) {
//     print('Payment Successful: ${response.paymentId}');
//     // Handle success logic (e.g., store payment details)
//   }
//
//   void _handlePaymentError(PaymentFailureResponse response) {
//     print('Payment Failed: ${response.error.description}');
//     // Handle failure logic
//   }
//
//   void _handlePaymentCancel(PaymentCancelResponse response) {
//     print('Payment Cancelled');
//     // Handle cancellation logic
//   }
// }
