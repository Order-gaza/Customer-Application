import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Global theme controller — manages dark/light mode with persistence.
class ThemeController extends GetxController {
  static ThemeController get to => Get.find();

  static const String _storageKey = 'theme_mode';
  final _storage = GetStorage();

  final Rx<ThemeMode> themeMode = ThemeMode.dark.obs;

  bool get isDark => themeMode.value == ThemeMode.dark;

  @override
  void onInit() {
    super.onInit();
    final stored = _storage.read<String>(_storageKey);
    if (stored == 'light') {
      themeMode.value = ThemeMode.light;
    } else {
      themeMode.value = ThemeMode.dark;
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
    themeMode.value = ThemeMode.dark;
    Get.changeThemeMode(ThemeMode.dark);
    _storage.write(_storageKey, 'dark');
  }

  void setLight() {
    themeMode.value = ThemeMode.light;
    Get.changeThemeMode(ThemeMode.light);
    _storage.write(_storageKey, 'light');
  }
}
