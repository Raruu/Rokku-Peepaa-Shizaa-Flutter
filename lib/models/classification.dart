import 'dart:math' as math;

List<double> _softmax(List<double> yLogits) {
  double maxVal = yLogits.reduce(math.max);
  List<double> expValues = yLogits.map((e) => math.exp(e - maxVal)).toList();
  double sumExp = expValues.reduce((value, element) => value + element);
  return expValues.map((e) => e / sumExp).toList();
}

List<double> processModelOutput(List<dynamic> rawOutput) {
  return _softmax(rawOutput[0]);
}
