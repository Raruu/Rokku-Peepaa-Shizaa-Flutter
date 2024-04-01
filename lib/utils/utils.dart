import 'dart:io';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imagelib;

Widget plotImage(File? value, {List<Widget>? bBoxesWidget}) {
  if (value == null) {
    return const Icon(
      Icons.image,
      size: 100.0,
    );
  } else if (value.existsSync()) {
    return Stack(children: [Image.file(value), ...?bBoxesWidget]);
  } else {
    return const CircularProgressIndicator();
  }
}

Future<File?> pickFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles();
  File? file;
  if (result != null) {
    file = File(result.files.single.path!);
  }
  return file;
}

File imagePathFromImageProvider(ImageProvider input) {
  String inputAsString = input.toString();
  int start = inputAsString.indexOf("\"") + 1;
  int end = inputAsString.indexOf("\"", start);
  String path = input.toString().substring(start, end);
  return File(path);
}

void showSnackBar(BuildContext context, String massage, {Duration? durations}) {
  durations ??= Durations.extralong4;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    duration: durations,
    content: Text(massage),
  ));
}

// Look at: https://stackoverflow.com/a/76386834/21073176

List<Uint8List> processGetYUVFromPlanes(Map<String, dynamic> data) {
  CameraImage availableImage = data['cameraImage'];
  List<Uint8List> planes = [];
  for (int planeIndex = 0; planeIndex < 3; planeIndex++) {
    Uint8List buffer;
    int width;
    int height;
    if (planeIndex == 0) {
      width = availableImage.width;
      height = availableImage.height;
    } else {
      width = availableImage.width ~/ 2;
      height = availableImage.height ~/ 2;
    }

    buffer = Uint8List(width * height);

    int pixelStride = availableImage.planes[planeIndex].bytesPerPixel!;
    int rowStride = availableImage.planes[planeIndex].bytesPerRow;
    int index = 0;
    for (int i = 0; i < height; i++) {
      for (int j = 0; j < width; j++) {
        buffer[index++] = availableImage
            .planes[planeIndex].bytes[i * rowStride + j * pixelStride];
      }
    }

    planes.add(buffer);
  }
  return planes;
}

Future<List<Uint8List>> getYUVFromPlanes(CameraImage availableImage) async {
  return await compute(processGetYUVFromPlanes, {
    'cameraImage': availableImage,
  });
}

List<Uint8List> processyuv420ToJpg(Map<String, dynamic> data) {
  List<Uint8List> planes = data['planes'];
  int width = data['width'];
  int height = data['height'];

  final yPlane = planes[0];
  final uPlane = planes[1];
  final vPlane = planes[2];
  var img = imagelib.Image(width: width, height: height);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int yIndex = y * width + x;
      final int uvIndex = (y ~/ 2) * (width ~/ 2) + (x ~/ 2);
      if (kDebugMode) {}

      final int yValue = yPlane[yIndex] & 0xFF;
      final int uValue = uPlane[uvIndex] & 0xFF;
      final int vValue = vPlane[uvIndex] & 0xFF;

      final int r = (yValue + 1.13983 * (vValue - 128)).round().clamp(0, 255);
      final int g =
          (yValue - 0.39465 * (uValue - 128) - 0.58060 * (vValue - 128))
              .round()
              .clamp(0, 255);
      final int b = (yValue + 2.03211 * (uValue - 128)).round().clamp(0, 255);
      img.setPixel(x, y, imagelib.ColorFloat32.rgb(r, g, b));
    }
  }
  return [imagelib.encodeJpg(img)];
}

Future<Uint8List> yuv420ToJpg(
    List<Uint8List> planes, int width, int height) async {
  final result = await compute(
      processyuv420ToJpg, {'planes': planes, 'width': width, 'height': height});
  return result[0];
}

Future<Uint8List> cameraImageToJpg(CameraImage image) async {
  // final yuv =
  return await yuv420ToJpg(
      await getYUVFromPlanes(image), image.width, image.height);
}
