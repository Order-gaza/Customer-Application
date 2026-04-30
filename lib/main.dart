import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'shared/localization/app_translations.dart';
import 'shared/controllers/language_controller.dart';
import 'shared/controllers/theme_controller.dart';
import 'shared/controllers/connectivity_controller.dart';
import 'shared/services/fcm_service.dart';
import 'shared/services/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await SecureStorageService.instance.init();

  // Initialize Firebase
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  Get.put(LanguageController());
  Get.put(ThemeController());
  Get.put(ConnectivityController(), permanent: true);

  // Initialize FCM service
  final fcmService = FcmService();
  Get.put(fcmService, permanent: true);
  await fcmService.init();

  runApp(const OrderApp());
}

class OrderApp extends StatelessWidget {
  const OrderApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = LanguageController.to;
    final themeController = ThemeController.to;

    return Obx(() => GetMaterialApp(
      title: 'Order',
      debugShowCheckedModeBanner: false,

      // Localization
      translations: AppTranslations(),
      locale: Locale(languageController.currentLanguage.value),
      fallbackLocale: const Locale('ar'),

      // Theme — reactive
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.themeMode.value,

      // Routes
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,

      // Default transition
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 250),
    ));
  }
}

