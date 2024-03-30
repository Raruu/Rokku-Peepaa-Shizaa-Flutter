import 'package:flutter/foundation.dart';

// Model Output: [1, 25200, 8]
// https://github.com/ultralytics/yolov5/issues/5304
// https://github.com/ultralytics/ultralytics/issues/6890

List<double> processModelOutput(List<dynamic> rawOutput,
    {double confidenceMin = 0.35}) {
  List boxes;
  List confidences;
  List<List<double>> classIds;
  (boxes, confidences, classIds) = decodeRawOutputs(rawOutput);

  return classIds[0];
}

(List boxes, List confidences, List<List<double>> classIds) decodeRawOutputs(
    List<dynamic> rawOutput,
    {double confidenceMin = 0.35}) {
  List boxes = [];
  List confidences = [];
  List<List<double>> classIds = [];
  for (int i = 0; i < rawOutput[0].length; i++) {
    final confidence = rawOutput[0][i][4];
    if (confidence > confidenceMin) {
      List box = [];
      box.add(rawOutput[0][i][0]);
      box.add(rawOutput[0][i][1]);
      box.add(rawOutput[0][i][2]);
      box.add(rawOutput[0][i][3]);
      boxes.add(box);

      confidences.add(confidence);

      List<double> classId = [];
      classId.add(rawOutput[0][i][5]);
      classId.add(rawOutput[0][i][6]);
      classId.add(rawOutput[0][i][7]);
      classIds.add(classId);
    }
  }
  if (kDebugMode) {
    for (var i = 0; i < confidences.length; i++) {
      print("Box ID: ${boxes[i]}");
      // print("Class ID: ${classIds[i]}");
    }
  }
  return (boxes, confidences, classIds);
  // Map<String, dynamic>
  // return {
  //   'boxes': boxes,
  //   'confidences': confidences,
  //   'classIds': classIds,
  // };
}

// (List boxes, List confidences, List classIds) decodeRawOutputs(
//     List<dynamic> rawOutput,
//     {double confidenceMin = 0.35}) {
//   List boxes = [];
//   List confidences = [];
//   List classIds = [];
//   for (int i = 0; i < rawOutput[0].length; i++) {
//     final confidence = rawOutput[0][i][4];
//     if (confidence > confidenceMin) {
//       List box = [];
//       box.add(rawOutput[0][i][0]);
//       box.add(rawOutput[0][i][1]);
//       box.add(rawOutput[0][i][2]);
//       box.add(rawOutput[0][i][3]);
//       boxes.add(box);

//       confidences.add(confidence);

//       List classId = [];
//       classId.add(rawOutput[0][i][5]);
//       classId.add(rawOutput[0][i][6]);
//       classId.add(rawOutput[0][i][7]);
//       classIds.add(classId);
//     }
//   }
//   if (kDebugMode) {
//     for (var i = 0; i < confidences.length; i++) {
//       print("Box ID: ${boxes[i]}");
//       // print("Class ID: ${classIds[i]}");
//     }
//   }
//   return (boxes, confidences, classIds);
//   // Map<String, dynamic>
//   // return {
//   //   'boxes': boxes,
//   //   'confidences': confidences,
//   //   'classIds': classIds,
//   // };
// }