import 'package:flutter/foundation.dart';

void processModelOutput(List<dynamic> output) {
  for (var bbox in output) {
    // Extract bounding box coordinates
    var xCenter = bbox[0];
    var yCenter = bbox[1];
    var width = bbox[2];
    var height = bbox[3];

    // Extract confidence score
    var confidence = bbox[4];

    // Extract class probability scores
    var classProbs = bbox.sublist(5);

    if (kDebugMode) {
      print(
          "Bounding Box Coordinates (x_center, y_center, width, height): $xCenter, $yCenter, $width, $height");
      print("Confidence Score: $confidence");
      print("Class Probability Scores: $classProbs");
    }
  }
}
