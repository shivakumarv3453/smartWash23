import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_wash/utils/location_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class WashingCenterDropdown extends StatefulWidget {
  final List<String> centerNames;
  final Map<String, String> centerNameToLocation;
  final Map<String, String> centerNameToUid;
  final Map<String, double?>? centerNameToRating;
  final Map<String, int>? centerNameToRatingCount;
  final Function(String?) onCenterSelected;
  final bool isLoading;
  final Position? currentPosition; // Add current position

  const WashingCenterDropdown({
    super.key,
    required this.centerNames,
    required this.centerNameToLocation,
    required this.centerNameToUid,
    this.centerNameToRating,
    this.centerNameToRatingCount,
    required this.onCenterSelected,
    this.isLoading = false,
    this.currentPosition,
  });

  @override
  _WashingCenterDropdownState createState() => _WashingCenterDropdownState();
}

class _WashingCenterDropdownState extends State<WashingCenterDropdown> {
  String? _selectedCenter;
  final Map<String, double?> _locationDistances = {};
  final Map<String, String> _resolvedAddresses = {};

  String _formatDistance(double? distanceInMeters) {
    if (distanceInMeters == null) return '>5km';
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }

  Future<double?> _calculateDistance(String location) async {
    if (widget.currentPosition == null) return null;
    if (_locationDistances.containsKey(location)) {
      return _locationDistances[location];
    }

    try {
      // First, try to get coordinates from the location name
      LatLng? coordinates = await getCoordinatesFromAddress(location);
      
      if (coordinates != null) {
        final distance = Geolocator.distanceBetween(
          widget.currentPosition!.latitude,
          widget.currentPosition!.longitude,
          coordinates.latitude,
          coordinates.longitude
        );
        _locationDistances[location] = distance;
        return distance;
      }

      // If location contains coordinates, use them as fallback
      if (location.contains(',')) {
        final parts = location.split(',');
        if (parts.length >= 2) {
          final latStr = parts[0].replaceAll(RegExp(r'[^0-9.-]'), '');
          final lonStr = parts[1].replaceAll(RegExp(r'[^0-9.-]'), '');
          
          if (latStr.isNotEmpty && lonStr.isNotEmpty) {
            final lat = double.parse(latStr);
            final lon = double.parse(lonStr);
            
            final distance = Geolocator.distanceBetween(
              widget.currentPosition!.latitude,
              widget.currentPosition!.longitude,
              lat,
              lon
            );
            _locationDistances[location] = distance;
            return distance;
          }
        }
      }
    } catch (e) {
      print('Error calculating distance: $e');
    }
    _locationDistances[location] = null;
    return null;
  }

  Future<String?> _getLocationName(String location) async {
    if (_resolvedAddresses.containsKey(location)) {
      return _resolvedAddresses[location];
    }

    try {
      if (location.contains(',')) {
        final parts = location.split(',');
        if (parts.length >= 2) {
          final latStr = parts[0].replaceAll(RegExp(r'[^0-9.-]'), '');
          final lonStr = parts[1].replaceAll(RegExp(r'[^0-9.-]'), '');
          
          if (latStr.isNotEmpty && lonStr.isNotEmpty) {
            final lat = double.parse(latStr);
            final lon = double.parse(lonStr);
            
            final address = await getAddressFromCoordinates(lat, lon);
            if (address != null) {
              _resolvedAddresses[location] = address;
              return address;
            }
          }
        }
      }
    } catch (e) {
      print('Error resolving location name: $e');
    }
    return null;
  }

  Future<String> _formatLocation(String center, String location) async {
    // For registered centers, use the location as is
    if (!widget.centerNameToUid[center]!.startsWith('overpass_')) {
      final distance = await _calculateDistance(location);
      final distanceStr = _formatDistance(distance);
      return location.isEmpty ? distanceStr : '$location • $distanceStr';
    }
    
    // For unregistered centers, try to get a proper address
    String? resolvedLocation = await _getLocationName(location);
    final distance = await _calculateDistance(location);
    final distanceStr = _formatDistance(distance);
    
    if (resolvedLocation != null) {
      // If we have phone information, preserve it
      if (location.contains('Phone:')) {
        final parts = location.split('Phone:');
        final phone = 'Phone: ${parts[1].trim()}';
        return '$resolvedLocation • $distanceStr\n$phone';
      }
      return '$resolvedLocation • $distanceStr';
    }
    
    // If we couldn't resolve the location, just show the distance
    return distanceStr;
  }

