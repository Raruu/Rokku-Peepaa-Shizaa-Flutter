import "package:camera/camera.dart";
import 'package:shimmer/shimmer.dart';
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import 'dart:io';

import 'package:flutter_rps/widgets/my_bottom_sheet.dart';
import 'package:flutter_rps/widgets/bounding_box.dart';
import 'package:flutter_rps/screens/component.dart' as component;

import 'package:flutter_rps/utils/utils.dart' as utils;
import "package:flutter_rps/models/rps_model.dart";
import 'dart:math' as math;

class MobileCameraScreen extends StatefulWidget {
  const MobileCameraScreen({
    super.key,
    required this.camera,
    required this.rpsModel,
    required this.screenMaxWidth,
    required this.screenMaxHeight,
  });

  final CameraDescription camera;
  final RpsModel rpsModel;
  final double screenMaxWidth;
  final double screenMaxHeight;

  @override
  State<MobileCameraScreen> createState() => _MobileCameraScreenState();
}

class _MobileCameraScreenState extends State<MobileCameraScreen> {
  late CameraController _cameraController;
  late Future<void> _initCameraControllerFuture;
  FlashMode _flashMode = FlashMode.off;
  int _flashModeSelect = 0;

  final List<String> _aspectRatioTitle = ['1:1', '3:4', '9:16', 'Screen'];
  late List<List<double>> _aspectRatio;
  int _aspectRatioSelect = 1;

  List<double> predProbs = List.filled(3, -1);

  Future<void> takePicture() async {
    await _cameraController.stopImageStream();
    await _initCameraControllerFuture;
    final image = await _cameraController.takePicture();
    if (!mounted) return;
    Navigator.pop(context, File(image.path));
  }

  bool predictInProcess = false;
  List<Widget> bBoxes = [];
  void Function()? statsSetState;

  Future<void> streamPredict(CameraImage image) async {
    final modelOutputs = await widget.rpsModel.cameraStreamPredict(image);

    switch (EnumModelTypes.values.byName(widget.rpsModel.modelType)) {
      case EnumModelTypes.classification:
        predProbs = modelOutputs['predProbs'];
        break;
      case EnumModelTypes.yolov5:
        for (int i = 0; i < predProbs.length; i++) {
          predProbs[i] = modelOutputs['rpsFounds'][i].toDouble();
        }

        final List<List<double>> listBoxes = modelOutputs['boxes'];
        final List<List<double>> classIds = modelOutputs['classIds'];

        final double resizeFactor = utils.resizeFactor(
            screenMaxWidth: _aspectRatio[_aspectRatioSelect][0],
            widgetMaxHeight: _aspectRatio[_aspectRatioSelect][1],
            imageWidth: image.width,
            imageHeight: image.height);

        if (kDebugMode) {
          print("resizeFactor: $resizeFactor");
        }

        bBoxes = List.generate(
          listBoxes.length,
          (index) {
            final double left =
                math.min(listBoxes[index][0], listBoxes[index][2]) *
                    resizeFactor;
            final double top =
                math.min(listBoxes[index][1], listBoxes[index][3]) *
                    resizeFactor;
            final double right =
                math.max(listBoxes[index][0], listBoxes[index][2]) *
                    resizeFactor;
            final double bottom =
                math.max(listBoxes[index][1], listBoxes[index][3]) *
                    resizeFactor;
            List<double> confidences = modelOutputs['confidences'];
            return BBox(
                left: (right - left),
                top: (bottom - top),
                width: (right - left),
                height: (bottom - top),
                label:
                    "${widget.rpsModel.getImagePredictClassNames(classIds[index])} ${confidences[index].toStringAsFixed(3)}");
          },
        );
        break;
      default:
    }
  }

  @override
  void initState() {
    _cameraController = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );

    _initCameraControllerFuture = _cameraController.initialize().then(
      (value) {
        _cameraController.startImageStream(
          (image) async {
            if (!predictInProcess) {
              predictInProcess = true;
              await streamPredict(image);
              if (!mounted) {
                return;
              }
              predictInProcess = false;
              statsSetState?.call();
              setState(() {});
              if (kDebugMode) {
                print("Image Format: ${image.format.group}");
              }
            }
          },
        );
      },
    );

