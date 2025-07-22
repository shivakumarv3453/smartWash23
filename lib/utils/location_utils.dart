import 'package:flutter/material.dart';
// import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

Future<LatLng?> getCoordinatesFromAddress(String address) async {
  if (address.isEmpty) return null;

  String cleanAddress = address
      .replaceAll('JP Nagara', 'JP Nagar') // Fix common misspelling
      .trim();

  if (!cleanAddress.toLowerCase().contains('bangalore')) {
    cleanAddress += ', Bangalore, India';
  }

  debugPrint("Geocoding partner address: $cleanAddress");

  try {
    final response = await http.get(Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$cleanAddress&format=json'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.isNotEmpty) {
        final lat = data[0]['lat'];
        final lon = data[0]['lon'];
        debugPrint("Fetched coordinates: lat=$lat, lon=$lon");
        return LatLng(double.parse(lat), double.parse(lon));
      }
    } else {
      debugPrint("Geocoding failed with status ${response.statusCode}");
    }
  } catch (e) {
    debugPrint("Error fetching coordinates: $e");
  }

  return null;
}

Future<String?> getAddressFromCoordinates(double lat, double lon) async {
  try {
    final response = await http.get(Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['address'] != null) {
        // Try to construct a meaningful address
        final address = data['address'];
        List<String> addressParts = [];

        // Add suburb or neighborhood if available
        if (address['suburb'] != null) {
          addressParts.add(address['suburb']);
        } else if (address['neighbourhood'] != null) {
          addressParts.add(address['neighbourhood']);
        }

        // Add area
        if (address['residential'] != null) {
          addressParts.add(address['residential']);
        }

        // If we don't have any parts yet, use the display name
        if (addressParts.isEmpty && data['display_name'] != null) {
          // Take only the first part of the display name (usually the most relevant)
          String displayName = data['display_name'].toString().split(',')[0];
          addressParts.add(displayName);
        }

        if (addressParts.isNotEmpty) {
          return addressParts.join(', ');
        }
      }
    }
  } catch (e) {
    debugPrint("Error reverse geocoding: $e");
  }
  return null;
}
