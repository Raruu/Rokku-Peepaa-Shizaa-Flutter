import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_rps/utils/utils.dart' as utils;
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as imagelib;
import 'package:flutter_rps/models/rps_models_constant.dart' as model;
import 'package:flutter_rps/models/classification.dart' as classification;
import 'package:flutter_rps/models/yolov5.dart' as yolov5;

enum EnumModelTypes { classification, yolov5 }

class RpsModel {
  List<String> get modelNames => model.modelNames;
  List<String> get classNames => model.classNames;
  List<List<double>> get modelMeanAvailable => model.mean.toSet().toList();
  List<List<double>> get modelStdAvailable => model.std.toSet().toList();
  String get modelType => model.modelTypes[_id];

  String get currentModel => model.modelNames[_id];

  // ignore: prefer_typing_uninitialized_variables
  late var _isolateInterpreter;
  late int _interpreterAddress;
  late List<int> _inputShape;
  late List<int> _outputShape;
  late bool _isIsolated;
  late bool _isGpuDelegate;
  bool get isIsolated => _isIsolated;
  bool get isGpuDelegate => _isGpuDelegate;

  int _id = 0;
  int get modelId => _id;
  int _width = 0;
  int _height = 0;

  bool _useCustomMean = false;
  bool get useCustomMean => _useCustomMean;
  List<double> _customMean = [0, 0, 0];
  List<double> get modelMean => _useCustomMean ? _customMean : model.mean[_id];

  bool _useCustomSTD = false;
  bool get useCustomSTD => _useCustomSTD;
  List<double> _customSTD = [1, 1, 1];
  List<double> get modelSTD => _useCustomSTD ? _customSTD : model.std[_id];

  double _objConfidence = 0.5;
  double get objConfidence => _objConfidence;
  void setObjConfidence(double value) => _objConfidence = value;
  static const double objConfidenceMin = 0.1;
  static const double objConfidenceMax = 1.0;

  static final Stopwatch _stopWatch = Stopwatch();
  double _preprocessTime = 0;
  double _predictTime = 0;
  double _outputProcessTime = 0;
  String get preprocessTime => _preprocessTime.toString();
  String get predictTime => _predictTime.toString();
  String get outputProcessTime => _outputProcessTime.toString();
  String get totalExecutionTime =>
      (_preprocessTime + _predictTime + _outputProcessTime).toStringAsFixed(5);

  RpsModel({bool gpuDelegate = true, bool runIsolated = true}) {
    _isGpuDelegate = gpuDelegate;
    _isIsolated = runIsolated;
  }

