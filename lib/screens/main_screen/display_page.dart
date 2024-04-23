import 'dart:io';

import 'package:flutter/foundation.dart';
import "package:flutter/material.dart";
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_rps/widgets/bounding_box.dart';

import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:flutter_rps/widgets/svg_icons.dart' as svg_icons;

import 'package:flutter_rps/models/rps_model.dart';
import 'package:flutter_rps/utils/utils.dart' as utils;
import 'dart:math' as math;

enum DisplayPages { pictureImage, donwloadImage }

class DisplayPage extends StatefulWidget {
  const DisplayPage({
    super.key,
    required this.rpsModel,
    required this.displayPageMode,
    this.switchCoverNDisplay,
    required this.cacheManager,
  });

  final RpsModel rpsModel;
  final DisplayPages displayPageMode;
  final void Function()? switchCoverNDisplay;
  final CacheManager cacheManager;

  @override
  State<DisplayPage> createState() => DisplayPageState();
}

class DisplayPageState extends State<DisplayPage> {
  bool _showResultDetails = false;
  bool isInPreviewSTDMEAN = false;
  List<double> _predProbs = List.filled(3, -1);
  String _predResult = '---';
  void _predictImage(File imgFile) async {
    final modelOutputs = await widget.rpsModel.getImagePredictFromFile(imgFile);

    switch (EnumModelTypes.values.byName(widget.rpsModel.modelType)) {
      case EnumModelTypes.classification:
        _predProbs = modelOutputs['predProbs'];
        _predResult = widget.rpsModel.getImagePredictClassNames(_predProbs);
        break;
      case EnumModelTypes.yolov5:
        if (!mounted) {
          return;
        }

        int tmp = 0;
        _predResult = '---';
        for (int i = 0; i < _predProbs.length; i++) {
          int x = modelOutputs['rpsFounds'][i];
          _predProbs[i] = x.toDouble();
          if (tmp < x) {
            tmp = x;
            _predResult = widget.rpsModel.classNames[i];
          }
        }

        final List<List<double>> listBoxes = modelOutputs['boxes'];
        final List<List<double>> classIds = modelOutputs['classIds'];

        final imgWidhtHeight = utils.getImageWidthHeight(imgFile);

        final double resizeFactor = utils.resizeFactor(
            screenMaxWidth: MediaQuery.of(context).size.width,
            widgetMaxHeight: 300,
            imageWidth: imgWidhtHeight[0],
            imageHeight: imgWidhtHeight[1]);

        if (kDebugMode) {
          print("resizeFactor: $resizeFactor");
        }

        List<Widget> bBoxes = List.generate(
          listBoxes.length,
          (index) {
            final double left =
                math.min(listBoxes[index][0], listBoxes[index][2]) *
                    resizeFactor;
            final double top =
                math.min(listBoxes[index][1], listBoxes[index][3]) *
                    resizeFactor;
            final double right =
                math.max(listBoxes[index][0], listBoxes[index][2]) *
                    resizeFactor;
            final double bottom =
                math.max(listBoxes[index][1], listBoxes[index][3]) *
                    resizeFactor;
            return BBox(
                left: left,
                top: top,
                width: right - left,
                height: bottom - top,
                label:
                    widget.rpsModel.getImagePredictClassNames(classIds[index]));
          },
        );
        imagePlotter = utils.plotImage(imgFile, bBoxesWidget: bBoxes);
        break;
      default:
    }
    setState(() {});
  }

  late Widget imagePlotter;
  Widget? _tempImagePlotter;
  late Future<void> _plotImageFutere;
  Future<File?> _plotImage(Future<File?> Function() func) async {
    File? file = await func();
    if (file != null) {
    } else {
      widget.switchCoverNDisplay!();
    }

    imagePlotter = utils.plotImage(file);
    setState(() {});
    return file;
  }

  void plotInit() {
    File? imgFile;
    switch (widget.displayPageMode) {
      case DisplayPages.pictureImage:
        _plotImageFutere =
            _plotImage(utils.pickFile).then((value) => imgFile = value);
        break;
      case DisplayPages.donwloadImage:
        break;
      default:
    }

    _predResult = 'Predicting . . .';
    _plotImageFutere.whenComplete(
      () {
        _predictImage(imgFile!);
      },
    );
  }

