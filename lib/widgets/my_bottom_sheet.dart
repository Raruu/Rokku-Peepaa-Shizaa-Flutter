import 'package:flutter/material.dart';

class MyBottomSheet extends StatelessWidget {
  const MyBottomSheet({
    super.key,
    required this.context,
    required this.child,
    required this.dragSensitivity,
    required this.title,
    this.minSheetSize = 0.25,
    this.maxSheetSize = 0.9,
  });

  final BuildContext context;
  final Widget child;
  final double dragSensitivity;
  final double minSheetSize;
  final double maxSheetSize;
  final String title;

  @override
  Widget build(BuildContext context) {
    double animateLineWidth = 30;
    Color animateLineColor = Colors.grey;
    double sheetSize = 0.3;

    return StatefulBuilder(
      builder: (context, setState) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: sheetSize,
          minChildSize: minSheetSize,
          maxChildSize: maxSheetSize,
          builder: (context, scrollController) {
            return GestureDetector(
              onPanUpdate: (details) {},
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Container(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: GestureDetector(
                            onVerticalDragUpdate: (details) => setState(() {
                              animateLineWidth = 100;
                              animateLineColor = Colors.black;
                              sheetSize -= details.delta.dy / dragSensitivity;
                              if (sheetSize > maxSheetSize) {
                                sheetSize = maxSheetSize;
                              }
                              if (sheetSize < minSheetSize) {
                                sheetSize = minSheetSize;
                                Navigator.of(context).pop();
                              }
                            }),
                            onVerticalDragEnd: (details) => setState(() {
                              animateLineWidth = 30;
                              animateLineColor = Colors.grey;
                            }),
                            child: Container(
                              width: double.infinity,
                              color: Colors.white,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 125),
                                    width: animateLineWidth,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      color: animateLineColor,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(top: 26),
                                  ),
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        child
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

Future<dynamic> showMyBottomSheet(
    {required BuildContext context,
    required double dragSensitivity,
    required String title,
    required Widget child}) {
  return showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) => MyBottomSheet(
            context: context,
            dragSensitivity: dragSensitivity,
            title: title,
            child: child,
          ));
}
