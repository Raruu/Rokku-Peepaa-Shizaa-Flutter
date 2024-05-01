import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import "package:flutter/material.dart";

import 'package:flutter_rps/widgets/svg_icons.dart' as svg_icons;
import 'package:iconify_flutter/iconify_flutter.dart';

class FightCamera extends StatefulWidget {
  const FightCamera({
    super.key,
    required this.camera,
    required this.switchCoverNDisplay,
  });

  final CameraDescription camera;
  final void Function()? switchCoverNDisplay;

  @override
  State<FightCamera> createState() => _FightCameraState();
}

class _FightCameraState extends State<FightCamera> {
  late CameraController _cameraController;
  late Future<void> _initCameraControllerFuture;

  bool inTaking = false;
  String strCountDown = 'Take your hand pose';

  int _handPoseSelect = 0;

  @override
  void initState() {
    _cameraController = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initCameraControllerFuture = _cameraController.initialize();

    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) return;
      setState(() {
        _handPoseSelect = (_handPoseSelect + 1) % 3;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void takePicture() {
    int countDown = 3;
    setState(() {
      inTaking = true;
      strCountDown = countDown.toString();
      countDown--;
    });

    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (countDown <= 0) {
        timer.cancel();
        await _initCameraControllerFuture;
        final image = await _cameraController.takePicture();
        if (!mounted) return;
        Navigator.pop(context, File(image.path));
      }
      strCountDown = countDown.toString();
      countDown--;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: backToCover(),
          ),
          const Spacer(),
          Text(
            strCountDown,
            style: const TextStyle(color: Colors.white, fontSize: 32),
          ),
          const Padding(padding: EdgeInsets.all(16)),
          Center(
            child: Container(
              height: MediaQuery.of(context).size.width * (2 / 3) * (4 / 3),
              width: MediaQuery.of(context).size.width * 2 / 3,
              alignment: Alignment.center,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  FutureBuilder(
                    future: _initCameraControllerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: CameraPreview(_cameraController));
                      }
                      return const SizedBox();
                    },
                  ),
                  Visibility(
                    visible: !inTaking,
                    child: Container(
                      color: Colors.white.withOpacity(0.7),
                      width: double.infinity,
                      height: double.infinity,
                      alignment: Alignment.center,
                      child: Iconify(
                        svg_icons.hands[_handPoseSelect],
                        size: 96,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Text(
            '(3 second countdown)',
            style: TextStyle(color: Colors.white),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 2 / 15,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusDirectional.circular(8))),
              onPressed: inTaking ? null : takePicture,
              child: Text(inTaking ? '>w<' : 'Start take Picture'),
            ),
          ),
        ],
      ),
    );
  }

  Row backToCover() {
    return Row(
      children: [
        IconButton(
          padding: const EdgeInsets.all(0),
          onPressed: () {
            Navigator.pop(context, null);
          },
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
    );
  }
}