    // Width x Height
    _aspectRatio = [
      // 1:1
      [widget.screenMaxWidth, widget.screenMaxWidth],
      // 3:4
      [widget.screenMaxWidth, widget.screenMaxWidth * (4 / 3)],
      // 9:16
      [widget.screenMaxWidth, widget.screenMaxWidth * (16 / 9)],
      //Screen
      [widget.screenMaxWidth, widget.screenMaxHeight]
    ];
    super.initState();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder(
        future: _initCameraControllerFuture,
        builder: (context, snapshot) {
          return Stack(
            children: [
              Column(
                children: [
                  const Spacer(flex: 1),
                  (snapshot.connectionState == ConnectionState.done)
                      ? Center(
                          //TODO: Make an actual aspect ratio
                          child: SizedBox(
                              width: _aspectRatio[_aspectRatioSelect][0],
                              height: _aspectRatio[_aspectRatioSelect][1],
                              child: CameraPreview(_cameraController)),
                        )
                      : Shimmer.fromColors(
                          baseColor: Colors.black54,
                          highlightColor: Colors.white,
                          child: Container(
                            color: Colors.black54,
                            width: double.infinity,
                            height: widget.screenMaxWidth * (4 / 3),
                          ),
                        ),
                  const Spacer(flex: 2),
                ],
              ),
              ...bBoxes,
              topBar(context),
              bottomBar((snapshot.connectionState == ConnectionState.done)),
            ],
          );
        },
      ),
    );
  }

  Align bottomBar(bool loaded) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        height: widget.screenMaxHeight * 11 / 45,
        alignment: Alignment.center,
        color: Colors.black.withOpacity(0.5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: GestureDetector(
                onTap: () {
                  showMyBottomSheet(
                      context: context,
                      dragSensitivity: widget.screenMaxHeight,
                      title: 'Details',
                      maxSheetSize: 0.45,
                      initialSheetSize: 0.4,
                      barrierColor: Colors.black.withOpacity(0.1),
                      children: [
                        StatefulBuilder(
                          builder: (context, setState) {
                            statsSetState = () => setState(() {});
                            return component.resultDetails(
                                context, widget.rpsModel, predProbs);
                          },
                        )
                      ]);
                },
                child: component.gridProbs(context, widget.rpsModel, predProbs,
                    textColor: Colors.white),
              ),
            ),
            SizedBox(
                width: 75,
                height: 75,
                child: loaded
                    ? OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(10),
                          side: const BorderSide(color: Colors.white, width: 2),
                        ),
                        onPressed: takePicture,
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              shape: BoxShape.circle),
                        ),
                      )
                    : Shimmer.fromColors(
                        baseColor: Colors.grey,
                        highlightColor: Colors.white,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(10),
                            side:
                                const BorderSide(color: Colors.white, width: 2),
                          ),
                          onPressed: null,
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.5),
                                shape: BoxShape.circle),
                          ),
                        ),
                      )),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Container topBar(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 100,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      color: Colors.black.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                _flashModeSelect = (_flashModeSelect + 1) % 4;
                _flashMode = FlashMode.values[_flashModeSelect];
                _cameraController.setFlashMode(_flashMode);
                setState(() {});
              },
              icon: Icon(
                switch (_flashMode) {
                  FlashMode.off => Icons.flashlight_off_rounded,
                  FlashMode.auto => Icons.flash_auto_rounded,
                  FlashMode.always => Icons.flashlight_on_rounded,
                  FlashMode.torch => Icons.flash_on_rounded
                },
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Text(
              widget.rpsModel.modelType,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {
                setState(() {
                  _aspectRatioSelect = (_aspectRatioSelect + 1) % 4;
                  if (kDebugMode) {
                    print('aspect: $_aspectRatioSelect');
                    print(_aspectRatio[_aspectRatioSelect][0]);
                    print(_aspectRatio[_aspectRatioSelect][1]);
                  }
                });
              },
              icon: Text(
                _aspectRatioTitle[_aspectRatioSelect],
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
