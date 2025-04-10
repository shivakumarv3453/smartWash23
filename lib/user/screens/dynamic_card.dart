import 'package:flutter/material.dart';

class DynamicCard extends StatefulWidget {
  final String imagePath;
  final String description;
  final String price;
  final String briefDescription;
  final VoidCallback onTap;

  const DynamicCard({
    super.key,
    required this.imagePath,
    required this.description,
    required this.price,
    required this.briefDescription,
    required this.onTap,
  });

  @override
  // ignore: library_private_types_in_public_api
  _DynamicCardState createState() => _DynamicCardState();
}

class _DynamicCardState extends State<DynamicCard> {
  bool _isDropdownOpen = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        color: Colors.blue,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              child: widget.imagePath.isNotEmpty
                  ? Image.asset(
                      // widget.imagePath,
                      // width: 300,
                      // height: 200,
                      // fit: BoxFit.fill,
                      widget.imagePath,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.fill,
                    )
                  : const Placeholder(fallbackHeight: 300, fallbackWidth: 300),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.description.isNotEmpty
                          ? widget.description
                          : 'No Description',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          backgroundColor: Colors.blue),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Text(
                    widget.price,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                _isDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                size: 24,
              ),
              onPressed: () {
                setState(() {
                  _isDropdownOpen = !_isDropdownOpen;
                });
              },
            ),
            if (_isDropdownOpen)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  widget.briefDescription,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w400),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
