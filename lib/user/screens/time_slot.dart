import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_wash/user/app_bar.dart';
import 'package:smart_wash/user/bookings/booking_list.dart';
// import 'package:smart_wash/booking_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_wash/user/screens/profile.dart';
import 'package:intl/intl.dart';
import 'package:smart_wash/utils/location_utils.dart';
import 'package:smart_wash/utils/price_calculator.dart';
// import 'package:geocoding/geocoding.dart';

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

  LatLng? _partnerLocation;

  @override
  void initState() {
    super.initState();
    _generateCalendar();
    _fetchDisabledTimeSlots();
    _fetchPartnerLocation().then((_) {
      if (_partnerLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Could not fetch partner location. Using default pricing."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }

  Future<void> _fetchPartnerLocation() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('partners')
          .doc(widget.selectedCenterUid)
          .get();

      if (!doc.exists) {
        _setDefaultLocation();
        return;
      }

      final data = doc.data() as Map<String, dynamic>? ?? {};
      final address = data['location']?.toString() ?? '';
      debugPrint("Partner Firestore address: $address");

      final coordinates = await getCoordinatesFromAddress(address);
      if (coordinates != null) {
        setState(() {
          _partnerLocation = coordinates;
        });
      } else {
        debugPrint("Using default coordinates for partner due to null");
        _setDefaultLocation();
      }
    } catch (e) {
      debugPrint("Location fetch error: $e");
      _setDefaultLocation();
    }
  }

  LatLng _getDefaultLocation() => const LatLng(12.9716, 77.5946); // Bangalore

  void _setDefaultLocation() {
    setState(() => _partnerLocation = _getDefaultLocation());
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
    // Calculate price and show in dialog
    Future<Map<String, dynamic>> _calculatePriceDetails() async {
      try {
        bool usingExactLocation = true;
        LatLng userLocation;
        LatLng partnerLocation;

        // Get user location with fallback
        try {
          Position position = await Geolocator.getCurrentPosition();
          userLocation = LatLng(position.latitude, position.longitude);
        } catch (e) {
          debugPrint("Using default user location: $e");
          userLocation = const LatLng(12.9716, 77.5946); // Bangalore
          usingExactLocation = false;
        }

        // Get partner location
        partnerLocation = _partnerLocation ?? const LatLng(12.9716, 77.5946);
        if (_partnerLocation == null) {
          usingExactLocation = false;
        }

        debugPrint(
            "User Location: ${userLocation.latitude}, ${userLocation.longitude}");
        debugPrint(
            "Partner Location: ${partnerLocation.latitude}, ${partnerLocation.longitude}");

        final price = PriceCalculator.calculateFinalPrice(
          carType: widget.carType,
          washType: widget.washType,
          serviceType: widget.serviceType,
          userLat: userLocation.latitude,
          userLng: userLocation.longitude,
          centerLat: partnerLocation.latitude,
          centerLng: partnerLocation.longitude,
        );

        return {
          'price': price,
          'isExact': usingExactLocation,
          'message': usingExactLocation
              ? null
              : "Using approximate location for pricing",
        };
      } catch (e) {
        debugPrint("Price calculation error: $e");

        final basePrice = PriceCalculator.basePrices[widget.carType]
                ?[widget.washType]?[widget.serviceType] ??
            0;

        return {
          'price': basePrice,
          'isExact': false,
          'message': "Using base price only",
        };
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Confirm Booking",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: FutureBuilder<Map<String, dynamic>>(
            future: _calculatePriceDetails(),
            builder: (context, snapshot) {
              Widget content;

              if (snapshot.connectionState == ConnectionState.waiting) {
                content = Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBookingInfo(),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    const Text("Calculating price..."),
                  ],
                );
              } else if (snapshot.hasError) {
                content = Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBookingInfo(),
                    const SizedBox(height: 24),
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 36),
                    const SizedBox(height: 12),
                    const Text("Could not calculate price"),
                    const SizedBox(height: 8),
                    Text(
                      "₹${PriceCalculator.basePrices[widget.carType]?[widget.washType]?[widget.serviceType] ?? 0}",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Base price only",
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                );
              } else {
                final data = snapshot.data!;
                content = Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBookingInfo(),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        "₹${data['price']}",
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    if (data['message'] != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        data['message'],
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        data['isExact']
                            ? "Your total price"
                            : "Approximate price",
                        style: TextStyle(
                          color: data['isExact'] ? Colors.green : Colors.orange,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                );
              }

              return SingleChildScrollView(child: content);
            },
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                if (selectedTimeSlot == null) return;

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

                  // Recalculate price to ensure we have the latest
                  final price = await _calculatePriceDetails();

                  // Fetch user info
                  final userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .get();
                  final userData = userDoc.data();
                  final userName = userData?['username'] ?? 'N/A';
                  final userPhone = userData?['mobile'] ?? 'N/A';
                  final userLocation = userData?['location'] ?? 'N/A';

                  // Check for existing booking
                  final existingBooking = await FirebaseFirestore.instance
                      .collection('bookings')
                      .where('centerUid', isEqualTo: widget.selectedCenterUid)
                      .where('date', isEqualTo: formattedDate)
                      .where('time', isEqualTo: selectedTimeSlot)
                      .where('serviceType', isEqualTo: widget.serviceType)
                      .get();

                  if (existingBooking.docs.isNotEmpty) {
                    Navigator.of(context).pop(); // Close loader
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            "This time slot for the selected service is already booked."),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Create booking
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
                    'price': price,
                    'timestamp': FieldValue.serverTimestamp(),
                    'notificationSent': false,
                    'userCoordinates': GeoPoint(
                      (await Geolocator.getCurrentPosition()).latitude,
                      (await Geolocator.getCurrentPosition()).longitude,
                    ),
                    'centerCoordinates': GeoPoint(
                      _partnerLocation!.latitude,
                      _partnerLocation!.longitude,
                    ),
                  });

                  // Send notification
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
              child: const Text(
                "Confirm",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          ],
        );
      },
    );
  }

  Widget _buildBookingInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Center: ${widget.selectedCenter}"),
        Text("Service: ${widget.serviceType}"),
        Text("Car: ${widget.carType}"),
        Text("Wash: ${widget.washType}"),
        Text("Date: ${DateFormat('dd MMM yyyy').format(selectedDate)}"),
        Text("Time: $selectedTimeSlot"),
      ],
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
