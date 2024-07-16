import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  primaryColor: Color(0xFFFFA726),
  colorScheme: ColorScheme.fromSwatch().copyWith(
    secondary: Color(0xFFFF7043),
  ),
  scaffoldBackgroundColor: Color(0xFFFFE0B2),
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFFFFA726),
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
    ),
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: Color(0xFFFFA726),
    textTheme: ButtonTextTheme.primary,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.all(Color(0xFFFFA726)),
      foregroundColor: MaterialStateProperty.all(Colors.white),
      textStyle: MaterialStateProperty.all(TextStyle(fontSize: 16)),
      padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
    ),
  ),
);
