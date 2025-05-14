import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_wash/user/app_bar.dart';
import 'package:smart_wash/user/screens/greet.dart';
// import 'package:smart_wash/main.dart';
import 'package:smart_wash/user/screens/rating.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_wash/services/firebase_service.dart';
import 'package:smart_wash/user/screens/washing_center.dart';

class Dash extends StatefulWidget {
  const Dash({super.key});

  @override
  State<Dash> createState() => _DashState();
}

class _DashState extends State<Dash> {
  String? _selectedCenter;
  String? selectedServiceType;
  String? selectedCarType;
  String? selectedWashType;
  DateTime? selectedDate;
  String? selectedTimeSlot;
  String? _selectedCenterUid;
  final List<String> _imagePaths = [
    'assets/images/main.jpeg',
    'assets/images/main4.jpg',
    'assets/images/main1.jpeg',
  ];

  int _currentImageIndex = 0;
  late Timer _timer;

  final List<Map<String, dynamic>> _ratings = []; // List to hold ratings

  // List of locations for the dropdown
  // final List<String> _locations = ["Banashankari", "JP Nagar", "Jayanagar"];
  // String? _selectedCenter; // Holds the selected location

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), _changeImage);
    fetchAdminSettings();
    _getLocationPermissionAndFetch();
    fetchCenters();
  }

  final FirebaseServices _firebaseServices = FirebaseServices();
  Map<String, dynamic>? adminSettings;
  String selectedServiceCenter = "center1";

  Future<void> fetchAdminSettings() async {
    var settings =
        await _firebaseServices.getAdminSettings(selectedServiceCenter);
    setState(() {
      adminSettings = settings;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _changeImage(Timer timer) {
    setState(() {
      _currentImageIndex = (_currentImageIndex + 1) % _imagePaths.length;
    });
  }
// Location

  Future<void> _getLocationPermissionAndFetch() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationError("Location services are disabled. Please enable them.");
      return;
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showLocationError("Location permission denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showLocationError(
          "Location permissions are permanently denied. Please enable them in settings.");
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _showLocationSnackBar(position);
    } catch (e) {
      _showLocationError("Error fetching location: $e");
    }
  }

  void _showLocationSnackBar(Position position) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            "Your location: Lat ${position.latitude}, Long ${position.longitude}"),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // Show an error Snackbar
  void _showLocationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // This function updates the ratings list
  void updateRating(int stars, String description) {
    setState(() {
      if (_ratings.isEmpty) {
        // Add new rating
        _ratings.add({'stars': stars, 'description': description});
      } else {
        // Edit the existing rating
        _ratings[0] = {'stars': stars, 'description': description};
      }
    });
  }

  List<String> availableServices = [];
  void fetchCenterAvailability(String centerId) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('partners')
        .doc(centerId)
        .get();

    if (doc.exists) {
      setState(() {
        bool onSiteEnabled = doc['onSiteEnabled'] ?? true;
        bool atCenterEnabled = doc['atCenterEnabled'] ?? true;

        availableServices = [];
        if (onSiteEnabled) availableServices.add("On-Site");
        if (atCenterEnabled) availableServices.add("At-Center");
      });
    }
  }

  bool isLoading = false;
  bool onSiteEnabled = true;
  bool atCenterEnabled = true;

