import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

typedef DaySelectedCallback = void Function(DateTime selectedDay);

class DaySelector extends StatelessWidget {
  final DateTime selectedDay;
  final DaySelectedCallback onDaySelected;
  final List<String> disabledDays;

  const DaySelector({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
    required this.disabledDays,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List<DateTime>.generate(
      7,
      (index) => today.add(Duration(days: index)),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.map((day) {
        final weekday = DateFormat('EEEE').format(day);
        final isDisabled = disabledDays.contains(weekday);

        return _DayButton(
          day: day,
          isSelected: _isSameDate(day, selectedDay),
          isDisabled: isDisabled,
          onTap: () => onDaySelected(day),
        );
      }).toList(),
    );
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DayButton extends StatelessWidget {
  final DateTime day;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _DayButton({
    required this.day,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = DateTime.now().day == day.day &&
        DateTime.now().month == day.month &&
        DateTime.now().year == day.year;

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
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
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
          children: [
            Text(
              DateFormat('E').format(day).substring(0, 1),
              style: TextStyle(
                color: textColor,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${day.day}',
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
