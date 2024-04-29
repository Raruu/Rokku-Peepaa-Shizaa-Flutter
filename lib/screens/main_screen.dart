import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:flutter_rps/screens/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconify_flutter/iconify_flutter.dart';

import 'package:flutter_rps/widgets/svg_icons.dart' as svg_icons;
import 'package:flutter_rps/widgets/my_bottom_sheet.dart';
import 'package:flutter_rps/screens/test_rps.dart';
import 'package:flutter_rps/widgets/dropdown_selector.dart';
import 'package:flutter_rps/widgets/menu_card.dart';
import 'package:flutter_rps/screens/main_screen/display_page.dart';
import 'package:flutter_rps/widgets/widget_rgb_value.dart';

import 'package:flutter_rps/models/rps_model.dart';
import 'package:flutter_rps/utils/utils.dart' as utils;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final CacheManager cacheManager;
  final _textURLController = TextEditingController();
  final RpsModel _rpsModel = RpsModel();

  GlobalKey<MyBottomSheetState> globalMyBottomSheet = GlobalKey();
  GlobalKey<DisplayPageState> globalDisplayPage = GlobalKey();

  Future<void> _loadModel(
          {String? modelName, bool? gpuDelegate, bool? runIsolated}) async =>
      utils.loadModel(
          context: context,
          rpsModel: _rpsModel,
          modelName: modelName,
          gpuDelegate: gpuDelegate,
          runIsolated: runIsolated);

  @override
  void initState() {
    _loadModel(modelName: _rpsModel.currentModel);
    super.initState();
    cacheManager = DefaultCacheManager();
  }

  @override
  void dispose() {
    cacheManager.emptyCache();
    cacheManager.dispose();
    super.dispose();
  }

  bool hidedMenu = false;
  bool showCoverMode = true;
  DisplayPages? displayPageMode;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light));
    return PopScope(
      canPop: showCoverMode,
      onPopInvoked: (didPop) {
        if (!didPop) {
          switchCoverNDisplay();
        }
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: showCoverMode
                ? _linearGradient(context)
                : _radialGradient(context),
          ),
          child: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    backToCover(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 24,
                          right: 24,
                        ),
                        child: Container(
                          alignment: Alignment.topCenter,
                          child: showCoverMode
                              ? cover(context)
                              : DisplayPage(
                                  key: globalDisplayPage,
                                  rpsModel: _rpsModel,
                                  displayPageMode: displayPageMode!,
                                  switchCoverNDisplay: switchCoverNDisplay,
                                  cacheManager: cacheManager,
                                  urlTextField: urlTextField,
                                  textURLController: _textURLController,
                                  rpsCamera: (context, rpsModel) async {
                                    return await rpsCamera(
                                        context: context, rpsModel: rpsModel);
                                  },
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              menu(context),
            ],
          ),
        ),
        floatingActionButton: hidedMenu
            ? GestureDetector(
                onLongPress: () {
                  setState(() {
                    hidedMenu = false;
                    globalMyBottomSheet.currentState!.setSheetSize(0.45);
                  });
                },
                child: FloatingActionButton(
                  backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                  shape: const CircleBorder(),
                  onPressed: (displayPageMode != null &&
                          displayPageMode == DisplayPages.fightWithRNG)
                      ? () {
                          globalDisplayPage.currentState!.plotInit();
                        }
                      : () {
                          setState(() {
                            hidedMenu = false;
                            globalMyBottomSheet.currentState!
                                .setSheetSize(0.45);
                          });
                        },
                  child: Iconify(
                    (displayPageMode != null &&
                            displayPageMode == DisplayPages.fightWithRNG)
                        ? svg_icons.fight
                        : svg_icons.menu,
                    color: Colors.white,
                  ),
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _bottomAppBar(context),
      ),
    );
  }

  void switchCoverNDisplay({DisplayPages? pageMode}) async {
    if (pageMode != null) {
      displayPageMode = pageMode;
      switch (displayPageMode) {
        case DisplayPages.downloadImage:
          if (await urlTextField() != 1) {
            return;
          }
          if (!showCoverMode) {
            globalDisplayPage.currentState!
                .plotInit(displayPageMode: displayPageMode);
          }
          break;
        default:
          if (!showCoverMode) {
            globalDisplayPage.currentState!
                .plotInit(displayPageMode: displayPageMode);
          }
      }

      if (!showCoverMode) {
        return;
      }
    }

    showCoverMode = !showCoverMode;
    if (showCoverMode) {
      globalMyBottomSheet.currentState!.setSheetSize(0.55);
      globalMyBottomSheet.currentState!.setMoveAble(false);
      hidedMenu = false;
    } else {
      globalMyBottomSheet.currentState!.setSheetSize(0.0);
      globalMyBottomSheet.currentState!.setMoveAble(true);
    }

    setState(() {});
  }

  Visibility backToCover() {
    return Visibility(
      visible: !showCoverMode,
      child: Row(
        children: [
          IconButton(
            padding: const EdgeInsets.all(0),
            onPressed: switchCoverNDisplay,
            icon: const Iconify(
              svg_icons.chevronBack,
              color: Colors.white,
            ),
          ),
          const Text(
            'Back',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Align menu(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: MyBottomSheet.initAnimation(
        key: globalMyBottomSheet,
        dragSensitivity: MediaQuery.of(context).size.height,
        navigatorPop: false,
        initialSheetSize: 0.55,
        minSheetSize: 0.1,
        maxSheetSize: 0.55,
        initialMoveAble: false,
        onHide: () => setState(() {
          hidedMenu = true;
        }),
        titleCustomWidget: Row(
          children: [
            const Text(
              'Model Selection',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              _rpsModel.currentModel,
              style: const TextStyle(fontWeight: FontWeight.w100),
            ),
          ],
        ),
        children: [
          DropDownSelector(
            items: _rpsModel.modelNames,
            value: _rpsModel.currentModel,
            onItemChanged: (value) {
              _loadModel(modelName: value).then((value) => setState(() {}));
            },
          ),
          const Padding(padding: EdgeInsets.all(8.0)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MenuCard(
                svgIcon: svg_icons.fight,
                title: 'Fight with RNG',
                onTap: () =>
                    switchCoverNDisplay(pageMode: DisplayPages.fightWithRNG),
              ),
              const Padding(padding: EdgeInsets.all(8.0)),
              MenuCard(
                svgIcon: svg_icons.camera,
                title: 'Live Camera',
                onTap: () {
                  switchCoverNDisplay(pageMode: DisplayPages.liveCamera);
                },
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MenuCard(
                svgIcon: svg_icons.imageFile,
                title: 'Open Image',
                onTap: () {
                  switchCoverNDisplay(pageMode: DisplayPages.pictureImage);
                },
              ),
              const Padding(padding: EdgeInsets.all(8.0)),
              MenuCard(
                svgIcon: svg_icons.url,
                title: 'Open URL Image',
                onTap: () {
                  switchCoverNDisplay(pageMode: DisplayPages.downloadImage);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<dynamic> settingSheet(BuildContext context) {
    return showMyBottomSheet(
        initialSheetSize: 0.6,
        context: context,
        title: 'Options',
        dragSensitivity: MediaQuery.of(context).size.height,
        contentScrollPhysics: const ScrollPhysics(),
        children: [
          StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                Row(
                  children: [
                    Text('Isolated Interpreter',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Switch(
                      value: _rpsModel.isIsolated,
                      onChanged: (value) async {
                        await _loadModel(
                          runIsolated: value,
                        );
                        setState(() {});
                      },
                    )
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Gpu Delegate',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Switch(
                      value: _rpsModel.isGpuDelegate,
                      onChanged: (value) async {
                        await _loadModel(
                          gpuDelegate: value,
                        );
                        setState(() {});
                      },
                    )
                  ],
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Detection Confidence',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(_rpsModel.objConfidence.toStringAsFixed(6))
                      ],
                    ),
                    Slider(
                      min: RpsModel.objConfidenceMin,
                      max: RpsModel.objConfidenceMax,
                      label: _rpsModel.objConfidence.toStringAsFixed(3),
                      value: _rpsModel.objConfidence,
                      onChanged: (value) {
                        _rpsModel.setObjConfidence(value);
                        setState(() {});
                      },
                    )
                  ],
                ),
                rgbModelMean(context, setState),
                rgbModelStd(context, setState),
              ],
            ),
          )
        ]);
  }

  Future<dynamic> urlTextField() {
    return showMyBottomSheet(
        context: context,
        dragSensitivity: MediaQuery.of(context).size.height,
        title: '',
        contentScrollPhysics: const NeverScrollableScrollPhysics(),
        showDragHandle: false,
        dontUseList: true,
        initialSheetSize: 0.35,
        minSheetSize: 0.28,
        titleCustomWidget: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Text(
                'Fill Text Field',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const Spacer(flex: 2),
            IconButton(
                onPressed: () {
                  Navigator.of(context).pop(0);
                },
                icon: const Icon(Icons.close_rounded)),
          ],
        ),
        children: [
          Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: TextField(
                    controller: _textURLController,
                    maxLines: 1000,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Raw Image URL',
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0))),
                  onPressed: () {
                    Navigator.of(context).pop(1);
                  },
                  child: const Text('Go'),
                ),
              )
            ],
          ),
        ]);
  }

  WidgetrgbValue rgbModelMean(BuildContext context, StateSetter setState) {
    return WidgetrgbValue(
      rpsModel: _rpsModel,
      sliderTitle: 'Use Custom Mean',
      rgbSuggestions: _rpsModel.modelMeanAvailable,
      onEditingComplete: (enabled, value) {
        _rpsModel.setCustomMean(enabled: enabled, mean: value);
      },
      modifiedRgb: List.from(_rpsModel.modelMean),
      enabled: _rpsModel.useCustomMean,
      context: context,
      setState: setState,
    );
  }

  WidgetrgbValue rgbModelStd(BuildContext context, StateSetter setState) {
    return WidgetrgbValue(
      rpsModel: _rpsModel,
      sliderTitle: 'Use Custom Std',
      rgbSuggestions: _rpsModel.modelStdAvailable,
      onEditingComplete: (enabled, value) {
        _rpsModel.setCustomSTD(enabled: enabled, std: value);
      },
      modifiedRgb: List.from(_rpsModel.modelSTD),
      enabled: _rpsModel.useCustomSTD,
      context: context,
      setState: setState,
    );
  }

  SizedBox cover(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.375,
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Iconify(
                  color: Colors.white,
                  svg_icons.github,
                  size: 30,
                ),
                Spacer(flex: 20),
                Iconify(
                  color: Colors.white,
                  svg_icons.flutter,
                  size: 25,
                ),
                Spacer(),
                Iconify(
                  color: Colors.white,
                  svg_icons.tensorFlow,
                  size: 25,
                ),
                Spacer(),
                Iconify(
                  color: Colors.white,
                  svg_icons.pyTorch,
                  size: 25,
                ),
              ],
            ),
            const Spacer(),
            Text(
              'Rock\nPaper\nScissor',
              style: GoogleFonts.justMeAgainDownHere()
                  .copyWith(fontSize: 74, height: 0.65),
            ),
            const Spacer(),
            Text(
              "A Flutter application that implements ML vision, with a classification model and an object detection model",
              style: GoogleFonts.justAnotherHand()
                  .copyWith(fontSize: 28, height: 0.75),
            ),
          ],
        ),
      ),
    );
  }

  RadialGradient _radialGradient(BuildContext context) {
    return RadialGradient(
      radius: 1,
      colors: [
        const Color.fromARGB(255, 184, 165, 215),
        Theme.of(context).colorScheme.primary,
      ],
      stops: const [0.0, 1.0],
      tileMode: TileMode.clamp,
    );
  }

  LinearGradient _linearGradient(BuildContext context) {
    return LinearGradient(
      colors: [
        const Color.fromARGB(255, 184, 165, 215),
        Theme.of(context).colorScheme.primary,
      ],
      begin: FractionalOffset.centerLeft,
      end: FractionalOffset.topRight,
      stops: const [0.0, 1.0],
      tileMode: TileMode.clamp,
    );
  }

  BottomAppBar _bottomAppBar(BuildContext context) {
    return BottomAppBar(
      height: 80,
      notchMargin: 8,
      padding: const EdgeInsets.all(0),
      shape: const CircularNotchedRectangle(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Column(
            children: [
              IconButton(
                onPressed: () => settingSheet(context),
                icon: const Iconify(
                  svg_icons.settingTwoOutline,
                  size: 24,
                ),
                tooltip: 'Settings',
              ),
              Container(
                  alignment: Alignment.center,
                  width: 100,
                  child: const Text('Settings'))
            ],
          ),
          const Spacer(
            flex: 3,
          ),
          Column(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const TestRps(title: 'Testing Page'),
                )),
                icon: const Iconify(
                  svg_icons.experiment,
                  size: 28,
                ),
                tooltip: '(Will be removed soon)',
              ),
              Container(
                  alignment: Alignment.center,
                  width: 100,
                  child: const Text('Test Page'))
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
