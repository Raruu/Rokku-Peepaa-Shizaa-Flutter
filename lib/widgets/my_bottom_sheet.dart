import 'package:flutter/material.dart';

class MyBottomSheet extends StatefulWidget {
  const MyBottomSheet({
    super.key,
    required this.children,
    required this.dragSensitivity,
    required this.navigatorPop,
    this.title = '',
    this.minSheetSize = 0.25,
    this.maxSheetSize = 0.9,
    this.initialSheetSize,
    this.titleCustomWidget,
    this.contentScrollPhysics = const NeverScrollableScrollPhysics(),
    this.onHide,
    this.showDragHandle = true,
    this.dontUseList = false,
    this.initialMoveAble = true,
  }) : initAnimation = false;

  const MyBottomSheet.initAnimation({
    super.key,
    required this.children,
    required this.dragSensitivity,
    required this.navigatorPop,
    this.title = '',
    this.minSheetSize = 0.25,
    this.maxSheetSize = 0.9,
    this.initialSheetSize,
    this.titleCustomWidget,
    this.contentScrollPhysics = const NeverScrollableScrollPhysics(),
    this.onHide,
    this.showDragHandle = true,
    this.dontUseList = false,
    this.initialMoveAble = true,
  }) : initAnimation = true;

  final List<Widget> children;
  final double dragSensitivity;
  final double minSheetSize;
  final double maxSheetSize;
  final double? initialSheetSize;
  final String title;
  final Widget? titleCustomWidget;
  final ScrollPhysics contentScrollPhysics;
  final bool navigatorPop;
  final void Function()? onHide;
  final bool initAnimation;
  final bool showDragHandle;
  final bool dontUseList;
  final bool initialMoveAble;

  @override
  State<MyBottomSheet> createState() => MyBottomSheetState();
}

class MyBottomSheetState extends State<MyBottomSheet>
    with SingleTickerProviderStateMixin {
  Animation<double>? _setSheetSizeAnimation;
  late double _sheetSize;

  void setSheetSize(double value) {
    if (value <= widget.minSheetSize) {
      widget.onHide?.call();
    }
    if (widget.initAnimation) {
      _setSheetSizeAnimation = Tween<double>(begin: _sheetSize, end: value)
          .animate(animationController!);
      animationController!.forward(from: 0);
      return;
    }
    _sheetSize = value;
  }

  AnimationController? animationController;

  late bool _moveAble;
  bool get isMoveAble => _moveAble;
  void setMoveAble(bool value) => setState(() {
        _moveAble = value;
      });

  @override
  void initState() {
    _moveAble = widget.initialMoveAble;
    if (widget.initialSheetSize != null) {
      _sheetSize = widget.initialSheetSize!;
    } else {
      _sheetSize = (widget.maxSheetSize + widget.minSheetSize) / 2;
    }

    super.initState();
    if (widget.initAnimation) {
      animationController = AnimationController(
        vsync: this,
        duration: const Duration(
          milliseconds: 159,
        ),
      );

      animationController!.addListener(() {
        setState(() {
          _sheetSize = _setSheetSizeAnimation!.value;
        });
      });
    }
  }

  @override
  void dispose() {
    if (widget.initAnimation) {
      animationController!.dispose();
    }
    super.dispose();
  }

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
            initialChildSize: _sheetSize,
            minChildSize: 0.0,
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
                              onVerticalDragUpdate: _moveAble
                                  ? (details) => setState(() {
                                        animateLineWidth = 100;
                                        animateLineColor = Colors.black;
                                        _sheetSize -= details.delta.dy /
                                            widget.dragSensitivity;
                                        if (_sheetSize > widget.maxSheetSize) {
                                          _sheetSize = widget.maxSheetSize;
                                        }
                                        if (_sheetSize < widget.minSheetSize) {
                                          _sheetSize = widget.minSheetSize;
                                          if (widget.navigatorPop) {
                                            Navigator.of(context).pop();
                                          } else {
                                            _sheetSize = 0.0;
                                          }
                                          widget.onHide?.call();
                                        }
                                      })
                                  : null,
                              onVerticalDragEnd: (details) => setState(() {
                                animateLineWidth = 30;
                                animateLineColor = Colors.grey;
                              }),
                              child: Container(
                                width: double.infinity,
                                color: Colors.white,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Visibility(
                                      visible: widget.showDragHandle,
                                      child: Center(
                                        child: AnimatedContainer(
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
                                      ),
                                    ),
                                    Padding(
                                      padding: widget.showDragHandle
                                          ? const EdgeInsets.only(top: 26)
                                          : const EdgeInsets.all(0),
                                    ),
                                    (widget.titleCustomWidget == null)
                                        ? Center(
                                            child: Text(
                                              widget.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                        : widget.titleCustomWidget!,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: widget.dontUseList
                                ? widget.children[0]
                                : ListView(
                                    padding: const EdgeInsets.all(0),
                                    physics: widget.contentScrollPhysics,
                                    children: widget.children,
                                  ),
                          )
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
  required List<Widget> children,
  double minSheetSize = 0.25,
  double maxSheetSize = 0.9,
  double? initialSheetSize,
  bool navigatorPop = true,
  ScrollPhysics contentScrollPhysics = const NeverScrollableScrollPhysics(),
  bool showDragHandle = true,
  Widget? titleCustomWidget,
  bool dontUseList = false,
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
}) async {
  return await showModalBottomSheet(
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
            initialSheetSize: initialSheetSize,
            navigatorPop: navigatorPop,
            contentScrollPhysics: contentScrollPhysics,
            showDragHandle: showDragHandle,
            titleCustomWidget: titleCustomWidget,
            dontUseList: dontUseList,
            children: children,
          ));
}
