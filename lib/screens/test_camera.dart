import "package:camera/camera.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import 'package:flutter_rps/widgets/my_bottom_sheet.dart';
import 'dart:io';
import 'package:flutter_rps/widgets/bounding_box.dart';

import "package:flutter_rps/models/rps_model.dart";

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

  late CameraController _cameraController;
  late Future<void> _initCameraControllerFuture;
  List<double> predProbs = List.filled(3, -1);
  bool predictInProcess = false;
  void Function()? statsSetState;

  @override
  void initState() {
    _modelName = widget.rpsModel.modelNames[widget.rpsModel.modelId];
    _modelGpuDelegate = (widget.rpsModel.isGpuDelegate) ? 'Yes' : 'No';

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
    });

    super.initState();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> takePicture() async {
    await _cameraController.stopImageStream();
    await _initCameraControllerFuture;
    final image = await _cameraController.takePicture();
    if (!mounted) return;
    Navigator.pop(context, File(image.path));
  }

  Future<void> streamPredict(CameraImage image) async {
    final modelOutput = await widget.rpsModel.cameraStreamPredict(image);

    switch (EnumModelTypes.values.byName(widget.rpsModel.modelType)) {
      case EnumModelTypes.classification:
        predProbs = modelOutput['predProbs'];
        break;
      case EnumModelTypes.yolov5:
        for (int i = 0; i < predProbs.length; i++) {
          predProbs[i] = modelOutput['rpsFounds'][i].toDouble();
        }
        break;
      default:
    }
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
                // (widget.rpsModel.modelType == EnumModelTypes.yolov5.name) ? BBox() : null,
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
                          onTap: () => showStats(context),
                          onPanStart: (details) => showStats(context),
                          child: gridProbs(context)),
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

  Future<dynamic> showStats(BuildContext context) {
    return showMyBottomSheet(
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
                gridProbs(context),
                Row(
                  children: [
                    const Text(
                      'Preprocess time',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text('${widget.rpsModel.preprocessTime} Secs')
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      'Predict time',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text('${widget.rpsModel.predictTime} Secs')
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      'Output time',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text('${widget.rpsModel.outputProcessTime} Secs')
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      'Model Name',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(_modelName)
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      'Gpu Delegate',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(_modelGpuDelegate)
                  ],
                ),
                const Padding(padding: EdgeInsets.all(4)),
                Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Detection Confidence',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(widget.rpsModel.objConfidence.toStringAsFixed(6))
                      ],
                    ),
                    Slider(
                      min: RpsModel.objConfidenceMin,
                      max: RpsModel.objConfidenceMax,
                      label: widget.rpsModel.objConfidence.toStringAsFixed(3),
                      value: widget.rpsModel.objConfidence,
                      onChanged: (value) {
                        widget.rpsModel.setObjConfidence(value);
                        setState(() {});
                      },
                    )
                  ],
                )
              ],
            ),
          );
        },
      ),
    ).whenComplete(() => statsSetState = null);
  }

  GridView gridProbs(BuildContext context) {
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
            Text((predProbs[0] < 0)
                ? '--'
                : '${num.parse(predProbs[index].toStringAsFixed(3))}')
          ],
        ),
      ),
    );
  }
}
