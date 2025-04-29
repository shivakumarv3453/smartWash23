import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WashingCenterDropdown extends StatefulWidget {
  final List<String> centerNames;
  final Map<String, String> centerNameToLocation;
  final Map<String, String> centerNameToUid;
  final Map<String, double?>? centerNameToRating;
  final Map<String, int>? centerNameToRatingCount;
  final Function(String?) onCenterSelected;

  const WashingCenterDropdown({
    super.key,
    required this.centerNames,
    required this.centerNameToLocation,
    required this.centerNameToUid,
    this.centerNameToRating,
    this.centerNameToRatingCount,
    required this.onCenterSelected,
  });

  @override
  _WashingCenterDropdownState createState() => _WashingCenterDropdownState();
}

class _WashingCenterDropdownState extends State<WashingCenterDropdown> {
  String? _selectedCenter;

  Future<Map<String, dynamic>> _fetchRatingAndCount(String centerUid) async {
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
    return DropdownButtonFormField<String>(
      value: _selectedCenter,
      hint: const Text(
        "Choose Washing Center",
        style: TextStyle(color: Colors.grey),
      ),
      items: widget.centerNames.map((String center) {
        final location = widget.centerNameToLocation[center] ?? "";
        final centerUid = widget.centerNameToUid[center] ?? "";

        return DropdownMenuItem<String>(
          value: center,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _fetchRatingAndCount(centerUid),
            builder: (context, snapshot) {
              final ratingData = snapshot.data;
              final double? rating = ratingData?['averageRating'];
              final int count = ratingData?['count'] ?? 0;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '$center ($location)',
                      style: const TextStyle(fontSize: 16),
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
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedCenter = newValue;
        });
        widget.onCenterSelected(newValue);
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