// some code for service-type
  Future<void> fetchServiceTypesForCenter(String centerUid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('partners')
          .doc(centerUid)
          .get();
      if (!doc.exists) {
        print("❌ No such document for UID: $centerUid");
        return;
      }
      final data = doc.data();
      print("✅ Service Types Data: $data"); // ← That's all it does!
    } catch (e) {
      print("🔥 Error fetching service types: $e");
    }
  }

  Future<void> fetchServiceTypes(String centerUid) async {
    try {
      print("Fetching service types for center UID: $centerUid");

      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('partners')
          .doc(centerUid)
          .get();

      if (!snapshot.exists) {
        print("Document with UID $centerUid does not exist!");
        return;
      }

      var data = snapshot.data() as Map<String, dynamic>?;

      if (data == null) {
        print("Document exists but has no data!");
        return;
      }

      if (mounted) {
        setState(() {
          onSiteEnabled = data["onSiteEnabled"] ?? false; // Default to false
          atCenterEnabled = data["atCenterEnabled"] ?? false;
        });
      }

      print(
          "Updated Values - onSiteEnabled: $onSiteEnabled, atCenterEnabled: $atCenterEnabled");
    } catch (error) {
      print("Error fetching service types: $error");
    }
  }

  Future<String?> getUidByCenter(String centerName) async {
    try {
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('partners')
          .where('center', isEqualTo: centerName)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        print("No center found with name: $centerName");
        return null;
      }

      return query.docs.first.id; // Use document ID as UID
    } catch (e) {
      print("Error fetching UID for center $centerName: $e");
      return null;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "N/A";
    DateTime date = (timestamp as Timestamp).toDate();
    return "${date.day}/${date.month}/${date.year}";
  }

  Map<String, String> centerNameToUid = {};
  Map<String, String> centerNameToLocation = {};

  void fetchCenters() async {
    QuerySnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance.collection('partners').get();

    setState(() {
      centerNameToUid.clear();
      centerNameToLocation.clear();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final centerName = data['center'];
        final location = data['location'];

        if (centerName != null &&
            centerName is String &&
            centerName.trim().isNotEmpty &&
            location != null &&
            location is String &&
            location.trim().isNotEmpty) {
          centerNameToUid[centerName] = doc.id;
          centerNameToLocation[centerName] = location;
        } else {
          print(
              "Skipped partner ${doc.id} due to missing/invalid center or location");
        }
      }
    });

    print("Center Name to UID Mapping: $centerNameToUid");
    print("Center Name to Location Mapping: $centerNameToLocation");
  }

  final Map<String, double?> _centerUidToAvgRating = {};
  final Map<String, int> _centerUidToRatingCount = {};

  Future<void> loadCenterRatings() async {
    for (var center in centerNameToUid.entries) {
      String uid = center.value;
      final ratingsSnapshot = await FirebaseFirestore.instance
          .collection('bookingRatings')
          .where('centerUid', isEqualTo: uid)
          .get();

      final ratings = ratingsSnapshot.docs
          .map((doc) => doc['rating'] as num?)
          .where((r) => r != null)
          .cast<num>()
          .toList();

      if (ratings.isNotEmpty) {
        double avg = ratings.reduce((a, b) => a + b) / ratings.length;
        _centerUidToAvgRating[uid] = avg;
        _centerUidToRatingCount[uid] = ratings.length;
      } else {
        _centerUidToAvgRating[uid] = null;
        _centerUidToRatingCount[uid] = 0;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custAppBar(context, "       Smart Wash"),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(children: [
            // Dropdown for location selection
            SingleChildScrollView(
              child: Column(
                children: [
                  WashingCenterDropdown(
                    centerNames: centerNameToUid.keys.toList(),
                    centerNameToLocation: centerNameToLocation,
                    centerNameToUid:
                        centerNameToUid, // ✅ This is what was missing
                    centerNameToRating: {
                      for (var entry in centerNameToUid.entries)
                        entry.key: _centerUidToAvgRating[entry.value]
                    },
                    centerNameToRatingCount: {
                      for (var entry in centerNameToUid.entries)
                        entry.key: _centerUidToRatingCount[entry.value] ?? 0
                    },
                    onCenterSelected: (String? center) async {
                      print("Selected Center: $center");

                      setState(() {
                        _selectedCenter = center;
                        _selectedCenterUid = null;
                      });

                      if (center != null) {
                        String? centerUid = centerNameToUid[center];

                        if (centerUid != null) {
                          setState(() {
                            _selectedCenterUid = centerUid;
                          });

                          print("Center UID: $_selectedCenterUid");

                          if (_selectedCenterUid!.isNotEmpty) {
                            fetchServiceTypes(_selectedCenterUid!);
                          } else {
                            print(
                                "❌ UID is empty or null, skipping fetchServiceTypesForCenter");
                          }
                        } else {
                          print("❌ No UID found for center: $center");
                        }
                      }
                    },
                  ),

                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      _imagePaths[_currentImageIndex],
                      height: 300,
                      width: 550,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.error,
                          size: 50,
                          color: Colors.red,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      print("Selected Center: $_selectedCenter");

                      if (_selectedCenter == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Please select a washing center")),
                        );
                        return;
                      }

                      // Ensure we have the center UID
                      if (_selectedCenterUid == null) {
                        _selectedCenterUid =
                            await getUidByCenter(_selectedCenter!);
                        if (_selectedCenterUid == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "Error: Could not find center details")),
                          );
                          return;
                        }
                      } // ========== NEW CODE BLOCK END ========== //

                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return AlertDialog(
                                title: Center(
                                  child: const Text(
                                    "Choose Service Type",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      "Select the type of service you want.",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 20),
                                    GestureDetector(
                                      onTap: onSiteEnabled
                                          ? () {
                                              setState(() {
                                                selectedServiceType =
                                                    "On-site"; // Update the class variable
                                              });
                                              print(
                                                  "Selected Service Type: $selectedServiceType");
                                            }
                                          : null,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: onSiteEnabled
                                              ? (selectedServiceType ==
                                                      "On-site"
                                                  ? Colors.lightGreen[200]
                                                  : Colors.grey[200])
                                              : Colors.grey[300],
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "On-Site Wash",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: onSiteEnabled
                                                    ? Colors.black
                                                    : Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              "We will send our team to your location.",
                                              style: TextStyle(fontSize: 16),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    GestureDetector(
                                      onTap: atCenterEnabled
                                          ? () {
                                              setState(() {
                                                selectedServiceType =
                                                    "At-Center"; // Update the class variable
                                              });
                                              print(
                                                  "Selected Service Type: $selectedServiceType");
                                            }
                                          : null,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: atCenterEnabled
                                              ? (selectedServiceType ==
                                                      "At-Center"
                                                  ? Colors.lightGreen[200]
                                                  : Colors.grey[200])
                                              : Colors.grey[300],
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Pickup & Wash",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: atCenterEnabled
                                                    ? Colors.black
                                                    : Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              "We'll come to your location and collect your car.",
                                              style: TextStyle(fontSize: 16),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      "Cancel",
                                      style: TextStyle(
                                          color:
                                              Color.fromARGB(255, 255, 7, 7)),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (selectedServiceType == null) {
                                        // Check the class variable
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  "Please select a service type")),
                                        );
                                        return;
                                      }

                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Greet(
                                            selectedCenter: _selectedCenter!,
                                            centerUid: _selectedCenterUid!,
                                            serviceType:
                                                selectedServiceType!, // Pass the class variable
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "Continue",
                                      style: TextStyle(
                                        color: Colors.green,
                                      ),
                                    ),
                                  )
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      elevation: 5,
                      shadowColor: Colors.deepOrangeAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text("Book Now"),
                  ),

                  const SizedBox(height: 40), // Space before rating container

                  // Display all user ratings from Firestore
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('feedback')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var feedbackDocs = snapshot.data!.docs;
                      bool showViewMore = feedbackDocs.length > 3;

                      return Column(
                        children: [
                          const SizedBox(height: 10),

                          // Container for first 3 feedback items
                          Container(
                            height: 400, // Fixed height for initial view
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                children: feedbackDocs.take(3).map((doc) {
                                  var feedbackData =
                                      doc.data() as Map<String, dynamic>;
                                  return Container(
                                    margin: const EdgeInsets.all(8.0),
                                    padding: const EdgeInsets.all(12.0),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // User name and date
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              feedbackData['username'] ??
                                                  'Anonymous',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              _formatDate(
                                                  feedbackData['timestamp']),
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),

                                        // Star rating
                                        Row(
                                          children: List.generate(5, (index) {
                                            return Icon(
                                              index <
                                                      (feedbackData['rating'] ??
                                                          0)
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: Colors.amber,
                                              size: 24,
                                            );
                                          }),
                                        ),
                                        const SizedBox(height: 8),

                                        // Feedback comment
                                        Text(
                                          feedbackData['comment']?.isNotEmpty ==
                                                  true
                                              ? feedbackData['comment']
                                              : "No comment provided.",
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),

                          // "View More" button if there are more than 3 feedbacks
                          if (showViewMore)
                            TextButton(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (context) {
                                    return Container(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.8,
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          const Text(
                                            "All Customer Feedback",
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Expanded(
                                            child: ListView.builder(
                                              itemCount: feedbackDocs.length,
                                              itemBuilder: (context, index) {
                                                var feedbackData =
                                                    feedbackDocs[index].data()
                                                        as Map<String, dynamic>;
                                                return Container(
                                                  margin: const EdgeInsets.only(
                                                      bottom: 8),
                                                  padding:
                                                      const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[100],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            feedbackData[
                                                                    'username'] ??
                                                                'Anonymous',
                                                            style:
                                                                const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                          Text(
                                                            _formatDate(
                                                                feedbackData[
                                                                    'timestamp']),
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .grey[600],
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: List.generate(
                                                            5, (starIndex) {
                                                          return Icon(
                                                            starIndex <
                                                                    (feedbackData[
                                                                            'rating'] ??
                                                                        0)
                                                                ? Icons.star
                                                                : Icons
                                                                    .star_border,
                                                            color: Colors.amber,
                                                            size: 24,
                                                          );
                                                        }),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        feedbackData['comment']
                                                                    ?.isNotEmpty ==
                                                                true
                                                            ? feedbackData[
                                                                'comment']
                                                            : "No comment provided.",
                                                        style: const TextStyle(
                                                            fontSize: 14),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              child: const Text("View All Feedback"),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
      // Add Floating Action Button to Submit Feedback
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showRatingDialog(context);
        },
        child: const Icon(Icons.rate_review),
      ),
    );
  }
}
