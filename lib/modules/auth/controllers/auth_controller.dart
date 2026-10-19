import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/constants/api_endpoints.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/providers/api_provider.dart';
import '../../../shared/controllers/connectivity_controller.dart';
import '../../../shared/controllers/language_controller.dart';
import '../../../shared/services/fcm_service.dart';
import '../../../shared/localization/app_translations.dart';
import '../../../shared/utils/app_navigator.dart';

class AuthController extends ChangeNotifier {
  static AuthController? _instance;
  static AuthController get to => _instance ??= AuthController();

  // Loading states
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // OTP resend timer
  int _resendSeconds = 0;
  int get resendSeconds => _resendSeconds;
  Timer? _resendTimer;

  // Temp storage for auth flows
  String _pendingEmail = '';
  String _resetToken = '';

  String get pendingEmail => _pendingEmail;

  AuthController() {
    _instance = this;
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  /// Check if we are online; if not, show a single friendly message and return false
  bool _ensureConnected() {
    try {
      if (!ConnectivityController.to.isConnected) {
        _setLoading(false);
        return false;
      }
    } catch (_) {
      // proceed anyway
    }
    return true;
  }

  // ── LOGIN ──
  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _snack('Email and password are required'.tr, isError: true);
      return;
    }
    if (!_ensureConnected()) return;

    _setLoading(true);
    final res = await ApiProvider.post(ApiEndpoints.login, body: {
      'email': email.trim(),
      'password': password,
    });
    _setLoading(false);

    // Silently ignore network errors – ConnectivityController handles the UI
    if (res.isNetworkError) return;

