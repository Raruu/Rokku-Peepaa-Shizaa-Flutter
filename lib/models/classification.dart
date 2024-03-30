import 'dart:math';

List<double> _softmax(List<double> yLogits) {
  double maxVal = yLogits.reduce(max);
  List<double> expValues = yLogits.map((e) => exp(e - maxVal)).toList();
  double sumExp = expValues.reduce((value, element) => value + element);
  return expValues.map((e) => e / sumExp).toList();
}

List<double> processModelOutput(List<dynamic> rawOutput) {
  return _softmax(rawOutput[0]);
}
