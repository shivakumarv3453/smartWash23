import 'dart:math';

import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

class PriceCalculator {
  static const Map<String, Map<String, Map<String, int>>> basePrices = {
    'Sedan': {
      'Standard': {'atCenter': 200, 'onSite': 250},
      'Premium': {'atCenter': 300, 'onSite': 350},
      'Ultra-Premium': {'atCenter': 400, 'onSite': 450},
    },
    'SUV': {
      'Standard': {'atCenter': 250, 'onSite': 300},
      'Premium': {'atCenter': 350, 'onSite': 400},
      'Ultra-Premium': {'atCenter': 450, 'onSite': 500},
    },
    'hatchback': {
      'Standard': {'atCenter': 150, 'onSite': 200},
      'Premium': {'atCenter': 250, 'onSite': 300},
      'Ultra-Premium': {'atCenter': 350, 'onSite': 400},
    },
  };

  static int calculateFinalPrice({
    required String carType,
    required String washType,
    required String serviceType,
    required double userLat,
    required double userLng,
    required double centerLat,
    required double centerLng,
  }) {
    final normalizedCarType = carType.trim();

    String normalizedWashType(String value) => value
        .toLowerCase()
        .replaceAll('-', '')
        .replaceAll(' wash', '')
        .replaceAll(' ', '')
        .trim();

    final normalizedServiceType = serviceType.toLowerCase() == 'at-center'
        ? 'atCenter'
        : serviceType.toLowerCase() == 'on-site'
            ? 'onSite'
            : serviceType;

    final carTypePrices = basePrices[normalizedCarType];
    if (carTypePrices == null) {
      debugPrint("No pricing found for car type: $normalizedCarType");
      return 0;
    }

    final inputNormalizedWash = normalizedWashType(washType);
    String? matchedWashTypeKey;

    for (var key in carTypePrices.keys) {
      if (normalizedWashType(key) == inputNormalizedWash) {
        matchedWashTypeKey = key;
        break;
      }
    }

    if (matchedWashTypeKey == null) {
      debugPrint("No matching wash type for: $washType");
      return 0;
    }

    final basePrice =
        carTypePrices[matchedWashTypeKey]?[normalizedServiceType] ?? 0;

    debugPrint(
        "Normalized keys: $normalizedCarType / $matchedWashTypeKey / $normalizedServiceType");
    debugPrint("Fetched base price: ₹$basePrice");

    final distance = _calculateDistance(userLat, userLng, centerLat, centerLng);
    final distanceCharge = (distance * 10).round(); // ₹10 per km
    final total = basePrice + distanceCharge;

    debugPrint("Distance: ${distance.toStringAsFixed(2)} km");
    debugPrint("Distance charge: ₹$distanceCharge");
    debugPrint("Final total: ₹$total");

    return total;
  }

  static double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371; // in km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _deg2rad(double deg) => deg * (pi / 180);
}
