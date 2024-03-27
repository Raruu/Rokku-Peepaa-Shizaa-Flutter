import 'dart:io';
import 'dart:math';
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
  late var _isolateInterpreter;
  late bool _isIsolated;
  late bool _isGpuDelegate;
  bool get isIsolated => _isIsolated;
  bool get isGpuDelegate => _isGpuDelegate;

  int _id = 0;
  int get modelId => _id;
  int get _width => 224;
  int get _height => 224;

  final Stopwatch _stopWatch = Stopwatch();
  String get executionTime => _stopWatch.elapsed.toString().substring(5);

  RpsModel({bool gpuDelegate = true, bool runIsolated = true}) {
    _isGpuDelegate = gpuDelegate;
    _isIsolated = runIsolated;
  }

  Future<void> loadModel(String modelName,
      {bool? gpuDelegate, bool? runIsolated}) async {
    gpuDelegate ??= _isGpuDelegate;
    runIsolated ??= _isIsolated;

    // I'm trying to free memory when loading another model
    // But this thing doesn't seem to free memory at all :(
    try {
      tfl.Interpreter pastInterpreter =
          tfl.Interpreter.fromAddress(_isolateInterpreter.address);
      pastInterpreter.close();
    } catch (e) {
      // if (kDebugMode) {
      //   print(e.toString());
      // }
    }

    _id = model.modelNames.indexOf(modelName);
    tfl.InterpreterOptions interpreterOptions = tfl.InterpreterOptions();

    _isGpuDelegate = gpuDelegate;
    if (gpuDelegate) {
      if (Platform.isAndroid) {
        interpreterOptions.addDelegate(tfl.GpuDelegateV2());
      }
      if (Platform.isWindows) {
        _isGpuDelegate = false;
      }
    }

    final interpreter = await tfl.Interpreter.fromAsset(
      'assets/models/$modelName.tflite',
      options: interpreterOptions,
    );
    interpreter.allocateTensors();

    if (runIsolated) {
      _isolateInterpreter =
          await tfl.IsolateInterpreter.create(address: interpreter.address);
    } else {
      _isolateInterpreter = interpreter;
    }
    _isIsolated = runIsolated;

    if (kDebugMode) {
      print("Loaded Model: $modelName");
      print("RunIsolated: $_isIsolated | GpuDelegate: $_isGpuDelegate");
    }
  }

  static List<List<List<num>>> _imageToTensor(Map<String, dynamic> data) {
    Uint8List value = data['value'];
    final width = data['w'];
    final height = data['h'];
    final id = data['id'];

    imagelib.Image? image = imagelib.decodeImage(value);
    image = imagelib.copyResize(image!, width: width, height: height);

    if (kDebugMode) {
      print("MEAN: ${model.mean[id]}");
      print("STD: ${model.std[id]}");
    }

    final imageMatrix = List.generate(
      image.height,
      (y) => List.generate(image!.width, (x) {
        final pixel = image?.getPixel(x, y);
        var r = (pixel!.rNormalized - model.mean[id][0]) / model.std[id][0];
        var g = (pixel.gNormalized - model.mean[id][1]) / model.std[id][1];
        var b = (pixel.bNormalized - model.mean[id][2]) / model.std[id][2];
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

  Future<List<List<List<num>>>> imageToTensor(Uint8List value) async {
    final data = {
      'value': value,
      'w': _width,
      'h': _height,
      'id': _id,
    };
    if (_isIsolated) {
      return await compute(_imageToTensor, data);
    } else {
      return _imageToTensor(data);
    }
  }

  Future<List<double>> getImagePredictFromFile(File imageFile) async =>
      await getImagePredict(imageFile.readAsBytesSync());

  Future<List<double>> getImagePredict(Uint8List byteImage) async {
    _stopWatch.reset();
    _stopWatch.start();
    final imageTensor = await imageToTensor(byteImage);
    final input = [imageTensor];
    List output = List.filled(1 * 3, 0).reshape([1, 3]);

    await _isolateInterpreter.run(input, output);

    final outputSoftmax = softmax(output[0]);

    _stopWatch.stop();

    if (kDebugMode) {
      print("Input Shape: ${input.shape}");
      print("Output Shape: ${output.shape}");
      print("Output: $output");
      print("Softmax: $outputSoftmax");
    }

    return outputSoftmax;
  }

  String getImagePredictClassNames(List<double> yLogits) {
    return model.classNames[yLogits.indexOf(yLogits.reduce(max))];
  }

  static List<double> softmax(List<double> yLogits) {
    double maxVal = yLogits.reduce(max);
    List<double> expValues = yLogits.map((e) => exp(e - maxVal)).toList();
    double sumExp = expValues.reduce((value, element) => value + element);
    return expValues.map((e) => e / sumExp).toList();
  }

  Uint8List previewPreprocess(File imageFile) {
    imagelib.Image? image = imagelib.decodeImage(imageFile.readAsBytesSync());
    image = imagelib.copyResize(image!, width: _width, height: _height);

    if (kDebugMode) {
      print("MEAN: ${model.mean[_id]}");
      print("STD: ${model.std[_id]}");
    }

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        var r =
            (((pixel.rNormalized - model.mean[_id][0]) / model.std[_id][0]) *
                    255.0)
                .round()
                .clamp(0, 255);
        var g =
            (((pixel.gNormalized - model.mean[_id][1]) / model.std[_id][1]) *
                    255.0)
                .round()
                .clamp(0, 255);
        var b =
            (((pixel.bNormalized - model.mean[_id][2]) / model.std[_id][2]) *
                    255.0)
                .round()
                .clamp(0, 255);

        image.setPixel(x, y, imagelib.ColorFloat32.rgb(r, g, b));
      }
    }

    return imagelib.encodeJpg(image);
  }

  void close() {
    _isolateInterpreter.close();
  }
}
