// lib/utils/price_calculator.dart
import 'dart:math';

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371; // Radius of the Earth in kilometers
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) *
          cos(lat2 * pi / 180) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c; // Distance in kilometers
}

double calculatePrice(
  String carType,
  String washType,
  String serviceType,
  double userLat,
  double userLon,
  double centerLat,
  double centerLon,
) {
  const double BASE_PRICE = 10.0;

  const Map<String, double> CAR_TYPE_MULTIPLIERS = {
    'SUV': 1.2,
    'Sedan': 1.1,
  };

  const Map<String, double> WASH_TYPE_MULTIPLIERS = {
    'Standard': 1.0,
    'Premium': 1.5,
    'Ultra-Premium': 2.0,
  };

  const Map<String, double> SERVICE_TYPE_FEES = {
    'At-Center': 5.0,
    'On-Site': 10.0,
  };

  double distance = calculateDistance(userLat, userLon, centerLat, centerLon);

  double price = BASE_PRICE;
  price *= CAR_TYPE_MULTIPLIERS[carType] ?? 1.0;
  price *= WASH_TYPE_MULTIPLIERS[washType] ?? 1.0;
  price += SERVICE_TYPE_FEES[serviceType] ?? 0.0;

  // Distance fee (per km)
  price += distance * 1.0;

  return price;
}
