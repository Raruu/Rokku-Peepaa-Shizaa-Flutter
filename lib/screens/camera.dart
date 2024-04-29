import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rps/models/rps_model.dart';
import 'package:flutter_rps/screens/test_camera.dart';
import "package:flutter_rps/screens/mobile_camera.dart";

Future<File?> rpsCamera({
  required BuildContext context,
  required RpsModel rpsModel,
}) async {
  final cameras = await availableCameras();
  if (!context.mounted) return null;
  File? results;

  if (Platform.isAndroid || Platform.isIOS) {
    results = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MobileCameraScreen(
          camera: cameras.first,
          rpsModel: rpsModel,
          screenMaxWidth: MediaQuery.of(context).size.width,
          screenMaxHeight: MediaQuery.of(context).size.height,
        ),
      ),
    );
  }
  return results;
}

Future<File?> rpsCameraTest({
  required BuildContext context,
  required RpsModel rpsModel,
}) async {
  final cameras = await availableCameras();
  if (!context.mounted) return null;
  File? results;

  if (Platform.isAndroid || Platform.isIOS) {
    results = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TestCameraScreen(
          camera: cameras.first,
          rpsModel: rpsModel,
        ),
      ),
    );
  }
  return results;
}
