import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/services/secure_storage_service.dart';
import '../../app/constants/app_constants.dart';

class LanguageController extends GetxController {
  static const String _baseLanguageKey = 'language_code';
  static LanguageController get to => Get.find();

  RxString currentLanguage = 'ar'.obs; // Arabic default

  String get _currentLanguageKey {
    final userId = SecureStorageService.instance.read(AppConstants.storageUserId);
    if (userId != null && userId.trim().isNotEmpty) {
      return '${_baseLanguageKey}_$userId';
    }
    return _baseLanguageKey;
  }

  bool get isArabic => currentLanguage.value == 'ar';

  @override
  void onInit() {
    super.onInit();
    _loadSavedLanguage();
  }

  Future<void> reloadLanguage() async {
    await _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_currentLanguageKey);
    if (savedCode != null) {
      currentLanguage.value = savedCode;
      Get.updateLocale(Locale(savedCode));
    } else {
      // Default to Arabic
      currentLanguage.value = 'ar';
      Get.updateLocale(const Locale('ar'));
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    if (currentLanguage.value == languageCode) return;

    currentLanguage.value = languageCode;
    Get.updateLocale(Locale(languageCode));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentLanguageKey, languageCode);
  }
}
