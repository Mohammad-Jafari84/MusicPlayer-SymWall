import 'package:flutter/material.dart';

class AppTheme {
  static const Color _matteBlack = Color(0xFF1C1C1C);
  static const Color _softGold = Color(0xFFFACF5A);
  static const Color _softWhite = Color(0xFFEFEFEF);
    static const Color _deepNavy = Color(0xFF131914); // رنگ پررنگ برای تم سبز
    static const Color _lightTeal = Color(0xFF146C03); // رنگ کم‌رنگ برای تم سبز

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
    scaffoldBackgroundColor: _softWhite,
    colorScheme: ColorScheme.light(
      primary: _softGold,
      secondary: _softGold.withOpacity(0.8),
      background: _softWhite,
      surface: Color(0xFFF4F4F4),
      onPrimary: _softWhite,
      onBackground: _matteBlack,
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
        foregroundColor: _softWhite,
        minimumSize: Size(double.infinity, 48),
      ),
    ),
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: _matteBlack),
      titleLarge: TextStyle(color: _matteBlack, fontWeight: FontWeight.bold),
    ),
  );

  static final ThemeData greenTheme = ThemeData(
    brightness: Brightness.dark, // تم سبز را با حس و حال تیره می‌سازیم
    primaryColor: _lightTeal,
    scaffoldBackgroundColor: _deepNavy, // استفاده از رنگ پررنگ به‌عنوان پس‌زمینه
    colorScheme: ColorScheme.dark(
      primary: _lightTeal, // رنگ کم‌رنگ به‌عنوان رنگ اصلی
      secondary: _lightTeal.withOpacity(0.8),
      background: _deepNavy,
      onPrimary: _deepNavy, // متن روی رنگ اصلی
      onBackground: _softWhite, // متن روی پس‌زمینه
      onSurface: _softWhite.withOpacity(0.9), // متن روی سطوح
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _deepNavy,
      foregroundColor: _softWhite,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightTeal,
        foregroundColor: _deepNavy,
        minimumSize: Size(double.infinity, 48),
      ),
    ),
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: _softWhite),
      titleLarge: TextStyle(color: _softWhite, fontWeight: FontWeight.bold),
    ),
  );
}