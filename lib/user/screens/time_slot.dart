import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_wash/user/app_bar.dart';
import 'package:smart_wash/user/bookings/booking_list.dart';
// import 'package:smart_wash/booking_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_wash/user/screens/profile.dart';
import 'package:intl/intl.dart';

class TimeSlotPage extends StatefulWidget {
  final String selectedCenterUid;
  final String selectedCenter;
  final String serviceType;
  final String carType;
  final String washType;
  final String asset;

  const TimeSlotPage({
    super.key,
    required this.selectedCenterUid,
    required this.selectedCenter,
    required this.serviceType,
    required this.carType,
    required this.washType,
    required this.asset,
  });

  @override
  State<TimeSlotPage> createState() => _TimeSlotPageState();
}

class _TimeSlotPageState extends State<TimeSlotPage> {
  DateTime selectedDate = DateTime.now();
  String? selectedTimeSlot;
  late List<List<DateTime?>> weeks;
  Map<String, bool> disabledTimeSlots = {};
  DateTime today = DateTime.now();
  DateTime lastSelectableDate = DateTime.now().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    _generateCalendar();
    _fetchDisabledTimeSlots();
  }

  void _fetchDisabledTimeSlots() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('partners')
        .doc(widget.selectedCenterUid)
        .get();

    if (doc.exists) {
      var data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('disabled_time_slots')) {
        setState(() {
          disabledTimeSlots =
              Map<String, bool>.from(data['disabled_time_slots']);
        });
      }
    }
  }

  void _generateCalendar() {
    DateTime firstDayOfMonth =
        DateTime(selectedDate.year, selectedDate.month, 1);
    int firstDayOfWeek = firstDayOfMonth.weekday;
    int daysInMonth =
        DateTime(selectedDate.year, selectedDate.month + 1, 0).day;

    weeks = [];
    int day = 1;
    DateTime today = DateTime.now();
    DateTime lastValidDate = today.add(const Duration(days: 7));

    for (int i = 0; i < 6; i++) {
      List<DateTime?> week = [];
      for (int j = 0; j < 7; j++) {
        if (i == 0 && j < firstDayOfWeek - 1) {
          week.add(null);
        } else if (day <= daysInMonth) {
          DateTime currentDate =
              DateTime(selectedDate.year, selectedDate.month, day);
          if (currentDate.isBefore(today) ||
              currentDate.isAfter(lastValidDate)) {
            week.add(null); // Disable past/future dates
          } else {
            week.add(currentDate); // Valid date
          }
          day++;
        } else {
          week.add(null);
        }
      }
      weeks.add(week);
    }
  }

  Future<bool> isUserProfileComplete(String userId) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!docSnapshot.exists) {
        debugPrint('User document does not exist');
        return false;
      }

      final data = docSnapshot.data();
      if (data == null) {
        debugPrint('User data is null');
        return false;
      }

      final username = data['username'];
      final mobile = data['mobile'];
      final location = data['location'];

      if (username == null || username.toString().trim().isEmpty) {
        debugPrint('Username is empty or null');
        return false;
      }

      if (mobile == null || mobile.toString().trim().isEmpty) {
        debugPrint('Mobile is empty or null');
        return false;
      }

      if (location == null || location.toString().trim().isEmpty) {
        debugPrint('Location is empty or null');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error checking profile completeness: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custAppBar(context, "Choose Date & Time Slot"),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // Remove the fixed height SizedBox and let content determine height
            Column(
              children: [
                // Day headers
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _DayHeader("Sun"),
                    _DayHeader("Mon"),
                    _DayHeader("Tue"),
                    _DayHeader("Wed"),
                    _DayHeader("Thu"),
                    _DayHeader("Fri"),
                    _DayHeader("Sat"),
                  ],
                ),
                const SizedBox(height: 8),
                // Calendar grid - use ListView if you have many weeks
                Column(
                  mainAxisSize: MainAxisSize.min, // Important
                  children: weeks.map((week) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: week.map((day) {
                          return _DayButton(
                            day: day,
                            isSelected: selectedDate.day == day?.day,
                            onTap: () {
                              if (day != null) {
                                setState(() {
                                  selectedDate = day;
                                  _generateCalendar();
                                });
                                _showTimeSlotDialog(context);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTimeSlotDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Choose a Time Slot"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTimeSlotButton(context, '11:00 AM'),
              const SizedBox(height: 10),
              _buildTimeSlotButton(context, '2:00 PM'),
              const SizedBox(height: 10),
              _buildTimeSlotButton(context, '4:00 PM'),
              const SizedBox(height: 10),
              _buildTimeSlotButton(context, '6:00 PM'),
              const SizedBox(height: 10),
              _buildTimeSlotButton(context, '8:00 PM'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeSlotButton(BuildContext context, String timeSlot) {
    bool isDisabled = disabledTimeSlots[timeSlot] == true;

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              setState(() {
                selectedTimeSlot = timeSlot;
              });
              Navigator.of(context).pop();
              _showConfirmationDialog(context);
            },
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey.shade400
              : (selectedTimeSlot == timeSlot ? Colors.blue : Colors.grey),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Center(
          child: Text(
            timeSlot,
            style: TextStyle(
              color: isDisabled ? Colors.black54 : Colors.white,
              fontWeight: isDisabled ? FontWeight.w300 : FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Booking"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Center: ${widget.selectedCenter}"),
              Text("Service: ${widget.serviceType}"),
              Text("Car: ${widget.carType}"),
              Text("Wash: ${widget.washType}"),
              Text("Date: ${selectedDate.toLocal().toString().split(' ')[0]}"),
              Text("Time: $selectedTimeSlot"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () async {
                final userId = FirebaseAuth.instance.currentUser?.uid;

                if (userId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please login to book")),
                  );
                  return;
                }

                final isComplete = await isUserProfileComplete(userId);
                if (!isComplete) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Please complete your profile before booking.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfilePage()),
                  );
                  return;
                }

                // Show loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  final formattedDate =
                      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

                  // ✅ Fetch user info from `users` collection
                  final userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .get();
                  final userData = userDoc.data();

                  final userName = userData?['username'] ?? 'N/A';
                  final userPhone = userData?['mobile'] ?? 'N/A';
                  final userLocation = userData?['location'] ?? 'N/A';

                  // ✅ Create booking document with user info included
                  DocumentReference bookingRef = await FirebaseFirestore
                      .instance
                      .collection('bookings')
                      .add({
                    'centerUid': widget.selectedCenterUid,
                    'center': widget.selectedCenter,
                    'carType': widget.carType,
                    'washType': widget.washType,
                    'serviceType': widget.serviceType,
                    'date': formattedDate,
                    'time': selectedTimeSlot,
                    'status': 'Pending',
                    'userId': userId,
                    'userName': userName,
                    'userPhone': userPhone,
                    'userLocation': userLocation,
                    'timestamp': FieldValue.serverTimestamp(),
                    'notificationSent': false,
                  });

                  // Send notification to admin
                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .doc()
                      .set({
                    'type': 'new_booking',
                    'bookingId': bookingRef.id,
                    'adminUid': widget.selectedCenterUid,
                    'title': 'New Booking',
                    'message': 'New booking at ${widget.selectedCenter}',
                    'timestamp': FieldValue.serverTimestamp(),
                    'read': false,
                  });

                  // Mark notification as sent
                  await bookingRef.update({'notificationSent': true});

                  Navigator.of(context).pop(); // Close loader
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Booking created successfully!")),
                  );

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => BookingListScreen()),
                    (route) => false,
                  );
                } catch (e) {
                  Navigator.of(context).pop(); // Close loader
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error creating booking: $e")),
                  );
                }
              },
              child:
                  const Text("Confirm", style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String day;
  const _DayHeader(this.day);

  @override
  Widget build(BuildContext context) {
    return Text(
      day,
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }
}

class _DayButton extends StatelessWidget {
  final DateTime? day;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayButton({
    required this.day,
    required this.isSelected,
    required this.onTap,
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
        day!.isAfter(lastValidDate);

    // Colors
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
        width: 40, // Fixed width
        height: 56, // Fixed height
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
              BoxShadow(
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
