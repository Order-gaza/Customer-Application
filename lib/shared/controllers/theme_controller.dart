import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';

/// Global theme controller — manages dark/light mode with persistence and Riverpod reactivity.
class ThemeController extends ChangeNotifier {
  static ThemeController? _instance;
  static ThemeController get to => _instance ??= ThemeController();

  static const String _storageKey = 'theme_mode';
  final _storage = GetStorage();

  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;

  ThemeController() {
    _instance = this;
    final stored = _storage.read<String>(_storageKey);
    if (stored == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }
  }

  void toggleTheme() {
    if (isDark) {
      setLight();
    } else {
      setDark();
    }
  }

  void setDark() {
    _themeMode = ThemeMode.dark;
    _storage.write(_storageKey, 'dark');
    notifyListeners();
  }

  void setLight() {
    _themeMode = ThemeMode.light;
    _storage.write(_storageKey, 'light');
    notifyListeners();
  }
}

final themeProvider =
    ChangeNotifierProvider<ThemeController>((ref) => ThemeController.to);
