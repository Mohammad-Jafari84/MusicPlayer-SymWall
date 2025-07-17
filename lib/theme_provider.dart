import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  String _theme = 'green';

  String get theme => _theme;

  bool get isDarkMode => _theme == 'dark';
  bool get isLightMode => _theme == 'light';
  bool get isGreenMode => _theme == 'green';

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _theme = prefs.getString('app_theme') ?? 'green';
    notifyListeners();
  }

  Future<void> setTheme(String theme) async {
    if (['light', 'dark', 'green', 'system'].contains(theme)) {
      _theme = theme;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_theme', theme);
      notifyListeners();
    }
  }

  void setLightMode() => setTheme('light');
  void setDarkMode() => setTheme('dark');
  void setSystemMode() => setTheme('system');

  void cycleTheme() {
    if (_theme == 'dark') {
      setTheme('light');
    } else if (_theme == 'light') {
      setTheme('green');
    } else {
      setTheme('dark');
    }
  }
}