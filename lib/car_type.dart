import 'package:flutter/material.dart';

class CarType extends StatelessWidget {
  final String name;
  final String asset1;
  final VoidCallback onTap;
  final bool isSelected; // ✅ Track selection state

  const CarType({
    super.key,
    required this.name,
    required this.asset1,
    required this.onTap,
    required this.isSelected, // ✅ Receive selection state
  });

  @override
  Widget build(BuildContext context) {
    print(
        "🔹 Car Type Loaded: $name - Selected: $isSelected"); // ✅ Log car type state

    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        color: isSelected
            ? Colors.green
            : Colors.blue, // ✅ Change color if selected
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 8,
        child: InkWell(
          onTap: () {
            print("✅ Car Type Selected: $name"); // ✅ Log selection
            onTap(); // ✅ Call parent function to update selection
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                child: Image.asset(
                  asset1,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.fill,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 23, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
