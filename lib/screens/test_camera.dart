import "package:camera/camera.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import 'package:flutter_rps/widgets/my_bottom_sheet.dart';
import 'dart:io';

import "package:flutter_rps/models/rps_model.dart";
import "package:flutter_rps/utils/utils.dart";

class CameraScreen extends StatefulWidget {
  const CameraScreen(
      {super.key,
      required this.camera,
      required this.rpsModel,
      required this.screenMaxHeight});

  final CameraDescription camera;
  final RpsModel rpsModel;
  final double screenMaxHeight;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late final String _modelName;
  late final String _modelGpuDelegate;
  late final String _runIsolated;

  late CameraController _cameraController;
  late Future<void> _initCameraControllerFuture;
  List<double>? yLogits;
  dynamic test;
  bool predictInProcess = false;
  void Function()? statsSetState;

  @override
  void initState() {
    _modelName = widget.rpsModel.modelNames[widget.rpsModel.modelId];
    _modelGpuDelegate = (widget.rpsModel.isGpuDelegate) ? 'Yes' : 'No';
    _runIsolated = (widget.rpsModel.isIsolated) ? 'Yes' : 'No';

    _cameraController = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initCameraControllerFuture =
        _cameraController.initialize().then((value) async {
      _cameraController.startImageStream(
        (image) async {
          if (!predictInProcess) {
            predictInProcess = true;
            final result = await streamPredict(image);
            if (!mounted) {
              return;
            }
            predictInProcess = false;
            yLogits = result;
            statsSetState?.call();
            setState(() {});
          } else {}

          if (kDebugMode) {
            print("Image Format: ${image.format.group}");
          }
        },
      );
    });

    super.initState();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> takePicture() async {
    _cameraController.stopImageStream();
    await _initCameraControllerFuture;
    final image = await _cameraController.takePicture();
    if (!mounted) return;
    Navigator.pop(context, File(image.path));
  }

  Future<List<double>> streamPredict(CameraImage image) async {
    final img = await Utils.cameraImageToJpg(image);
    return await widget.rpsModel.getImagePredict(img);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initCameraControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_cameraController),
                // (test == null) ? Text('data') : test,
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18.0),
                        child: ElevatedButton(
                          onPressed: takePicture,
                          style: ButtonStyle(
                            shape:
                                MaterialStateProperty.all(const CircleBorder()),
                            padding: MaterialStateProperty.all(
                                const EdgeInsets.all(30)),
                            backgroundColor: MaterialStateProperty.all(
                                Theme.of(context).canvasColor),
                            overlayColor: MaterialStateProperty.resolveWith(
                              (states) {
                                if (states.contains(MaterialState.pressed)) {
                                  return Theme.of(context).hoverColor;
                                }
                                return null;
                              },
                            ),
                          ),
                          child: const Icon(Icons.camera),
                        ),
                      ),
                      GestureDetector(
                          onTap: () => showMyBottomSheet(
                                context: context,
                                isDismissible: false,
                                barrierColor: Colors.black.withOpacity(0.1),
                                dragSensitivity: widget.screenMaxHeight,
                                title: 'Stats',
                                maxSheetSize: 0.5,
                                child: StatefulBuilder(
                                  builder: (context, setState) {
                                    statsSetState = () {
                                      setState(() {});
                                    };
                                    return Expanded(
                                      child: ListView(
                                        children: [
                                          gridLogits(context),
                                          const Row(
                                            children: [
                                              Text(
                                                'Preprocess time',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Spacer(),
                                              Text('data')
                                            ],
                                          ),
                                          const Row(
                                            children: [
                                              Text(
                                                'Predict time',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Spacer(),
                                              Text('data')
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const Text(
                                                'Model Name',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const Spacer(),
                                              Text(_modelName)
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const Text(
                                                'Gpu Delegate',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const Spacer(),
                                              Text(_modelGpuDelegate)
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const Text(
                                                'Isolated',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const Spacer(),
                                              Text(_runIsolated)
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ).whenComplete(() => statsSetState = null),
                          child: gridLogits(context)),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }

  GridView gridLogits(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      childAspectRatio: 2,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      children: List.generate(
        3,
        (index) => Column(
          children: [
            Text(
              widget.rpsModel.classNames[index],
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text((yLogits == null)
                ? 'data'
                : '${num.parse(yLogits![index].toStringAsExponential(3))}')
          ],
        ),
      ),
    );
  }
}
