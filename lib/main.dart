import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/holo_theme.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const HoloRadioApp());
}

class HoloRadioApp extends StatelessWidget {
  const HoloRadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Holo Radio',
      debugShowCheckedModeBanner: false,
      theme: HoloTheme.theme,
      home: const HomeScreen(),
    );
  }
}
