import 'dart:convert';
import 'package:http/http.dart' as http;

class OverpassService {
  Future<List<Map<String, dynamic>>> fetchNearbyCarWashCenters({
    required double latitude,
    required double longitude,
    double radiusInMeters = 5000,
  }) async {
    print("🔍 Fetching car washes near ($latitude, $longitude) within ${radiusInMeters}m");
    
    // Build the Overpass query to find car washes within the radius
    final query = '''
      [out:json];
      (
        node["amenity"="car_wash"](around:$radiusInMeters,$latitude,$longitude);
        way["amenity"="car_wash"](around:$radiusInMeters,$latitude,$longitude);
      );
      out body;
      >;
      out skel qt;
    ''';

    final encodedQuery = Uri.encodeComponent(query);
    final url = Uri.parse('https://overpass-api.de/api/interpreter?data=$encodedQuery');
    
    print("🌐 Sending request to Overpass API...");

    try {
      final response = await http.get(url);
      print("📡 Response status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final elements = data['elements'] as List;
        print("✅ Found ${elements.length} car washes in response");

        final results = elements.map((e) {
          final name = e['tags']?['name'] ?? 'Unnamed Car Wash';
          final lat = e['lat'];
          final lon = e['lon'];
          print("🚗 Found car wash: $name at ($lat, $lon)");
          
          return {
            'id': e['id'].toString(),
            'name': name,
            'lat': lat,
            'lon': lon,
            'address': e['tags']?['addr:street'] ?? '',
            'phone': e['tags']?['phone'] ?? '',
            'website': e['tags']?['website'] ?? '',
          };
        }).toList();

        print("✨ Processed ${results.length} car washes successfully");
        return results;
      } else {
        print("❌ API request failed with status: ${response.statusCode}");
        print("❌ Response body: ${response.body}");
        throw Exception('Overpass API failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching car wash centers: $e');
      return []; // Return empty list instead of throwing to handle errors gracefully
    }
  }
}
