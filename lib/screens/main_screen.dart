import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:flutter_rps/screens/test_camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconify_flutter/iconify_flutter.dart';

import 'package:flutter_rps/widgets/svg_icons.dart' as svg_icons;
import 'package:flutter_rps/widgets/my_bottom_sheet.dart';
import 'package:flutter_rps/screens/test_rps.dart';
import 'package:flutter_rps/widgets/dropdown_selector.dart';
import 'package:flutter_rps/widgets/menu_card.dart';

import 'package:flutter_rps/models/rps_model.dart';
import 'package:flutter_rps/utils/utils.dart' as utils;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final RpsModel _rpsModel = RpsModel();

  GlobalKey<MyBottomSheetState> globalMyBottomSheet = GlobalKey();

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
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool hideMenu = false;
  bool showCoverMode = true;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light));
    return Scaffold(
      extendBody: true,
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
            cover(context),
            menu(context),
          ],
        ),
      ),
      floatingActionButton: hideMenu
          ? FloatingActionButton(
              shape: const CircleBorder(),
              onPressed: () {
                setState(() {
                  hideMenu = false;
                  globalMyBottomSheet.currentState!.setSheetSize(0.35);
                });
              },
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _bottomAppBar(context),
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
        onHide: () => setState(() {
          hideMenu = true;
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
                onTap: () {},
              ),
              const Padding(padding: EdgeInsets.all(8.0)),
              MenuCard(
                svgIcon: svg_icons.camera,
                title: 'Live Camera',
                onTap: () {
                  // Navigator.of(context).push(
                  //   MaterialPageRoute(
                  //     builder: (context) => CameraScreen(
                  //       rpsModel: _rpsModel,
                  //     ),
                  //   ),
                  // );
                  setState(() {
                    showCoverMode = !showCoverMode;
                  });
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
                onTap: () {},
              ),
              const Padding(padding: EdgeInsets.all(8.0)),
              MenuCard(
                svgIcon: svg_icons.url,
                title: 'Open URL Image',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  SafeArea cover(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(
          top: 16,
          bottom: 16,
          left: 24,
          right: 24,
        ),
        child: SizedBox(
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
                onPressed: () {},
                icon: const Icon(Icons.settings_outlined),
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
                tooltip: 'Test Page',
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
