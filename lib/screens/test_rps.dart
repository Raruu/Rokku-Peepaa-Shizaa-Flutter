import 'dart:io';

import 'package:flutter_rps/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rps/models/rps_model.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import "package:camera/camera.dart";
import 'package:flutter_rps/screens/camera.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final CacheManager cacheManager;
  final RpsModel _rpsModel = RpsModel();

  final _textURLController = TextEditingController();
  dynamic _imageWidgetPlotter;

  String _predResult = '. . .';
  String _yLogits = 'Logits';
  String _predTime = '-';

  void _predictImage(File imgFile) {
    List<double> yLogits = _rpsModel.getImagePredictLogits(imgFile)[0];
    _yLogits = '';
    for (var i = 0; i < yLogits.length; i++) {
      _yLogits +=
          "${_rpsModel.classNames[i]}: ${yLogits[i].toStringAsExponential(3)}\n";
    }
    _predResult = _rpsModel.getImagePredictClassNames(yLogits);
    _predTime = _rpsModel.executionTime;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _imageWidgetPlotter = Utils.plotImage(null);
    cacheManager = DefaultCacheManager();
  }

  @override
  void dispose() {
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
      body: Center(
        child: predictResult(context),
      ),
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
            onTap: () async {
              final cameras = await availableCameras();
              if (!context.mounted) return;
              final results = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CameraScreen(camera: cameras.first),
                ),
              );
              _imageWidgetPlotter = Utils.plotImage(results);
              _predictImage(results);
            },
            backgroundColor: Theme.of(context).secondaryHeaderColor,
            label: 'Take Image',
          ),
        ],
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
                  });
                } else {
                  const snackBar = SnackBar(
                    duration: Durations.extralong4,
                    content: Text('URL is not valid'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                }
              },
              child: const Text('Submit'))
        ],
      ),
    );
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
          'PyTorch Pred Result:',
        ),
        Text(
          _predResult,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        Text(
          _yLogits,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text('Time Taken: $_predTime'),
      ],
    );
  }
}
