import 'package:flutter/material.dart';
import 'package:smart_wash/app_bar.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final ValueNotifier<DateTime> _selectedDate;
  late final ValueNotifier<DateTime> _focusedDay;

  @override
  void initState() {
    super.initState();
    _selectedDate = ValueNotifier(DateTime.now());
    _focusedDay = ValueNotifier(DateTime.now());
  }

  @override
  void dispose() {
    _selectedDate.dispose();
    _focusedDay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custAppBar(context, "Booking dates"),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 10, 16),
          lastDay: DateTime.utc(2030, 3, 14),
          focusedDay: _focusedDay.value,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDate.value, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDate.value = selectedDay;
              _focusedDay.value = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay.value = focusedDay;
          },
        ),
      ),
    );
  }
}
