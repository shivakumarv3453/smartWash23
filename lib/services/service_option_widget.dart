import 'package:flutter/material.dart';

Widget buildServiceOption({
  required bool isEnabled,
  required String serviceName,
  required String description,
  required VoidCallback onTap,
  required bool isSelected,
}) {
  return GestureDetector(
    onTap: isEnabled ? onTap : null, // Disable tap if not enabled
    child: Container(
      decoration: BoxDecoration(
        color: isEnabled
            ? (isSelected ? Colors.lightGreen[200] : Colors.grey[200])
            : Colors.grey[300], // Disabled state
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isEnabled ? Colors.green : Colors.grey,
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            serviceName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isEnabled ? Colors.black : Colors.grey,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    ),
  );
}
