import 'package:flutter/material.dart';

class BBox extends StatelessWidget {
  final double x;
  final double y;
  final double width;
  final double height;
  final String label;

  const BBox({
    super.key,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      child: Container(
        width: 200,
        height: 200,
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
