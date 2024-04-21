import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rps/models/rps_model.dart';
import 'package:flutter_rps/screens/test_camera.dart';

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
        builder: (context) => TestCameraScreen(
          camera: cameras.first,
          rpsModel: rpsModel,
        ),
      ),
    );
  }
  return results;
}
