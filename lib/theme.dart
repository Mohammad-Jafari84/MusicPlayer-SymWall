import 'package:flutter/material.dart';

class AppTheme {
  static const Color _matteBlack = Color(0xFF1C1C1C);
  static const Color _softGold = Color(0xFFFACF5A);
  static const Color _softWhite = Color(0xFFEFEFEF);

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: _softGold,
    scaffoldBackgroundColor: _matteBlack,
    colorScheme: ColorScheme.dark(
      primary: _softGold,
      secondary: _softGold.withOpacity(0.8),
      background: _matteBlack,
      surface: Color(0xFF2C2C2C),
      onPrimary: _matteBlack,
      onBackground: _softWhite,
      onSurface: Colors.white70,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _matteBlack,
      foregroundColor: _softWhite,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _softGold,
        foregroundColor: _matteBlack,
        minimumSize: Size(double.infinity, 48),
      ),
    ),
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: _softWhite),
      titleLarge: TextStyle(color: _softWhite, fontWeight: FontWeight.bold),
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: _softGold,
    scaffoldBackgroundColor: _softWhite, // سفید ملایم
    colorScheme: ColorScheme.light(
      primary: _softGold,
      secondary: _softGold.withOpacity(0.8),
      background: _softWhite,
      surface: Color(0xFFF4F4F4),
      onPrimary: _softWhite, // متن روی پس‌زمینه طلایی => سفید ملایم
      onBackground: _matteBlack, // متن عمومی => مشکی
      onSurface: _matteBlack.withOpacity(0.87),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _softWhite,
      foregroundColor: _matteBlack,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _softGold,
        foregroundColor: _softWhite, // متن دکمه (روی طلایی) سفید ملایم
        minimumSize: Size(double.infinity, 48),
      ),
    ),
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: _matteBlack), // متن عمومی مشکی
      titleLarge: TextStyle(color: _matteBlack, fontWeight: FontWeight.bold),
    ),
  );
}