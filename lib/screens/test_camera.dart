import "package:camera/camera.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import 'dart:io';

import "package:flutter_rps/models/rps_model.dart";
import "package:flutter_rps/utils/utils.dart";

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, required this.camera, required this.rpsModel});

  final CameraDescription camera;

  final RpsModel rpsModel;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _cameraController;
  late Future<void> _initCameraControllerFuture;
  List<double>? yLogits;
  dynamic test;

  @override
  void initState() {
    _cameraController = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initCameraControllerFuture =
        _cameraController.initialize().then((value) async {
      _cameraController.startImageStream(
        (image) async {
          yLogits = await streamPredict(image);
          _cameraController.stopImageStream();
          // await Utils.cameraImageToJpg(image)
          //     .then((value) => test = Image.memory(value));
          setState(() {});
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
                      GridView.count(
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
                      ),
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
}
