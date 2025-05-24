import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  String _theme = 'dark'; // Default: dark

  String get theme => _theme;

  bool get isDarkMode => _theme == 'dark';
  bool get isLightMode => _theme == 'light';
  bool get isGreenMode => _theme == 'green';

  void setTheme(String theme) {
    if (['light', 'dark', 'green', 'system'].contains(theme)) {
      _theme = theme;
      notifyListeners();
    }
  }

  void setLightMode() {
    setTheme('light');
  }

  void setDarkMode() {
    setTheme('dark');
  }

  void setSystemMode() {
    setTheme('system');
  }

  void cycleTheme() {
    // Cycle: dark -> light -> green -> dark
    if (_theme == 'dark') {
      _theme = 'light';
    } else if (_theme == 'light') {
      _theme = 'green';
    } else {
      _theme = 'dark';
    }
    notifyListeners();
  }
}