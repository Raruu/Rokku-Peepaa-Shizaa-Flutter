import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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
}
