import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void openManageWashTypesDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Center(child: CircularProgressIndicator()),
  );

  FirebaseFirestore.instance
      .collection('partners')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .get()
      .then((snapshot) {
    Navigator.pop(context); // Close loading indicator

    if (!snapshot.exists) return;

    var data = snapshot.data() ?? {};
    Map<String, bool> washTypes = {
      "Standard": data["washTypes"]?["Standard"] ?? false,
      "Premium": data["washTypes"]?["Premium"] ?? false,
      "Ultra-Premium": data["washTypes"]?["Ultra-Premium"] ?? false,
    };

    // Show the dialog with fetched data
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> updateWashType(String type, bool value) async {
              try {
                await FirebaseFirestore.instance
                    .collection('partners')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .update({'washTypes.$type': value});

                setState(() {
                  washTypes[type] = value;
                });
              } catch (e) {
                print("Error updating wash type: $e");
              }
            }

            return AlertDialog(
              title: Text("Manage Wash Types"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: washTypes.keys.map((type) {
                  return SwitchListTile(
                    title: Text(type),
                    value: washTypes[type]!,
                    onChanged: (value) => updateWashType(type, value),
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
          },
        );
      },
    );
  }).catchError((error) {
    Navigator.pop(context); // Close loading indicator
    print("Error fetching wash types: $error");
  });
}
