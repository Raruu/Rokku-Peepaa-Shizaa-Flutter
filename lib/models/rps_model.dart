import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as imagelib;

class RpsModel {
  List<String> get classNames => ['paper', 'rock', 'scissors'];
  // ignore: prefer_typing_uninitialized_variables
  var _interpreter;
  final Stopwatch _stopWatch = Stopwatch();
  String get executionTime => _stopWatch.elapsed.toString().substring(5);

  RpsModel() {
    loadModel();
  }

  Future<void> loadModel() async {
    _interpreter =
        await tfl.Interpreter.fromAsset('assets/models/model_V1.tflite');
  }

  List<List<List<num>>> imageToTensor(File imageFile, int width, int height) {
    imagelib.Image? image = imagelib.decodeImage(imageFile.readAsBytesSync());
    image = imagelib.copyResize(image!, width: width, height: height);

    final imageMatrix = List.generate(
      image.height,
      (y) => List.generate(image!.width, (x) {
        final pixel = image?.getPixel(x, y);
        var r = (pixel!.rNormalized - 0.485) / 0.229;
        var g = (pixel.gNormalized - 0.456) / 0.224;
        var b = (pixel.bNormalized - 0.406) / 0.225;
        return [r, g, b];
      }),
    );

    // mean=[0.485, 0.456, 0.406]
    // std=[0.229, 0.224, 0.225]

    List<List<List<num>>> permutedList = List.generate(
      3,
      (index) => List.generate(height, (_) => List.generate(width, (_) => 0)),
    );

    for (var i = 0; i < imageMatrix.length; i++) {
      for (var j = 0; j < imageMatrix[i].length; j++) {
        for (var k = 0; k < imageMatrix[i][j].length; k++) {
          permutedList[k][i][j] = imageMatrix[i][j][k];
        }
      }
    }
    return permutedList;
  }

  // Get Logits
  List getImagePredictLogits(File imageFile) {
    _stopWatch.reset();
    _stopWatch.start();
    final imageTensor = imageToTensor(imageFile, 224, 224);
    final input = [imageTensor];
    var output = List.filled(1 * 3, 0).reshape([1, 3]);

    _interpreter.run(input, output);

    if (kDebugMode) {
      print(input.shape);
      print(output.shape);
      print(output);
    }

    _stopWatch.stop();
    return output;
  }

  String getImagePredictClassNames(List<double> yLogits) {
    double highest = double.negativeInfinity;
    int index = 0;
    for (var i = 0; i < yLogits.length; i++) {
      if (yLogits[i] > highest) {
        highest = yLogits[i];
        index = i;
      }
    }
    return classNames[index];
  }
}
