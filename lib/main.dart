import 'package:flutter/material.dart';
import 'package:flutter_rps/screens/test_rps.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MaterialApp(
    title: 'RPS Flutter',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      useMaterial3: true,
    ),
    home: const MyHomePage(
      title: 'Rock Paper Scissor',
    ),
  ));
}
