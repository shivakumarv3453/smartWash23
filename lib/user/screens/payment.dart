import 'package:flutter/material.dart';
import 'package:smart_wash/user/app_bar.dart';

class PaymentPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custAppBar(context, "Payment"),
      body: Center(
        child: Text("Payment functionality coming soon!"),
      ),
    );
  }
}
