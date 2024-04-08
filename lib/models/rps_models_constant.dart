const List<String> classNames = [
  'paper',
  'rock',
  'scissors',
];

const List<String> modelNames = [
  'model_V1',
  'RPS2_Trans_V3_NoGrad_5Ep',
  'RPS3_yolov5s',
  'RPSHello_yolov5s',
];

const List<String> modelTypes = [
  'classification',
  'classification',
  'yolov5',
  'yolov5',
];

const List<List<double>> mean = [
  [0.485, 0.456, 0.406],
  [0.1222, 0.1387, 0.1135],
  [0, 0, 0],
  [0, 0, 0],
];

const List<List<double>> std = [
  [0.229, 0.224, 0.225],
  [0.2518, 0.2518, 0.2518],
  [1, 1, 1],
  [1, 1, 1],
];
