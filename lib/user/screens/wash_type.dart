import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_wash/user/app_bar.dart';
import 'package:smart_wash/user/screens/time_slot.dart';
import 'dynamic_card.dart';

// ✅ Global variable to store selected wash type
String? selectedWashType;

class WashType extends StatefulWidget {
  final String centerUid;
  final String washType;
  final String asset;
  final String selectedCenter; // New parameter
  final String serviceType; // New parameter

  const WashType({
    super.key,
    required this.centerUid,
    required this.washType,
    required this.asset,
    required this.selectedCenter,
    required this.serviceType,
  });

  @override
  _WashTypeState createState() => _WashTypeState();
}

class _WashTypeState extends State<WashType> {
  Map<String, bool> washTypeAvailability = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    print("📡 Fetching wash type availability for center: ${widget.centerUid}");
    fetchWashTypeAvailability();
  }

  Future<void> fetchWashTypeAvailability() async {
    try {
      DocumentSnapshot centerDoc = await FirebaseFirestore.instance
          .collection('partners')
          .doc(widget.centerUid)
          .get();

      if (centerDoc.exists) {
        Map<String, dynamic>? data = centerDoc.data() as Map<String, dynamic>?;
        if (data != null && data['washTypes'] != null) {
          setState(() {
            washTypeAvailability = Map<String, bool>.from(data['washTypes']);
            isLoading = false;
          });
          print("✅ Updated wash type availability: $washTypeAvailability");
        }
      } else {
        print("⚠️ No data found for center UID: ${widget.centerUid}");
      }
    } catch (e) {
      print("❌ Error fetching wash type availability: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, String> keyMapping = {
      "Standard Wash": "Standard",
      "Premium Wash": "Premium",
      "Ultra Premium Wash": "Ultra-Premium",
    };

    final List<Map<String, String>> washTypes = [
      {
        'imagePath': 'assets/images/main4.jpg',
        'description': 'Standard Wash',
        'price': 'Rs.200',
        'briefDescription':
            'A basic car wash that cleans only the exterior, windows, and tires.'
      },
      {
        'imagePath': 'assets/images/main1.jpeg',
        'description': 'Premium Wash',
        'price': 'Rs.300',
        'briefDescription':
            'The Premium wash includes exterior wash, interior cleaning, and tire polishing.'
      },
      {
        'imagePath': 'assets/images/main.jpeg',
        'description': 'Ultra Premium Wash',
        'price': 'Rs.500',
        'briefDescription':
            'The Ultra Premium wash includes full exterior and interior cleaning, waxing, polishing, and premium services.'
      },
    ];

    return Scaffold(
      appBar: custAppBar(context, "Wash Type"),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: washTypes.map((washType) {
                    String washTypeKey = washType['description'] ?? "";
                    String firestoreKey =
                        keyMapping[washTypeKey] ?? washTypeKey;
                    bool isEnabled =
                        washTypeAvailability[firestoreKey] ?? false;

                    print(
                        "🔎 Checking washType: $washTypeKey (Firestore Key: $firestoreKey) -> Enabled: $isEnabled");

                    return Opacity(
                      opacity: isEnabled ? 1.0 : 0.5,
                      child: IgnorePointer(
                        ignoring: !isEnabled,
                        child: DynamicCard(
                          imagePath: washType['imagePath']!,
                          description: washType['description']!,
                          price: washType['price']!,
                          briefDescription: washType['briefDescription']!,
                          onTap: () {
                            if (isEnabled) {
                              setState(() {
                                selectedWashType = washTypeKey;
                              });
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TimeSlotPage(
                                    selectedCenterUid: widget.centerUid,
                                    // Pass all collected data forward:
                                    selectedCenter: widget.selectedCenter,
                                    serviceType: widget.serviceType,
                                    carType: widget
                                        .washType, // This was originally passed as washType
                                    washType: washTypeKey,
                                    asset: widget.asset,
                                  ),
                                ),
                              );
                            } else {
                              print("⛔ Wash Type $washTypeKey is disabled!");
                            }
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
      ),
    );
  }
}
