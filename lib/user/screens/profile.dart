import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_wash/user/app_bar.dart';
import 'package:geocoding/geocoding.dart';
// import 'package:smart_wash/utils/location_utils.dart';
import 'package:android_intent_plus/android_intent.dart';
// import 'package:android_intent_plus/intent.dart';
import 'dart:io' show Platform;

void openLocationSettings() {
  if (Platform.isAndroid) {
    final intent = AndroidIntent(
      action: 'android.settings.LOCATION_SOURCE_SETTINGS',
    );
    intent.launch();
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();

  final User? user = FirebaseAuth.instance.currentUser;

  bool isLoading = true;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _fetchProfileData();
    }
  }

  Future<void> _fetchProfileData() async {
    if (user == null) return;

    try {
      DocumentSnapshot profileDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (profileDoc.exists) {
        Map<String, dynamic> profileData =
            profileDoc.data() as Map<String, dynamic>;

        // safely check and access each field
        String username = profileData.containsKey('username')
            ? profileData['username'] ?? user?.displayName ?? ''
            : user?.displayName ?? '';

        String mobile = profileData.containsKey('mobile')
            ? profileData['mobile'] ?? ''
            : '';

        String location = profileData.containsKey('location')
            ? profileData['location'] ?? ''
            : '';

        setState(() {
          usernameController.text = username;
          mobileController.text = mobile;
          locationController.text = location;
          isLoading = false;
        });
      } else {
        // Create the missing profile with default values
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .set({
          'username': user?.displayName ?? 'User Name',
          'mobile': '',
          'location': '',
        });
        await _fetchProfileData(); // fetch again after setting defaults
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error fetching profile data: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (user == null) {
      print("User is null");
      return;
    }

    final mobile = mobileController.text.trim();
    final username = usernameController.text.trim();
    final locationInput = locationController.text.trim();

    if (mobile.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mobile number must be 10 digits"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (locationInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a location"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Predefined list of popular Bangalore locations
    final Map<String, String> popularLocations = {
      "BTM": "BTM Layout, Bangalore",
      "BTM Layout": "BTM Layout, Bangalore",
      "Indiranagar": "Indiranagar, Bangalore",
      "Koramangala": "Koramangala, Bangalore",
      "Whitefield": "Whitefield, Bangalore",
      "HSR": "HSR Layout, Bangalore",
      "HSR Layout": "HSR Layout, Bangalore",
    };

    String? finalLocation;
    double? lat;
    double? long;

    if (popularLocations.containsKey(locationInput)) {
      finalLocation = popularLocations[locationInput];
      print("Using popular location: $finalLocation");

      try {
        List<Location> geoResults = await locationFromAddress(finalLocation!);
        if (geoResults.isNotEmpty) {
          lat = geoResults.first.latitude;
          long = geoResults.first.longitude;
        } else {
          throw Exception("No coordinates found for popular location");
        }
      } catch (e) {
        print("Geocoding failed for popular location: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to get coordinates from popular location."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      print("Popular location not matched, trying geocoding first...");

      try {
        List<Location> geoResults = await locationFromAddress(locationInput);
        if (geoResults.isNotEmpty) {
          lat = geoResults.first.latitude;
          long = geoResults.first.longitude;
          finalLocation = locationInput; // ✅ Set this
          locationController.text = "$lat, $long";
          print("Successfully got location via geocoding: $lat, $long");
        } else {
          throw Exception("No geocoding results found");
        }
      } catch (e) {
        print("Geocoding failed: $e. Trying device location...");

        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          bool enableService = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Enable Location"),
                  content: const Text(
                      "We need your current location. Please enable location services."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Enable"),
                    ),
                  ],
                ),
              ) ??
              false;

          if (!enableService) return;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            print("Location permissions are denied");
            return;
          }
        }

        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          lat = position.latitude;
          long = position.longitude;
          finalLocation = "Current Device Location"; // ✅ Set this
          locationController.text = "$lat, $long";
          print("Using device location: $lat, $long");
        } catch (e) {
          print("Error using device location: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Unable to get device location."),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    // ✅ Defensive check before Firestore update
    if (lat == null) {
      print("Some value is still null: $finalLocation | $lat | $long");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: Location or coordinates are missing"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ Firestore update
    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'username': username,
        'mobile': mobile,
        'location': finalLocation,
        'latitude': lat,
        'longitude': long,
      }, SetOptions(merge: true));

      setState(() {
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully"),
          backgroundColor: Colors.green,
        ),
      );

      await _fetchProfileData();
    } catch (e) {
      print("Firestore update error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving to database: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> handleLocationSave(
      BuildContext context, TextEditingController locationController) async {
    String locationInput = locationController.text.trim(); // Get user input
    String? finalLocation = locationInput.isNotEmpty ? locationInput : null;
    double? lat;
    double? lon;

    try {
      // First, try to geocode the entered location
      if (finalLocation != null && finalLocation.isNotEmpty) {
        List<Location> geoResults = await locationFromAddress(finalLocation);
        if (geoResults.isNotEmpty) {
          lat = geoResults.first.latitude;
          lon = geoResults.first.longitude;
          print("Geocoding success: $lat, $lon");
        } else {
          throw Exception("No coordinates found for the entered location");
        }
      }
    } catch (e) {
      print("Geocoding failed: $e. Asking to use device location...");

      if (kIsWeb) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Smart Wash Needs Your Location"),
            content: const Text(
              "Please allow location access in your browser. "
              "Click the lock icon in the address bar and enable location permission.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } else {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          bool enableService = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Smart Wash Needs Your Location"),
                  content: const Text(
                    "We need your location to show nearby washing centers. "
                    "Please allow location access in your device settings.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await openAppSettings();
                        openLocationSettings();
                      },
                      child: const Text("Go to Settings"),
                    ),
                  ],
                ),
              ) ??
              false;

          if (!enableService) return;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            print('Location permissions are denied');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Location permission is required to proceed."),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }

        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        lat = position.latitude;
        lon = position.longitude;
        print("Using device location: $lat, $lon");

        locationController.text = "$lat, $lon"; // Update location field
      }
    }
  }

