import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DayButton extends StatelessWidget {
  final DateTime? day;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDisabledByAdmin;

  const DayButton({
    super.key,
    required this.day,
    required this.isSelected,
    required this.onTap,
    required this.isDisabledByAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final lastValidDate = today.add(const Duration(days: 7));
    final isToday = day != null &&
        day!.year == today.year &&
        day!.month == today.month &&
        day!.day == today.day;

    final isDisabled = day == null ||
        day!.isBefore(DateTime(today.year, today.month, today.day)) ||
        day!.isAfter(lastValidDate) ||
        isDisabledByAdmin;

    final Color bgColor;
    final Color textColor;
    final Color borderColor;

    if (isDisabled) {
      bgColor = Colors.grey.shade100;
      textColor = Colors.grey.shade400;
      borderColor = Colors.grey.shade300;
    } else if (isSelected) {
      bgColor = Theme.of(context).primaryColor;
      textColor = Colors.white;
      borderColor = Theme.of(context).primaryColor;
    } else if (isToday) {
      bgColor = Colors.blue.shade50;
      textColor = Theme.of(context).primaryColor;
      borderColor = Colors.blue.shade100;
    } else {
      bgColor = Colors.white;
      textColor = Colors.black87;
      borderColor = Colors.grey.shade200;
    }

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        width: 40,
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            if (!isDisabled && (isSelected || isToday))
              const BoxShadow(
                color: Colors.black12,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              day != null ? DateFormat('E').format(day!).substring(0, 1) : '',
              style: TextStyle(
                color: textColor,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              day != null ? '${day!.day}' : '',
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isToday && !isSelected && !isDisabled)
              Container(
                margin: const EdgeInsets.only(top: 2),
                height: 3,
                width: 3,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
