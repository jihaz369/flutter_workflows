import 'package:flutter/material.dart';

class HoloTheme {
  static const Color background = Color(0xFF03070D);
  static const Color panel = Color(0xFF07101E);
  static const Color darkPanel = Color(0xFF040911);
  static const Color cyan = Color(0xFF00E5FF);
  static const Color dimCyan = Color(0xFF07566A);
  static const Color green = Color(0xFF00FF88);
  static const Color red = Color(0xFFFF3366);
  static const Color yellow = Color(0xFFFFCC00);
  static const Color blue = Color(0xFF0066FF);
  static const Color borderColor = Color(0x4000E5FF);
  static const Color grid = Color(0x1000E5FF);

  static const String fontMono = 'Courier New';
  static const String fontUi = 'Segoe UI';

  static ThemeData get theme => ThemeData(
    scaffoldBackgroundColor: background,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: cyan,
      secondary: green,
      surface: panel,
      background: background,
      error: red,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: cyan, fontFamily: fontMono, fontSize: 14),
      bodyMedium: TextStyle(color: cyan, fontFamily: fontMono, fontSize: 12),
      titleLarge: TextStyle(color: cyan, fontFamily: fontMono, fontSize: 22, letterSpacing: 4),
      titleMedium: TextStyle(color: cyan, fontFamily: fontMono, fontSize: 16, letterSpacing: 2),
      labelSmall: TextStyle(color: dimCyan, fontFamily: fontMono, fontSize: 10, letterSpacing: 1),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkPanel,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: const BorderSide(color: cyan),
      ),
      labelStyle: const TextStyle(color: dimCyan, fontFamily: fontMono, fontSize: 10),
      hintStyle: const TextStyle(color: dimCyan, fontFamily: fontMono),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: panel,
        foregroundColor: cyan,
        side: const BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        textStyle: const TextStyle(fontFamily: fontMono, fontSize: 12, letterSpacing: 2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) =>
        states.contains(MaterialState.selected) ? green : dimCyan),
      trackColor: MaterialStateProperty.resolveWith((states) =>
        states.contains(MaterialState.selected) ? green.withOpacity(0.3) : darkPanel),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: cyan,
      inactiveTrackColor: dimCyan,
      thumbColor: cyan,
      overlayColor: Color(0x2000E5FF),
    ),
    dropdownMenuTheme: const DropdownMenuThemeData(
      textStyle: TextStyle(color: cyan, fontFamily: fontMono, fontSize: 12),
    ),
  );
}
