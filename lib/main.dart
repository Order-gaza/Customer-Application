import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'shared/controllers/language_controller.dart';
import 'shared/controllers/theme_controller.dart';
import 'shared/controllers/connectivity_controller.dart';
import 'shared/services/fcm_service.dart';
import 'shared/services/secure_storage_service.dart';
import 'shared/utils/app_navigator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await SecureStorageService.instance.init();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize singletons
  LanguageController.to;
  ThemeController.to;
  ConnectivityController.to;

  // Initialize FCM service
  final fcmService = FcmService.to;
  await fcmService.init();

  runApp(const ProviderScope(child: OrderApp()));
}

class OrderApp extends ConsumerWidget {
  const OrderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final theme = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Order',
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNavigator.navigatorKey,
      scaffoldMessengerKey: AppNavigator.messengerKey,

      // Localization
      locale: Locale(language.currentLanguage),

      // Theme — reactive
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: theme.themeMode,

      // Routes
      initialRoute: AppRoutes.splash,
      routes: AppPages.routes,
      onGenerateRoute: AppPages.onGenerateRoute,
    );
  }
}
