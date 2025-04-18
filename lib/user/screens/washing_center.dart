import 'package:flutter/material.dart';

class WashingCenterDropdown extends StatefulWidget {
  final List<String> centerNames;
  final Map<String, String> centerNameToLocation;
  final Function(String?) onCenterSelected;

  const WashingCenterDropdown({
    super.key,
    required this.centerNames,
    required this.centerNameToLocation,
    required this.onCenterSelected,
  });

  @override
  _WashingCenterDropdownState createState() => _WashingCenterDropdownState();
}

class _WashingCenterDropdownState extends State<WashingCenterDropdown> {
  String? _selectedCenter;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _selectedCenter,
      hint: const Text(
        "Choose Washing Center",
        style: TextStyle(color: Colors.grey),
      ),
      items: widget.centerNames.map((String center) {
        final location = widget.centerNameToLocation[center] ?? "";
        return DropdownMenuItem<String>(
          value: center,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: " ($location)",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedCenter = newValue;
        });
        widget.onCenterSelected(newValue);
      },
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: Colors.grey[100],
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.greenAccent, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.green, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      dropdownColor: Colors.white,
      icon: const Icon(Icons.arrow_drop_down, color: Colors.green, size: 30),
      isExpanded: true,
      isDense: true,
      menuMaxHeight: 200,
    );
  }
}