// A helper method to open app settings if permission is denied
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<void> getDeviceLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return;
        }
      }

      Position? position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      double lat = position.latitude;
      double lon = position.longitude;
      locationController.text = "$lat, $lon";
      print("Using device location: $lat, $lon");
    } catch (e) {
      print("Error using device location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: custAppBar(context, "Profile"),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          usernameController.text.isNotEmpty
                              ? usernameController.text
                              : "User Name",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          user?.email ?? "user@example.com",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Text(
              "Personal Information",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const Divider(height: 20),
            const SizedBox(height: 10),
            _buildFormField(
              controller: usernameController,
              label: "Username",
              icon: Icons.person,
              enabled: isEditing,
            ),
            const SizedBox(height: 15),
            _buildFormField(
              controller: TextEditingController(text: user?.email ?? ""),
              label: "Email",
              icon: Icons.email,
              enabled: false,
            ),
            const SizedBox(height: 15),
            _buildFormField(
              controller: mobileController,
              label: "Mobile",
              icon: Icons.phone,
              enabled: isEditing,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                LengthLimitingTextInputFormatter(10),
                FilteringTextInputFormatter.digitsOnly
              ],
            ),
            const SizedBox(height: 15),
            _buildFormField(
              controller: locationController,
              label: "Location",
              icon: Icons.location_on,
              enabled: isEditing,
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                const SizedBox(width: 10),
                if (!isEditing)
                  Expanded(
                    child: ElevatedButton.icon(
                      // icon: const Icon(Icons.edit, size: 20),
                      label: const Text(
                        "EDIT",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          isEditing = true;
                        });
                      },
                    ),
                  ),
                if (isEditing)
                  Expanded(
                    child: ElevatedButton.icon(
                      // icon: const Icon(Icons.save, size: 20),
                      label: const Text(
                        "SAVE",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        print("SAVE button tapped");
                        FocusScope.of(context)
                            .unfocus(); // Close the keyboard if it's open

                        // Call handleLocationSave with the correct parameters
                        await handleLocationSave(context, locationController);

                        // Proceed with updating the profile
                        await _updateProfile(); // Make sure _updateProfile is async if necessary

                        print("Location save and updateProfile done");
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}
