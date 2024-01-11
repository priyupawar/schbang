import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
    primaryColor: Colors.white,
    primaryColorDark: Colors.black,
    cardColor: Colors.grey.shade200,
    brightness: Brightness.light,
    dividerColor: Colors.grey);

final ThemeData darkTheme = ThemeData(
    primaryColor: Colors.black,
    primaryColorDark: Colors.white,
    cardColor: Colors.grey.shade200,
    brightness: Brightness.dark,
    dividerColor: Colors.white);

class ThemeConfig {
  static ThemeData currentTheme = lightTheme;

  static void toggleTheme() {
    currentTheme = (currentTheme == lightTheme) ? darkTheme : lightTheme;
  }
}
