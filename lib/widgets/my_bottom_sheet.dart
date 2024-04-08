import 'package:flutter/material.dart';

class MyBottomSheet extends StatefulWidget {
  const MyBottomSheet({
    super.key,
    required this.child,
    required this.dragSensitivity,
    required this.title,
    this.minSheetSize = 0.25,
    this.maxSheetSize = 0.9,
  });

  final Widget child;
  final double dragSensitivity;
  final double minSheetSize;
  final double maxSheetSize;
  final String title;

  @override
  State<MyBottomSheet> createState() => _MyBottomSheetState();
}

class _MyBottomSheetState extends State<MyBottomSheet> {
  double sheetSize = 0.3;
  @override
  Widget build(BuildContext context) {
    double animateLineWidth = 30;
    Color animateLineColor = Colors.grey;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: StatefulBuilder(
        builder: (context, setState) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: sheetSize,
            minChildSize: widget.minSheetSize,
            maxChildSize: widget.maxSheetSize,
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
                                sheetSize -=
                                    details.delta.dy / widget.dragSensitivity;
                                if (sheetSize > widget.maxSheetSize) {
                                  sheetSize = widget.maxSheetSize;
                                }
                                if (sheetSize < widget.minSheetSize) {
                                  sheetSize = widget.minSheetSize;
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
                                      duration:
                                          const Duration(milliseconds: 125),
                                      width: animateLineWidth,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        color: animateLineColor,
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(top: 26),
                                    ),
                                    Text(
                                      widget.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          widget.child
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Future<dynamic> showMyBottomSheet({
  required BuildContext context,
  required double dragSensitivity,
  required String title,
  required Widget child,
  double minSheetSize = 0.25,
  double maxSheetSize = 0.9,
  Color? backgroundColor,
  String? barrierLabel,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  Color? barrierColor,
  bool isScrollControlled = true,
  double scrollControlDisabledMaxHeightRatio = 9.0 / 16.0,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useSafeArea = false,
  RouteSettings? routeSettings,
  AnimationController? transitionAnimationController,
  Offset? anchorPoint,
}) {
  return showModalBottomSheet(
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor,
      barrierLabel: barrierLabel,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      constraints: constraints,
      barrierColor: barrierColor,
      scrollControlDisabledMaxHeightRatio: scrollControlDisabledMaxHeightRatio,
      useRootNavigator: useRootNavigator,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      useSafeArea: useSafeArea,
      routeSettings: routeSettings,
      transitionAnimationController: transitionAnimationController,
      anchorPoint: anchorPoint,
      context: context,
      builder: (context) => MyBottomSheet(
            dragSensitivity: dragSensitivity,
            title: title,
            minSheetSize: minSheetSize,
            maxSheetSize: maxSheetSize,
            child: child,
          ));
}
