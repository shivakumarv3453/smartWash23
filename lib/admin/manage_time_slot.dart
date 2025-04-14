import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageTimeSlotsPopup extends StatefulWidget {
  final String adminUid;

  const ManageTimeSlotsPopup({super.key, required this.adminUid});

  @override
  _ManageTimeSlotsPopupState createState() => _ManageTimeSlotsPopupState();
}

class _ManageTimeSlotsPopupState extends State<ManageTimeSlotsPopup> {
  final Map<String, bool> defaultTimeSlots = {
    "11:00 AM": false,
    "2:00 PM": false,
    "4:00 PM": false,
    "6:00 PM": false,
    "8:00 PM": false,
  };

  late Map<String, bool> timeSlots;

  @override
  void initState() {
    super.initState();
    timeSlots = Map.from(defaultTimeSlots);
    fetchDisabledData();
  }

  void fetchDisabledData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('partners')
          .doc(widget.adminUid)
          .get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        var fetchedSlots =
            data['disabled_time_slots'] as Map<String, dynamic>? ?? {};

        setState(() {
          timeSlots = Map.from(defaultTimeSlots);
          fetchedSlots.forEach((key, value) {
            if (timeSlots.containsKey(key)) {
              timeSlots[key] = !(value as bool);
            }
          });
        });
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  Future<void> saveDisabledData() async {
    try {
      await FirebaseFirestore.instance
          .collection('partners')
          .doc(widget.adminUid)
          .set({
        'disabled_time_slots':
            timeSlots.map((key, value) => MapEntry(key, !value)),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error saving data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Manage Time Slots"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: timeSlots.keys.map((time) {
          return SwitchListTile(
            title: Text(time),
            value: timeSlots[time]!,
            onChanged: (value) {
              setState(() {
                timeSlots[time] = value;
              });

              // Save only after state is updated
              Future.microtask(() => saveDisabledData());
            },

          );
        }).toList(),
      ),
      actions: [
        TextButton(
          child: Text("Close"),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
