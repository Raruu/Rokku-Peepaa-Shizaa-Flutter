import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BBox extends StatelessWidget {
  final double left;
  final double top;

  final double width;
  final double height;
  final String label;

  const BBox({
    super.key,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print("left: $left");
      print("top: $top");
      print("width: $width");
      print("height: $height");
    }
    // I think this wrong but sometimes work
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green, width: 3),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: FittedBox(
            child: Text(
              label,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}
