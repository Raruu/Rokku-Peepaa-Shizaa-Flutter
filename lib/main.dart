import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_rps/screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MaterialApp(
    title: 'RPS Flutter',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 169, 117, 255)),
      useMaterial3: true,
      sliderTheme:
          const SliderThemeData(showValueIndicator: ShowValueIndicator.always),
      textTheme: GoogleFonts.lexendTextTheme(),
    ),
    home: const MainScreen(),
  ));
}
