import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageDaysPopup extends StatefulWidget {
  final String adminUid;

  const ManageDaysPopup({super.key, required this.adminUid});

  @override
  _ManageDaysPopupState createState() => _ManageDaysPopupState();
}

class _ManageDaysPopupState extends State<ManageDaysPopup> {
  final Map<String, bool> defaultDays = {
    "Monday": false,
    "Tuesday": false,
    "Wednesday": false,
    "Thursday": false,
    "Friday": false,
    "Saturday": false,
    "Sunday": false,
  };

  late Map<String, bool> days;

  @override
  void initState() {
    super.initState();
    days = Map.from(defaultDays);
    fetchDisabledDays();
  }

  void fetchDisabledDays() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('partners')
          .doc(widget.adminUid)
          .get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        var fetchedDays = data['disabled_days'] as Map<String, dynamic>? ?? {};

        setState(() {
          days = Map.from(defaultDays);
          fetchedDays.forEach((key, value) {
            if (days.containsKey(key)) {
              days[key] = !(value as bool);
            }
          });
        });
      }
    } catch (e) {
      print("Error fetching days: $e");
    }
  }

  Future<void> saveDisabledDays() async {
    try {
      await FirebaseFirestore.instance
          .collection('partners')
          .doc(widget.adminUid)
          .set({
        'disabled_days': days.map((key, value) => MapEntry(key, !value)),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error saving days: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Manage Days of the Week"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: days.keys.map((day) {
          return SwitchListTile(
            title: Text(day),
            value: days[day]!,
            onChanged: (value) {
              setState(() {
                days[day] = value;
              });

              Future.microtask(() => saveDisabledDays());
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
