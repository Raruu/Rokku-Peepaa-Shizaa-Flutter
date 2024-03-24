import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imagelib;

class Utils {
  static dynamic plotImage(File? value) {
    dynamic imageWidgetPlotter;
    if (value == null) {
      imageWidgetPlotter = const Icon(
        Icons.image,
        size: 100.0,
      );
    } else if (value.existsSync()) {
      imageWidgetPlotter = Image.file(value);
    } else {
      imageWidgetPlotter = const CircularProgressIndicator();
    }
    return imageWidgetPlotter;
  }

  static Future<File?> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    File? file;
    if (result != null) {
      file = File(result.files.single.path!);
    }
    return file;
  }

  static File imagePathFromImageProvider(ImageProvider input) {
    String inputAsString = input.toString();
    int start = inputAsString.indexOf("\"") + 1;
    int end = inputAsString.indexOf("\"", start);
    String path = input.toString().substring(start, end);
    return File(path);
  }

  static void showSnackBar(BuildContext context, String massage,
      {Duration? durations}) {
    durations ??= Durations.extralong4;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: durations,
      content: Text(massage),
    ));
  }

  // Look at: https://stackoverflow.com/a/76386834/21073176
  static List<Uint8List> getYUVFromPlanes(CameraImage availableImage) {
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

  static Uint8List yuv420ToJpg(List<Uint8List> planes, int width, int height) {
    final yPlane = planes[0];
    final uPlane = planes[1];
    final vPlane = planes[2];
    var img = imagelib.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * width + x;
        final int uvIndex = (y ~/ 2) * (width ~/ 2) + (x ~/ 2);

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
    return imagelib.encodeJpg(img);
  }

  static Future<Uint8List> cameraImageToJpg(CameraImage image) async =>
      yuv420ToJpg(getYUVFromPlanes(image), image.width, image.height);

  // static Future<List<double>> isolated(){

  // }
}