    if (res.success && res.data != null) {
      final d = res.data;
      ApiProvider.saveAuth(
        token: d['token'] ?? '',
        userId: d['user_id']?.toString() ?? '',
        userName: d['name'] ?? '',
        userEmail: d['email'] ?? '',
        userPhone: d['phone'] ?? '',
        profileImage: d['profile_image'],
      );
      LanguageController.to.reloadLanguage();
      // Register FCM token after successful login
      FcmService.to.refreshToken();
      AppNavigator.offAllNamed(AppRoutes.main);
    } else {
      _snack(res.message ?? 'Login failed'.tr, isError: true);
    }
  }

  // ── SIGNUP ──
  Future<void> signup(String name, String email, String phone,
      String password, String confirmPassword) async {
    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      _snack('All fields are required'.tr, isError: true);
      return;
    }
    if (password.length < 6) {
      _snack('Password must be at least 6 characters'.tr, isError: true);
      return;
    }
    if (password != confirmPassword) {
      _snack('Passwords do not match'.tr, isError: true);
      return;
    }
    if (!_ensureConnected()) return;

    _setLoading(true);
    final res = await ApiProvider.post(ApiEndpoints.signup, body: {
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'password': password,
      'confirm_password': confirmPassword,
    });
    _setLoading(false);

    if (res.isNetworkError) return;

    if (res.success) {
      _pendingEmail = email.trim();
      _startResendTimer();
      AppNavigator.toNamed(AppRoutes.verifyEmail);
    } else {
      _snack(res.message ?? 'Registration failed'.tr, isError: true);
    }
  }

  // ── VERIFY EMAIL OTP ──
  Future<void> verifyEmail(String otp) async {
    if (otp.length != 6) {
      _snack('Please enter the 6-digit code'.tr, isError: true);
      return;
    }
    if (!_ensureConnected()) return;

    _setLoading(true);
    final res = await ApiProvider.post(ApiEndpoints.verifyEmail, body: {
      'email': _pendingEmail,
      'otp': otp,
    });
    _setLoading(false);

    if (res.isNetworkError) return;

    if (res.success) {
      _snack('Account created successfully'.tr);
      AppNavigator.offAllNamed(AppRoutes.login);
    } else {
      _snack(res.message ?? 'Invalid code'.tr, isError: true);
    }
  }

  // ── RESEND OTP ──
  Future<void> resendOtp() async {
    if (_resendSeconds > 0) return;
    if (!_ensureConnected()) return;

    final res = await ApiProvider.post(ApiEndpoints.resendOtp, body: {
      'email': _pendingEmail,
    });

    if (res.isNetworkError) return;

    if (res.success) {
      _snack('Code sent successfully'.tr);
      _startResendTimer();
    } else {
      _snack(res.message ?? 'Something went wrong'.tr, isError: true);
    }
  }

  // ── FORGOT PASSWORD ──
  Future<void> forgotPassword(String email) async {
    if (email.isEmpty) {
      _snack('Enter your email'.tr, isError: true);
      return;
    }
    if (!_ensureConnected()) return;

    _setLoading(true);
    final res = await ApiProvider.post(ApiEndpoints.forgotPassword, body: {
      'email': email.trim(),
    });
    _setLoading(false);

    if (res.isNetworkError) return;

    if (res.success) {
      _pendingEmail = email.trim();
      _startResendTimer();
      AppNavigator.toNamed(AppRoutes.verifyResetOtp);
    } else {
      _snack(res.message ?? 'Something went wrong'.tr, isError: true);
    }
  }

  // ── VERIFY RESET OTP ──
  Future<void> verifyResetOtp(String otp) async {
    if (otp.length != 6) {
      _snack('Please enter the 6-digit code'.tr, isError: true);
      return;
    }
    if (!_ensureConnected()) return;

    _setLoading(true);
    final res = await ApiProvider.post(ApiEndpoints.verifyResetOtp, body: {
      'email': _pendingEmail,
      'otp': otp,
    });
    _setLoading(false);

    if (res.isNetworkError) return;

    if (res.success) {
      _resetToken = res.data?['reset_token'] ?? '';
      AppNavigator.toNamed(AppRoutes.resetPassword);
    } else {
      _snack(res.message ?? 'Invalid code'.tr, isError: true);
    }
  }

  // ── RESET PASSWORD ──
  Future<void> resetPassword(String password, String confirmPassword) async {
    if (password.isEmpty || confirmPassword.isEmpty) {
      _snack('Both fields are required'.tr, isError: true);
      return;
    }
    if (password.length < 6) {
      _snack('Password must be at least 6 characters'.tr, isError: true);
      return;
    }
    if (password != confirmPassword) {
      _snack('Passwords do not match'.tr, isError: true);
      return;
    }
    if (!_ensureConnected()) return;

    _setLoading(true);
    final res = await ApiProvider.post(ApiEndpoints.resetPassword, body: {
      'email': _pendingEmail,
      'reset_token': _resetToken,
      'new_password': password,
      'confirm_password': confirmPassword,
    });
    _setLoading(false);

    if (res.isNetworkError) return;

    if (res.success) {
      _snack('Password reset successfully'.tr);
      AppNavigator.offAllNamed(AppRoutes.login);
    } else {
      _snack(res.message ?? 'Something went wrong'.tr, isError: true);
    }
  }

  // ── LOGOUT ──
  Future<void> logout() async {
    // Fire-and-forget – don't block on network errors during logout
    ApiProvider.post(ApiEndpoints.logout);
    ApiProvider.clearAuth();
    AppNavigator.offAllNamed(AppRoutes.login);
  }

  // ── TIMER ──
  void _startResendTimer() {
    _resendSeconds = 60;
    notifyListeners();
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      _resendSeconds--;
      notifyListeners();
      if (_resendSeconds <= 0) t.cancel();
    });
  }

  /// Show a snackbar.
  void _snack(String message, {bool isError = false}) {
    AppNavigator.snackbar(
      isError ? 'Error'.tr : 'Success'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError
          ? Colors.red.withValues(alpha: 0.9)
          : Colors.green.withValues(alpha: 0.9),
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }
}

final authProvider =
    ChangeNotifierProvider<AuthController>((ref) => AuthController.to);
