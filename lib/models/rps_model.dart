import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_rps/utils/utils.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as imagelib;
import 'package:flutter_rps/models/rps_models_constant.dart' as model;
import 'package:flutter_rps/models/classification.dart' as classification;
import 'package:flutter_rps/models/yolov5.dart' as yolov5;

enum EnumModelTypes { classification, yolov5 }

class RpsModel {
  List<String> get modelNames => model.modelNames;
  List<String> get classNames => model.classNames;
  String get modelType => model.modelTypes[_id];
  List<double> get mean => model.mean[_id];
  List<double> get std => model.std[_id];

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
  double _objConfidence = 0.5;
  double get objConfidence => _objConfidence;
  void setObjConfidence(double value) => _objConfidence = value;

  static final Stopwatch _stopWatch = Stopwatch();
  double _preprocessTime = 0;
  double _predictTime = 0;
  String get preprocessTime => _preprocessTime.toString();
  String get predictTime => _predictTime.toString();
  String get totalExecutionTime => (_predictTime + _predictTime).toString();

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
          tfl.Interpreter.fromAddress(_interpreterAddress);
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

  Future<List<double>> getImagePredictFromFile(File imageFile) async {
    _stopwatchResetStart();
    return await getImagePredict(
        [await imageToTensor(imageFile.readAsBytesSync())]);
  }

  Future<List<double>> getImagePredict(
    List<List<List<List<num>>>> input,
  ) async {
    _stopwatchResetStart();

    final outputLength =
        _outputShape.reduce((value, element) => value * element);
    List rawOutput = List.filled(outputLength, 0).reshape(_outputShape);

    await _isolateInterpreter.run(input, rawOutput);
    dynamic processedOutput;
    if (modelType == EnumModelTypes.classification.name) {
      processedOutput = classification.processModelOutput(rawOutput);
    } else if (modelType == EnumModelTypes.yolov5.name) {
      // yolov5.processModelOutput(rawOutput);
      processedOutput = yolov5.processModelOutput(rawOutput);
    }

    _predictTime = _stopwatchTimeit();

    if (kDebugMode) {
      print("Input Shape: ${input.shape}");
      print("Output Shape: ${rawOutput.shape}");
      print("Output: $rawOutput");
      print("Output Processed: $processedOutput");
    }

    return processedOutput;
  }

  String getImagePredictClassNames(List<double> yLogits) {
    return model.classNames[yLogits.indexOf(yLogits.reduce(max))];
  }

  Future<List<double>> cameraStreamPredict(CameraImage image) async {
    final data = {
      'cameraImage': image,
      'id': _id,
      'width': _width,
      'height': _height,
      'interpreterAddress': _interpreterAddress,
      'outputShape': _outputShape,
    };
    final dataOutput = await compute(_cameraStreamPredict, data);
    _preprocessTime = dataOutput['timerImage'];
    _predictTime = dataOutput['timerPredict'];
    return dataOutput['output'];
  }

  static Map<String, dynamic> _cameraStreamPredict(Map<String, dynamic> data) {
    _stopwatchResetStart();
    Map<String, dynamic> toSendBackData = {};
    // getYUVFromPlanes
    CameraImage availableImage = data['cameraImage'];
    List<Uint8List> planes = Utils.processGetYUVFromPlanes(data);

    // yuv420ToJpg
    final img = Utils.processyuv420ToJpg({
      'planes': planes,
      'width': availableImage.width,
      'height': availableImage.height
    });

    int id = data['id'];
    int width = data['width'];
    int height = data['height'];

    final input = [
      _imageToTensor(
          {'value': img[0], 'width': width, 'height': height, 'id': id})
    ];
    toSendBackData['timerImage'] = _stopwatchTimeit();

    _stopwatchResetStart();
    final List<int> outputShape = data['outputShape'];
    final outputLength =
        outputShape.reduce((value, element) => value * element);
    List output = List.filled(outputLength, 0).reshape(outputShape);
    tfl.Interpreter interpreter =
        tfl.Interpreter.fromAddress(data['interpreterAddress']);
    interpreter.run(input, output);

    dynamic processedOutput;
    if (model.modelTypes[id] == EnumModelTypes.classification.name) {
      processedOutput = classification.processModelOutput(output);
    }
    toSendBackData['output'] = processedOutput;

    _stopWatch.stop();
    toSendBackData['timerPredict'] = _stopwatchTimeit();
    return toSendBackData;
  }

  Future<List<List<List<num>>>> imageToTensor(Uint8List value) async {
    final data = {
      'value': value,
      'width': _width,
      'height': _height,
      'id': _id,
    };
    if (_isIsolated) {
      return await compute(_imageToTensor, data);
    } else {
      return _imageToTensor(data);
    }
  }

  static List<List<List<num>>> _imageToTensor(Map<String, dynamic> data) {
    Uint8List value = data['value'];
    final width = data['width'];
    final height = data['height'];
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

  static void _stopwatchResetStart() {
    _stopWatch.reset();
    _stopWatch.start();
  }

  static double _stopwatchTimeit() {
    _stopWatch.stop();
    return double.parse(_stopWatch.elapsed.toString().substring(5));
  }
}