  void _showUnregisteredCenterDialog(String centerName, String location, String phone) async {
    String? resolvedLocation = await _getLocationName(location);
    final distance = await _calculateDistance(location);
    final distanceStr = _formatDistance(distance);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            centerName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "⚠️ Unregistered Center",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (resolvedLocation != null)
                          Text(
                            resolvedLocation,
                            style: const TextStyle(fontSize: 14),
                          ),
                        Text(
                          distanceStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "This center has not partnered with us yet.",
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              if (phone.isNotEmpty) ...[
                const Text(
                  "If you want service from this center, please contact:",
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.phone, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else
                const Text(
                  "Contact information is not available for this center.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const SizedBox(height: 16),
              // Add Google Maps link
              if (location.contains(',')) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    final parts = location.split(',');
                    if (parts.length >= 2) {
                      final latStr = parts[0].replaceAll(RegExp(r'[^0-9.-]'), '');
                      final lonStr = parts[1].replaceAll(RegExp(r'[^0-9.-]'), '');
                      if (latStr.isNotEmpty && lonStr.isNotEmpty) {
                        final lat = double.parse(latStr);
                        final lon = double.parse(lonStr);
                        final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
                        launchUrl(Uri.parse(url));
                      }
                    }
                  },
                  icon: const Icon(Icons.map, color: Colors.white),
                  label: const Text(
                    'Open in Google Maps',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _selectedCenter = null;
                });
              },
              child: const Text(
                "Close",
                style: TextStyle(color: Colors.deepOrange),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchRatingAndCount(String centerUid) async {
    // Skip rating fetch for Overpass centers
    if (centerUid.startsWith('overpass_')) {
      return {'averageRating': null, 'count': 0};
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('bookingRatings')
          .where('centerUid', isEqualTo: centerUid)
          .get();
      if (querySnapshot.docs.isEmpty) {
        return {'averageRating': null, 'count': 0};
      }

      double total = 0;
      int count = 0;
      for (var doc in querySnapshot.docs) {
        total += (doc['rating'] ?? 0).toDouble();
        count++;
      }
      double average = total / count;
      return {'averageRating': average, 'count': count};
    } catch (e) {
      print('Error fetching ratings: $e');
      return {'averageRating': null, 'count': 0};
    }
  }

  Color _getRatingColor(double rating) {
    if (rating > 4) return Colors.green;
    if (rating > 3) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        height: 48, // Match default dropdown height
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.deepOrangeAccent, width: 2),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
            strokeWidth: 2.0, // Thinner stroke
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedCenter,
      hint: const Text(
        "Choose Washing Center",
        style: TextStyle(color: Colors.grey),
      ),
      selectedItemBuilder: (BuildContext context) {
        // This controls what's shown in the button when an item is selected
        return widget.centerNames.map<Widget>((String center) {
          final centerUid = widget.centerNameToUid[center] ?? "";
          
          return FutureBuilder<Map<String, dynamic>>(
            future: _fetchRatingAndCount(centerUid),
            builder: (context, snapshot) {
              final ratingData = snapshot.data;
              final double? rating = ratingData?['averageRating'];
              final int count = ratingData?['count'] ?? 0;

              return Row(
                children: [
                  Expanded(
                    child: Text(
                      center,
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (rating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRatingColor(rating),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '${rating.toStringAsFixed(1)} ($count)',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          );
        }).toList();
      },
      items: widget.centerNames.map((String center) {
        final location = widget.centerNameToLocation[center] ?? "";
        final centerUid = widget.centerNameToUid[center] ?? "";

        return DropdownMenuItem<String>(
          value: center,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _fetchRatingAndCount(centerUid),
            builder: (context, snapshot) {
              return FutureBuilder<String>(
                future: _formatLocation(center, location),
                builder: (context, locationSnapshot) {
                  final formattedLocation = locationSnapshot.data ?? 'Loading...';
                  final ratingData = snapshot.data;
                  final double? rating = ratingData?['averageRating'];
                  final int count = ratingData?['count'] ?? 0;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              formattedLocation,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              centerUid.startsWith('overpass_') ? '(Unregistered Center)' : '(Registered Center)',
                              style: TextStyle(
                                fontSize: 10,
                                color: centerUid.startsWith('overpass_') ? Colors.orange : Colors.green,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (snapshot.connectionState == ConnectionState.done &&
                          rating != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getRatingColor(rating),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                '${rating.toStringAsFixed(1)} ($count)',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      else if (snapshot.connectionState == ConnectionState.waiting)
                        const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        )
                      else
                        const Text(
                          "No ratings",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        );
      }).toList(),
      onChanged: (String? newValue) async {
        if (newValue != null) {
          final centerUid = widget.centerNameToUid[newValue] ?? "";
          
          if (centerUid.startsWith('overpass_')) {
            final location = widget.centerNameToLocation[newValue] ?? "";
            String phone = "";
            
            if (location.contains('Phone:')) {
              final parts = location.split('Phone:');
              if (parts.length > 1) {
                phone = parts[1].split('•')[0].trim();
              }
            }

            _showUnregisteredCenterDialog(newValue, location, phone);
          } else {
            setState(() {
              _selectedCenter = newValue;
            });
            widget.onCenterSelected(newValue);
          }
        }
      },
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: Colors.grey[100],
        enabledBorder: OutlineInputBorder(
          borderSide:
              const BorderSide(color: Colors.deepOrangeAccent, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      dropdownColor: Colors.white,
      icon:
          const Icon(Icons.arrow_drop_down, color: Colors.deepOrange, size: 30),
      isExpanded: true,
      isDense: true,
      menuMaxHeight: 300,
    );
  }
}
