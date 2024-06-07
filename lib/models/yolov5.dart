import 'dart:math' as math;

// Model Output: [1, 25200, 8]
// https://github.com/ultralytics/yolov5/issues/5304
// https://github.com/ultralytics/ultralytics/issues/6890

(
  List<List<double>> boxes,
  List<double> confidences,
  List<List<double>> classIds
) decodeRawOutputs(List<dynamic> rawOutput, {double confidenceMin = 0.35}) {
  List<List<double>> boxes = [];
  List<double> confidences = [];
  List<List<double>> classIds = [];
  for (int i = 0; i < rawOutput[0].length; i++) {
    final confidence = rawOutput[0][i][4];
    if (confidence > confidenceMin) {
      List<double> box = [];
      box.add(rawOutput[0][i][0]);
      box.add(rawOutput[0][i][1]);
      box.add(rawOutput[0][i][2]);
      box.add(rawOutput[0][i][3]);
      // boxes.add(_xywh2xyxy(box));
      boxes.add(box);

      confidences.add(confidence);

      List<double> classId = [];
      classId.add(rawOutput[0][i][5]);
      classId.add(rawOutput[0][i][6]);
      classId.add(rawOutput[0][i][7]);
      classIds.add(classId);
    }
  }

  return (boxes, confidences, classIds);
}

// List<double> _xywh2xyxy(List<double> bbox) {
//   double halfWidth = bbox[2] / 2;
//   double halfHeight = bbox[3] / 2;
//   return [
//     bbox[0] - halfWidth,
//     bbox[1] - halfHeight,
//     bbox[0] + halfWidth,
//     bbox[1] + halfHeight,
//   ];
// }

double sigmoid(double x) => 1 / (1 + math.exp(-x));