  @override
  void initState() {
    plotInit();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _plotImageFutere,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox();
        }
        return Column(
          children: [
            const Spacer(flex: 10),
            Expanded(
              flex: _showResultDetails ? 350 : 50,
              child: Container(
                clipBehavior: Clip.hardEdge,
                width: double.infinity,
                // height: MediaQuery.of(context).size.height * 2 / 5,
                alignment: Alignment.topCenter,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 3 / 11,
                      decoration: BoxDecoration(boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 6,
                          blurRadius: 5,
                        )
                      ]),
                      child: imagePlotter,
                    ),
                    _showResultDetails
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10))
                        : const Spacer(),
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: () {
                          _showResultDetails = !_showResultDetails;
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          color: Colors.white,
                          width: double.infinity,
                          child: listDetailsResult(context),
                        ),
                      ),
                    ),
                    _showResultDetails
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 0))
                        : const Spacer(),
                  ],
                ),
              ),
            ),
            const Spacer(flex: 4),
            buttonMenu(),
            const Spacer(flex: 10),
          ],
        );
      },
    );
  }

  Visibility buttonMenu() {
    return Visibility(
      visible: !_showResultDetails,
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
            ),
            onPressed: () => _predictImage(
              utils.imagePathFromImageProvider(
                  utils.getImageProviderFromPlotImage(imagePlotter)),
            ),
            child: const Row(
              children: [
                Iconify(
                  svg_icons.predictions,
                  color: Colors.white,
                ),
                Padding(padding: EdgeInsets.symmetric(horizontal: 4.0)),
                Text(
                  'Re-Predict',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
            ),
            onPressed: () {
              if (isInPreviewSTDMEAN) {
                imagePlotter = _tempImagePlotter!;
              } else {
                _tempImagePlotter ??= imagePlotter;
                imagePlotter = Image.memory(
                  widget.rpsModel
                      .previewPreprocess(utils.imagePathFromImageProvider(
                    utils.getImageProviderFromPlotImage(imagePlotter),
                  )),
                );
              }
              isInPreviewSTDMEAN = !isInPreviewSTDMEAN;
              setState(() {});
            },
            child: const Row(
              children: [
                Icon(
                  Icons.preview_outlined,
                  color: Colors.white,
                ),
                Padding(padding: EdgeInsets.symmetric(horizontal: 4.0)),
                Text(
                  'Preprocess Image',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
            ),
            onPressed: plotInit,
            child: const Row(
              children: [
                Iconify(
                  svg_icons.imageFile,
                  color: Colors.white,
                ),
                Padding(padding: EdgeInsets.symmetric(horizontal: 4.0)),
                Text(
                  'Choose another Image',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  ListView listDetailsResult(BuildContext context) {
    return ListView(
      physics: _showResultDetails
          ? const ScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      children: [
        Column(
          children: [
            Text(
              _predResult,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Pred Time: ${widget.rpsModel.totalExecutionTime}s',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w100,
              ),
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 8)),
            Visibility(
              visible: _showResultDetails,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  gridProbs(context),
                  Wrap(
                    spacing: double.infinity,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      const Text(
                        '[r, g, b] Preprocess Mean',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(widget.rpsModel.modelMean.toString())
                    ],
                  ),
                  Wrap(
                    spacing: double.infinity,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      const Text(
                        '[r, g, b] Preprocess Std',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(widget.rpsModel.modelSTD.toString())
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Preprocess time',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text('${widget.rpsModel.preprocessTime} Secs')
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Predict time',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text('${widget.rpsModel.predictTime} Secs')
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Output time',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text('${widget.rpsModel.outputProcessTime} Secs')
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Model Name',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(widget.rpsModel.currentModel)
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Gpu Delegate',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(widget.rpsModel.isGpuDelegate ? 'YES' : 'NO')
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  GridView gridProbs(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      childAspectRatio: 2,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      children: List.generate(
        3,
        (index) => Column(
          children: [
            Text(
              widget.rpsModel.classNames[index],
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text((_predProbs[0] < 0)
                ? '--'
                : '${num.parse(_predProbs[index].toStringAsFixed(3))}')
          ],
        ),
      ),
    );
  }
}
