import 'package:flutter/material.dart';

class StaticWashingCenterDropdown extends StatelessWidget {
  final List<String> centerNames;
  final String? selectedCenter;
  final Function(String?) onCenterSelected;

  const StaticWashingCenterDropdown({
    super.key,
    required this.centerNames,
    required this.selectedCenter,
    required this.onCenterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Washing Center",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButton<String>(
          isExpanded: true,
          hint: const Text("Choose a center"),
          value: selectedCenter != null && centerNames.contains(selectedCenter)
              ? selectedCenter
              : null,
          items: centerNames.map((String center) {
            return DropdownMenuItem<String>(
              value: center,
              child: Text(center),
            );
          }).toList(),
          onChanged: (String? newValue) {
            onCenterSelected(newValue);
          },
        ),
      ],
    );
  }
}
