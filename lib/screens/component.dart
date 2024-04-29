import 'package:flutter/material.dart';
import 'package:flutter_rps/models/rps_model.dart';

GridView gridProbs(
    BuildContext context, RpsModel rpsModel, List<double> predProbs,
    {Color? textColor}) {
  return GridView.count(
    padding: const EdgeInsets.all(0),
    shrinkWrap: true,
    childAspectRatio: 2,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 3,
    children: List.generate(
      3,
      (index) => Column(
        children: [
          Text(
            rpsModel.classNames[index],
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold, color: textColor),
          ),
          Text(
            (predProbs[0] < 0)
                ? '--'
                : '${num.parse(predProbs[index].toStringAsFixed(3))}',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: textColor),
          )
        ],
      ),
    ),
  );
}

Column resultDetails(
    BuildContext context, RpsModel rpsModel, List<double> predProbs) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      gridProbs(context, rpsModel, predProbs),
      Wrap(
        spacing: double.infinity,
        alignment: WrapAlignment.spaceBetween,
        children: [
          const Text(
            '[r, g, b] Preprocess Mean',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(rpsModel.modelMean.toString())
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
          Text(rpsModel.modelSTD.toString())
        ],
      ),
      Row(
        children: [
          const Text(
            'Preprocess time',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text('${rpsModel.preprocessTime} Secs')
        ],
      ),
      Row(
        children: [
          const Text(
            'Predict time',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text('${rpsModel.predictTime} Secs')
        ],
      ),
      Row(
        children: [
          const Text(
            'Output time',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text('${rpsModel.outputProcessTime} Secs')
        ],
      ),
      Row(
        children: [
          const Text(
            'Model Name',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(rpsModel.currentModel)
        ],
      ),
      Row(
        children: [
          const Text(
            'Gpu Delegate',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(rpsModel.isGpuDelegate ? 'YES' : 'NO')
        ],
      ),
    ],
  );
}
