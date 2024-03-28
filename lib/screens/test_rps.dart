import 'dart:io';

import 'package:flutter_rps/widgets/error_dialog.dart';
import 'package:flutter_rps/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rps/models/rps_model.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import "package:camera/camera.dart";
import 'package:flutter_rps/screens/test_camera.dart';
import 'package:flutter_rps/widgets/my_bottom_sheet.dart';

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

  Future<void> _predictImage(File imgFile) async {
    List<double> predProbs = await _rpsModel.getImagePredictFromFile(imgFile);
    _predProbs = '';
    for (var i = 0; i < predProbs.length; i++) {
      _predProbs +=
          "${_rpsModel.classNames[i]}: ${num.parse(predProbs[i].toStringAsExponential(3))}\n";
    }
    _predResult = _rpsModel.getImagePredictClassNames(predProbs);
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
    Utils.showSnackBar(context, 'Loaded: $dropDownModelValue');
  }

  @override
  void initState() {
    super.initState();
    _imageWidgetPlotter = Utils.plotImage(null);
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
                      _predictImage(Utils.imagePathFromImageProvider(
                          _imageWidgetPlotter.image));
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
                      .previewPreprocess(Utils.imagePathFromImageProvider(
                          _imageWidgetPlotter.image)));
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
          builder: (context, setState) => Column(
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
              )
            ],
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
    Utils.pickFile().then((value) {
      if (value != null) {
        _imageWidgetPlotter = Utils.plotImage(value);
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
                  _imageWidgetPlotter = Utils.plotImage(File(''));
                });
                Navigator.of(context).pop();

                if (Uri.parse(_textURLController.text).isAbsolute) {
                  cacheManager.emptyCache();
                  cacheManager
                      .getSingleFile(_textURLController.text)
                      .then((value) {
                    _imageWidgetPlotter = Utils.plotImage(value);
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
                  Utils.showSnackBar(context, 'URL is not valid');
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
        ),
      ),
    );
    _imageWidgetPlotter = Utils.plotImage(results);
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
