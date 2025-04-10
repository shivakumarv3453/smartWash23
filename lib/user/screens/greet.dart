import 'package:flutter/material.dart';
import 'package:smart_wash/user/app_bar.dart';
import 'package:smart_wash/user/screens/car_type.dart';
import 'package:smart_wash/user/screens/wash_type.dart';

class Greet extends StatefulWidget {
  final String selectedCenter;
  final String centerUid; // New required parameter
  final String serviceType; // New required parameter

  const Greet({
    super.key,
    required this.selectedCenter,
    required this.centerUid,
    required this.serviceType,
  });

  @override
  State<Greet> createState() => _GreetState();
}

class _GreetState extends State<Greet> {
  String? selectedCarType;

  void _navigateToWashType(BuildContext context, String carType, String asset) {
    setState(() => selectedCarType = carType);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WashType(
          centerUid: widget.centerUid,
          washType: carType, // Changed parameter name to match WashType
          asset: asset,
          // Add these new required parameters:
          selectedCenter: widget.selectedCenter,
          serviceType: widget.serviceType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> carTypes = [
      {"name": "Sedan", "asset": "assets/images/sedan.jpg"},
      {"name": "SUV", "asset": "assets/images/suv.jpeg"},
      {"name": "HatchBack", "asset": "assets/images/small.png"},
    ];

    return Scaffold(
      appBar: custAppBar(context, "Car Type"),
      body: ListView(
        children: carTypes.map((car) {
          return CarType(
            name: car["name"]!,
            asset1: car["asset"]!,
            isSelected: selectedCarType == car["name"], // Pass selection state
            onTap: () =>
                _navigateToWashType(context, car["name"]!, car["asset"]!),
          );
        }).toList(),
      ),
    );
  }
}
