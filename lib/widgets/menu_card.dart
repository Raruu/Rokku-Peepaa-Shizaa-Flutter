import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';

class MenuCard extends StatelessWidget {
  const MenuCard({
    super.key,
    this.onTap,
    required this.svgIcon,
    this.iconSize = 24,
    required this.title,
  });

  final void Function()? onTap;
  final String svgIcon;
  final double iconSize;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        splashColor: const Color.fromARGB(255, 184, 165, 215),
        onTap: onTap,
        child: SizedBox(
          width: 160,
          height: 90,
          child: Padding(
            padding: const EdgeInsets.all(19.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Iconify(
                  svgIcon,
                  size: iconSize,
                ),
                const Spacer(),
                Text(
                  title,
                  style:
                      const TextStyle(height: 0, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