  Future<void> loadModel(String modelName,
      {bool? gpuDelegate, bool? runIsolated}) async {
    gpuDelegate ??= _isGpuDelegate;
    runIsolated ??= _isIsolated;

    // try to free memory when loading another model
    //
    try {
      tfl.Interpreter pastInterpreter =
          tfl.Interpreter.fromAddress(_interpreterAddress);
      pastInterpreter.close();
      if (isIsolated) {
        _isolateInterpreter.close();
      }
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
    _inputShape = interpreter.getInputTensor(0).shape;
    _outputShape = interpreter.getOutputTensor(0).shape;
    _interpreterAddress = interpreter.address;
    _width = _inputShape[2];
    _height = _inputShape[3];

    if (runIsolated) {
      _isolateInterpreter =
          await tfl.IsolateInterpreter.create(address: interpreter.address);
    } else {
      _isolateInterpreter = interpreter;
    }
    _isIsolated = runIsolated;

    if (kDebugMode) {
      print("Model Input: $_inputShape");
      print("Model Output: $_outputShape");
      print("Loaded Model: $modelName");
      print("RunIsolated: $_isIsolated | GpuDelegate: $_isGpuDelegate");
    }
  }

  Future<Map<String, dynamic>> getImagePredictFromFile(File imageFile) async {
    _stopwatchResetStart();
    return await getImagePredict(
        [await imageToTensor(imageFile.readAsBytesSync())]);
  }

  Future<Map<String, dynamic>> getImagePredict(
      List<List<List<List<num>>>> input) async {
    Map<String, dynamic> toReturnData = {};
    _stopwatchResetStart();

    final outputLength =
        _outputShape.reduce((value, element) => value * element);
    List rawOutput = List.filled(outputLength, 0).reshape(_outputShape);

    await _isolateInterpreter.run(input, rawOutput);
    _stopWatch.stop();
    _predictTime = _stopwatchTimeit();

    _stopwatchResetStart();
    toReturnData = processRawOutput(rawOutput, modelType,
        detectionConfidenceMin: _objConfidence);
    _stopWatch.stop();
    _outputProcessTime = _stopwatchTimeit();

    if (kDebugMode) {
      print("Input Shape: ${input.shape}");
      print("Output Shape: ${rawOutput.shape}");
      print("Output: $rawOutput");
      // print("Output Processed: $processedOutput");
    }

    return toReturnData;
  }

  static Map<String, dynamic> processRawOutput(List rawOutput, String modelType,
      {double detectionConfidenceMin = 0.5}) {
    Map<String, dynamic> toReturnData = {};

    switch (EnumModelTypes.values.byName(modelType)) {
      case EnumModelTypes.classification:
        toReturnData['predProbs'] =
            classification.processModelOutput(rawOutput);
        break;
      case EnumModelTypes.yolov5:
        List<int> rpsFound = List.filled(3, 0);
        final processedOutput = yolov5.decodeRawOutputs(rawOutput,
            confidenceMin: detectionConfidenceMin);
        for (var element in processedOutput.$3) {
          rpsFound[element.indexOf(element.reduce(math.max))] += 1;
        }

        toReturnData['boxes'] = processedOutput.$1;
        toReturnData['confidences'] = processedOutput.$2;
        toReturnData['classIds'] = processedOutput.$3;
        toReturnData['rpsFounds'] = rpsFound;
        break;
      default:
        throw Exception("ModelType Not in Enum");
    }

    return toReturnData;
  }

  String getImagePredictClassNames(List<double> yLogits) {
    return model.classNames[yLogits.indexOf(yLogits.reduce(math.max))];
  }

  Future<Map<String, dynamic>> cameraStreamPredict(CameraImage image) async {
    final data = {
      'cameraImage': image,
      'id': _id,
      'width': _width,
      'height': _height,
      'interpreterAddress': _interpreterAddress,
      'outputShape': _outputShape,
      'modelType': modelType,
      'objConfidence': _objConfidence,
      'mean': modelMean,
      'std': modelSTD,
    };
    final dataOutput = await compute(_cameraStreamPredict, data);
    _preprocessTime = dataOutput['timerImage'];
    _predictTime = dataOutput['timerPredict'];
    _outputProcessTime = dataOutput['timerOutput'];
    return dataOutput['output'];
  }

  static Map<String, dynamic> _cameraStreamPredict(Map<String, dynamic> data) {
    _stopwatchResetStart();
    Map<String, dynamic> toSendBackData = {};
    // getYUVFromPlanes
    CameraImage availableImage = data['cameraImage'];
    List<Uint8List> planes = utils.processGetYUVFromPlanes(data);

    // yuv420ToJpg
    final img = utils.processyuv420ToJpg({
      'planes': planes,
      'width': availableImage.width,
      'height': availableImage.height
    });

    int id = data['id'];
    int width = data['width'];
    int height = data['height'];

    final input = [
      _imageToTensor({
        'value': img[0],
        'width': width,
        'height': height,
        'id': id,
        'mean': data['mean'],
        'std': data['std'],
      })
    ];
    toSendBackData['timerImage'] = _stopwatchTimeit();

    _stopwatchResetStart();
    final List<int> outputShape = data['outputShape'];
    final outputLength =
        outputShape.reduce((value, element) => value * element);
    List rawOutput = List.filled(outputLength, 0).reshape(outputShape);
    tfl.Interpreter interpreter =
        tfl.Interpreter.fromAddress(data['interpreterAddress']);
    interpreter.run(input, rawOutput);
    _stopWatch.stop();
    toSendBackData['timerPredict'] = _stopwatchTimeit();

    _stopwatchResetStart();
    toSendBackData['output'] = processRawOutput(
      rawOutput,
      data['modelType'],
      detectionConfidenceMin: data['objConfidence'],
    );
    _stopWatch.stop();
    toSendBackData['timerOutput'] = _stopwatchTimeit();

    return toSendBackData;
  }

  Future<List<List<List<num>>>> imageToTensor(Uint8List value) async {
    _stopwatchResetStart();
    final data = {
      'value': value,
      'width': _width,
      'height': _height,
      // 'id': _id,
      'mean': modelMean,
      'std': modelSTD,
    };

    final List<List<List<num>>> results;

    if (_isIsolated) {
      results = await compute(_imageToTensor, data);
    } else {
      results = _imageToTensor(data);
    }
    _preprocessTime = _stopwatchTimeit();
    return results;
  }

  static List<List<List<num>>> _imageToTensor(Map<String, dynamic> data) {
    Uint8List value = data['value'];
    final width = data['width'];
    final height = data['height'];
    // final id = data['id'];
    final mean = data['mean'];
    final std = data['std'];

    imagelib.Image? image = imagelib.decodeImage(value);
    image = imagelib.copyResize(image!, width: width, height: height);

    if (kDebugMode) {
      print("MEAN: $mean");
      print("STD: $std");
    }

    final imageMatrix = List.generate(
      image.height,
      (y) => List.generate(image!.width, (x) {
        final pixel = image?.getPixel(x, y);
        var r = (pixel!.rNormalized - mean[0]) / std[0];
        var g = (pixel.gNormalized - mean[1]) / std[1];
        var b = (pixel.bNormalized - mean[2]) / std[2];
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

  Uint8List previewPreprocess(File imageFile) {
    imagelib.Image? image = imagelib.decodeImage(imageFile.readAsBytesSync());
    image = imagelib.copyResize(image!, width: _width, height: _height);

    if (kDebugMode) {
      print("MEAN: $modelMean");
      print("STD: $modelSTD");
    }

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        var r = (((pixel.rNormalized - modelMean[0]) / modelSTD[0]) * 255.0)
            .round()
            .clamp(0, 255);
        var g = (((pixel.gNormalized - modelMean[1]) / modelSTD[1]) * 255.0)
            .round()
            .clamp(0, 255);
        var b = (((pixel.bNormalized - modelMean[2]) / modelSTD[2]) * 255.0)
            .round()
            .clamp(0, 255);

        image.setPixel(x, y, imagelib.ColorFloat32.rgb(r, g, b));
      }
    }

    return imagelib.encodeJpg(image);
  }

  void setCustomMean({required bool enabled, List<double>? mean}) {
    _useCustomMean = enabled;
    if (mean != null) {
      _customMean = mean;
      if (kDebugMode) {
        print("Set Mean to: $mean");
      }
    }
  }

  void setCustomSTD({required bool enabled, List<double>? std}) {
    _useCustomSTD = enabled;
    if (std != null) {
      _customSTD = std;
      if (kDebugMode) {
        print("Set STD to: $std");
      }
    }
  }

  void close() {
    _isolateInterpreter.close();
  }

  static void _stopwatchResetStart() {
    _stopWatch.reset();
    _stopWatch.start();
  }

  static double _stopwatchTimeit() {
    _stopWatch.stop();
    return double.parse(_stopWatch.elapsed.toString().substring(5));
  }
}
