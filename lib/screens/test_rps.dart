import 'dart:io';

import 'package:flutter_rps/widgets/error_dialog.dart';
import 'package:flutter_rps/utils/utils.dart' as utils;
import 'package:flutter/material.dart';
import 'package:flutter_rps/models/rps_model.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import "package:camera/camera.dart";
import 'package:flutter_rps/screens/test_camera.dart';
import 'package:flutter_rps/widgets/my_bottom_sheet.dart';
import 'package:flutter_rps/widgets/bounding_box.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late String dropDownModelValue;
  late final CacheManager cacheManager;

  final RpsModel _rpsModel = RpsModel();

  final _textURLController = TextEditingController();
  dynamic _imageWidgetPlotter;
  dynamic _tempImageWidgetPlotter;

  String _predResult = '. . .';
  String _predProbs = 'Pred Probs';
  String _predTime = '-';
  bool isInPreviewSTDMEAN = false;
  double _maxHeight = 0;
  double _maxWidth = 0;

  void resetPreviewSTDMEAN({bool? skipSetState}) {
    if (isInPreviewSTDMEAN) {
      _imageWidgetPlotter = _tempImageWidgetPlotter;
    }

    isInPreviewSTDMEAN = false;
    _tempImageWidgetPlotter = null;

    skipSetState ??= false;
    if (!skipSetState) {
      setState(() {});
    }
  }

  void _predictImage(File imgFile) async {
    _predProbs = '';
    final modelOutputs = await _rpsModel.getImagePredictFromFile(imgFile);
    _imageWidgetPlotter = utils.plotImage(imgFile);

    switch (EnumModelTypes.values.byName(_rpsModel.modelType)) {
      case EnumModelTypes.classification:
        List<double> predProbs = modelOutputs['predProbs'];
        for (int i = 0; i < predProbs.length; i++) {
          _predProbs +=
              "${_rpsModel.classNames[i]}: ${num.parse(predProbs[i].toStringAsFixed(3))}\n";
          _predResult = _rpsModel.getImagePredictClassNames(predProbs);
        }
        break;
      case EnumModelTypes.yolov5:
        _predResult = 'Detected:';
        final List<int> rpsFounds = modelOutputs['rpsFounds'];
        for (int i = 0; i < rpsFounds.length; i++) {
          _predProbs += "${_rpsModel.classNames[i]}: ${rpsFounds[i]}\n";
        }
        final List<List<double>> listBoxes = modelOutputs['boxes'];
        final List<List<double>> classIds = modelOutputs['classIds'];
        final imgWidhtHeight = utils.getImageWidthHeight(imgFile);

        final double resizeFactor = utils.resizeFactor(
            screenMaxWidth: _maxWidth,
            widgetMaxHeight: 200,
            imageWidth: imgWidhtHeight[0],
            imageHeight: imgWidhtHeight[1]);
        List<Widget> bBoxes = List.generate(
          listBoxes.length,
          (index) => BBox(
              x: listBoxes[index][0] * resizeFactor,
              y: listBoxes[index][1] * resizeFactor,
              width: listBoxes[index][2] * resizeFactor,
              height: listBoxes[index][3] * resizeFactor,
              label: _rpsModel.getImagePredictClassNames(classIds[index])),
        );
        _imageWidgetPlotter = utils.plotImage(
          imgFile,
          bBoxesWidget: bBoxes,
        );
        break;
      default:
    }

    _predTime = _rpsModel.totalExecutionTime;
    resetPreviewSTDMEAN(skipSetState: true);
    setState(() {});
  }

  Future<void> _loadModel({bool? gpuDelegate, bool? runIsolated}) async {
    gpuDelegate ??= _rpsModel.isGpuDelegate;
    runIsolated ??= _rpsModel.isIsolated;
    await _rpsModel
        .loadModel(
      dropDownModelValue,
      gpuDelegate: gpuDelegate,
      runIsolated: runIsolated,
    )
        .onError((error, stackTrace) {
      showDialog(
          context: context,
          builder: (context) =>
              ErrorDialog(error: error, stackTrace: stackTrace));
      _rpsModel.loadModel(dropDownModelValue, gpuDelegate: false);
    });
    resetPreviewSTDMEAN();

    if (!mounted) return;
    utils.showSnackBar(context, 'Loaded: $dropDownModelValue');
  }

  @override
  void initState() {
    super.initState();
    _imageWidgetPlotter = utils.plotImage(null);
    cacheManager = DefaultCacheManager();
    dropDownModelValue = _rpsModel.modelNames.first;
    _loadModel();
  }

  @override
  void dispose() {
    _rpsModel.close();
    cacheManager.emptyCache();
    cacheManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        _maxHeight = constraints.maxHeight;
        _maxWidth = constraints.maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            dropDownModels(),
            Expanded(child: predictResult(context)),
          ],
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: SpeedDial(
        icon: Icons.image,
        activeIcon: Icons.close,
        spacing: 3,
        childPadding: const EdgeInsets.all(3),
        spaceBetweenChildren: 15,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.file_open),
            onTap: predictFromFile,
            backgroundColor: Theme.of(context).secondaryHeaderColor,
            label: 'Open Image From File',
          ),
          SpeedDialChild(
            child: const Icon(Icons.web),
            onTap: () => predictFromUrl(context),
            backgroundColor: Theme.of(context).secondaryHeaderColor,
            label: 'Open Image From URL',
          ),
          SpeedDialChild(
            child: const Icon(Icons.camera),
            onTap: predictFromCamera,
            backgroundColor: Theme.of(context).secondaryHeaderColor,
            label: 'Camera',
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        height: 60,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Model Settings',
              onPressed: () {
                settingSheet(context);
              },
              icon: const Icon(Icons.settings),
            ),
            IconButton(
              tooltip: 'Re-Predict',
              onPressed: isInPreviewSTDMEAN
                  ? null
                  : () {
                      _predictImage(utils.imagePathFromImageProvider(
                          _imageWidgetPlotter.children[0].image));
                    },
              icon: const Icon(Icons.restart_alt_rounded),
            ),
            IconButton(
              tooltip: 'Preprocess Image Preview',
              onPressed: () {
                if (isInPreviewSTDMEAN) {
                  _imageWidgetPlotter = _tempImageWidgetPlotter;
                  isInPreviewSTDMEAN = false;
                } else {
                  _tempImageWidgetPlotter ??= _imageWidgetPlotter;
                  _imageWidgetPlotter = Image.memory(_rpsModel
                      .previewPreprocess(utils.imagePathFromImageProvider(
                          _imageWidgetPlotter.children[0].image)));
                  isInPreviewSTDMEAN = true;
                }
                setState(() {});
              },
              icon: const Icon(Icons.photo_filter),
            )
          ],
        ),
      ),
    );
  }

  Future<dynamic> settingSheet(BuildContext context) {
    return showMyBottomSheet(
        context: context,
        title: 'Options',
        dragSensitivity: _maxHeight,
        child: StatefulBuilder(
          builder: (context, setState) => Expanded(
            child: ListView(
              children: [
                Row(
                  children: [
                    Text('Isolated Interpreter',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Switch(
                      value: _rpsModel.isIsolated,
                      onChanged: (value) async {
                        await _loadModel(
                          runIsolated: value,
                        );
                        setState(() {});
                      },
                    )
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Gpu Delegate',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Switch(
                      value: _rpsModel.isGpuDelegate,
                      onChanged: (value) async {
                        await _loadModel(
                          gpuDelegate: value,
                        );
                        setState(() {});
                      },
                    )
                  ],
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Detection Confidence',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(_rpsModel.objConfidence.toStringAsFixed(6))
                      ],
                    ),
                    Slider(
                      min: RpsModel.objConfidenceMin,
                      max: RpsModel.objConfidenceMax,
                      label: _rpsModel.objConfidence.toStringAsFixed(3),
                      value: _rpsModel.objConfidence,
                      onChanged: (value) {
                        _rpsModel.setObjConfidence(value);
                        setState(() {});
                      },
                    )
                  ],
                )
              ],
            ),
          ),
        ));
  }

  Container dropDownModels() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButton(
          value: dropDownModelValue,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          iconSize: 30,
          underline: const SizedBox(),
          items: _rpsModel.modelNames.map((String value) {
            return DropdownMenuItem(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (value) {
            dropDownModelValue = value!;
            _loadModel().then((value) => setState(() {}));
          },
        ),
      ),
    );
  }

  void predictFromFile() {
    utils.pickFile().then((value) {
      if (value != null) {
        setState(() {
          _imageWidgetPlotter = utils.plotImage(File(''));
        });
        _predictImage(value);
      }
    });
  }

  Future<dynamic> predictFromUrl(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        icon: const Icon(Icons.image_outlined),
        title: const Text('Enter URL'),
        content: Container(
          constraints:
              const BoxConstraints(maxHeight: 500, minWidth: double.maxFinite),
          child: TextField(
            controller: _textURLController,
            maxLines: null,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Raw Image URL',
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () {
                setState(() {
                  _imageWidgetPlotter = utils.plotImage(File(''));
                });
                Navigator.of(context).pop();

                if (Uri.parse(_textURLController.text).isAbsolute) {
                  cacheManager.emptyCache();
                  cacheManager
                      .getSingleFile(_textURLController.text)
                      .then((value) {
                    _imageWidgetPlotter = utils.plotImage(value);
                    _predictImage(value);
                  }).onError(
                    (error, stackTrace) => showDialog(
                      context: context,
                      builder: (BuildContext context) => ErrorDialog(
                        error: error,
                        stackTrace: stackTrace,
                      ),
                    ),
                  );
                } else {
                  utils.showSnackBar(context, 'URL is not valid');
                }
              },
              child: const Text('Submit'))
        ],
      ),
    );
  }

  void predictFromCamera() async {
    final cameras = await availableCameras();
    if (!mounted) return;
    final results = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          camera: cameras.first,
          rpsModel: _rpsModel,
          screenMaxHeight: _maxHeight,
          screenMaxWidth: _maxWidth,
        ),
      ),
    );
    _imageWidgetPlotter = utils.plotImage(results);
    _predictImage(results);
  }

  Column predictResult(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 200,
          height: 200,
          child: _imageWidgetPlotter,
        ),
        const Text(
          'Pred Result:',
        ),
        Text(
          _predResult,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        Text(
          _predProbs,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text('Time Taken: $_predTime'),
      ],
    );
  }
}
