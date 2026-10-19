import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/secure_storage_service.dart';
import '../../shared/utils/app_navigator.dart';
import '../../app/constants/api_endpoints.dart';
import '../../data/providers/api_provider.dart';
import '../../firebase_options.dart';

/// Top-level background message handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) debugPrint('[FCM] Background message: ${message.messageId}');
}

class FcmService extends ChangeNotifier {
  static FcmService? _instance;
  static FcmService get to => _instance ??= FcmService();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  /// Notification channel for Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'order_notifications',
    'Order Notifications',
    description: 'Notifications for order status updates',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  /// Initialize FCM
  Future<FcmService> init() async {
    _instance = this;

    // Create notification channel on Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Initialize local notifications
    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Get FCM token
      final token = await _messaging.getToken();
      if (kDebugMode) debugPrint('[FCM] Token: ****');

      if (token != null) {
        _registerTokenWithBackend(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_registerTokenWithBackend);

      // Foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // When app is opened from a notification (background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was launched from a notification (terminated)
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    }

    // Fetch initial unread count from backend
    fetchUnreadCount();

    return this;
  }

  /// Fetch unread notification count from backend
  Future<void> fetchUnreadCount() async {
    try {
      final res = await ApiProvider.get(ApiEndpoints.notificationsUnreadCount);
      if (res.success && res.data != null) {
        _unreadCount = res.data['unread_count'] ?? 0;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Reset unread count (call when user opens notifications page)
  void resetUnreadCount() {
    _unreadCount = 0;
    notifyListeners();
  }

  /// Register FCM token with the backend
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      final authToken = SecureStorageService.instance.read('auth_token');
      if (authToken == null) {
        if (kDebugMode) {
          debugPrint('[FCM] No auth token found — skipping registration');
        }
        return;
      }

      await ApiProvider.post(
        ApiEndpoints.registerFcmToken,
        body: {
          'fcm_token': token,
          'device_type': 'android',
        },
      );
      if (kDebugMode) debugPrint('[FCM] Token registered with backend');
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] Failed to register token: $e');
    }
  }

  /// Handle foreground message — show local notification
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('[FCM] Foreground message: ${message.notification?.title}');
    }

    final notification = message.notification;

    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
            playSound: true,
            enableVibration: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );

      // Update unread count
      _unreadCount++;
      notifyListeners();

      // Show in-app banner
      if (!AppNavigator.isSnackbarOpen) {
        AppNavigator.snackbar(
          notification.title ?? 'Notification',
          notification.body ?? '',
          backgroundColor: const Color(0xFF1E1E2E),
          colorText: Colors.white,
          icon: const Icon(
            Icons.notifications_active,
            color: Color(0xFFFF6B35),
          ),
          duration: const Duration(seconds: 4),
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(12),
          borderRadius: 12,
        );
      }
    }
  }

  /// Handle notification tap (when app opens from background)
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) debugPrint('[FCM] Notification tapped: ${message.data}');
    _navigateToOrder(message.data);
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      debugPrint('[FCM] Local notification tapped: ${response.payload}');
    }
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _navigateToOrder(data);
      } catch (_) {}
    }
  }

  /// Navigate to order tracking based on notification data
  void _navigateToOrder(Map<String, dynamic> data) {
    final orderId = data['order_id'];

    if (orderId != null && orderId.toString().isNotEmpty) {
      // Navigate to order tracking page
      try {
        AppNavigator.toNamed('/order-tracking', arguments: {
          'order_id': orderId.toString(),
        });
      } catch (_) {
        if (kDebugMode) {
          debugPrint('[FCM] Could not navigate to order tracking');
        }
      }
    }
  }

  /// Re-register token (call after login)
  Future<void> refreshToken() async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _registerTokenWithBackend(token);
    }
  }
}

final fcmProvider = ChangeNotifierProvider<FcmService>((ref) => FcmService.to);
