import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as imagelib;
import 'package:flutter_rps/models/rps_models_constant.dart' as model;

class RpsModel {
  List<String> get modelNames => model.modelNames;
  List<String> get classNames => model.classNames;
  List<double> get mean => model.mean[_id];
  List<double> get std => model.std[_id];

  // ignore: prefer_typing_uninitialized_variables
  late tfl.Interpreter _interpreter;
  int _id = 0;

  final Stopwatch _stopWatch = Stopwatch();
  String get executionTime => _stopWatch.elapsed.toString().substring(5);

  RpsModel() {
    // loadModel();
  }

  Future<void> loadModel(String modelName) async {
    _id = model.modelNames.indexOf(modelName);
    _interpreter =
        await tfl.Interpreter.fromAsset('assets/models/$modelName.tflite');
    _interpreter.allocateTensors();
  }

  List<List<List<num>>> imageToTensor(File imageFile, int width, int height) {
    imagelib.Image? image = imagelib.decodeImage(imageFile.readAsBytesSync());
    image = imagelib.copyResize(image!, width: width, height: height);

    if (kDebugMode) {
      print("MEAN: ${model.mean[_id]}");
      print("STD: ${model.std[_id]}");
    }

    final imageMatrix = List.generate(
      image.height,
      (y) => List.generate(image!.width, (x) {
        final pixel = image?.getPixel(x, y);
        var r = (pixel!.rNormalized - model.mean[_id][0]) / model.std[_id][0];
        var g = (pixel.gNormalized - model.mean[_id][1]) / model.std[_id][1];
        var b = (pixel.bNormalized - model.mean[_id][2]) / model.std[_id][2];
        return [r, g, b];
      }),
    );

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

    _stopWatch.stop();

    if (kDebugMode) {
      print("Input Shape: $input.shape");
      print("Output Shape: $output.shape");
      print("Output: $output");
    }

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
    return model.classNames[index];
  }

  void close() {
    _interpreter.close();
  }
}
