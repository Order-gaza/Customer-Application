import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/constants/api_endpoints.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/providers/api_provider.dart';
import '../../../shared/controllers/connectivity_controller.dart';
import '../../../shared/controllers/language_controller.dart';
import '../../../shared/services/fcm_service.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  // Loading states
  final RxBool isLoading = false.obs;

  // OTP resend timer
  final RxInt resendSeconds = 0.obs;
  Timer? _resendTimer;

  // Temp storage for auth flows
  String _pendingEmail = '';
  String _resetToken = '';

  String get pendingEmail => _pendingEmail;

  /// Check if we are online; if not, show a single friendly message and return false
  bool _ensureConnected() {
    try {
      if (!ConnectivityController.to.isConnected.value) {
        // ConnectivityController already shows a persistent "No Internet" banner,
        // so just stop loading – don't spam another snackbar.
        isLoading.value = false;
        return false;
      }
    } catch (_) {
      // ConnectivityController not registered yet – proceed anyway
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

    isLoading.value = true;
    final res = await ApiProvider.post(ApiEndpoints.login, body: {
      'email': email.trim(),
      'password': password,
    });
    isLoading.value = false;

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
      if (Get.isRegistered<FcmService>()) {
        Get.find<FcmService>().refreshToken();
      }
      Get.offAllNamed(AppRoutes.main);
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

    isLoading.value = true;
    final res = await ApiProvider.post(ApiEndpoints.signup, body: {
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'password': password,
      'confirm_password': confirmPassword,
    });
    isLoading.value = false;

    if (res.isNetworkError) return;

    if (res.success) {
      _pendingEmail = email.trim();
      _startResendTimer();
      Get.toNamed(AppRoutes.verifyEmail);
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

    isLoading.value = true;
    final res = await ApiProvider.post(ApiEndpoints.verifyEmail, body: {
      'email': _pendingEmail,
      'otp': otp,
    });
    isLoading.value = false;

    if (res.isNetworkError) return;

    if (res.success) {
      _snack('Account created successfully'.tr);
      Get.offAllNamed(AppRoutes.login);
    } else {
      _snack(res.message ?? 'Invalid code'.tr, isError: true);
    }
  }

  // ── RESEND OTP ──
  Future<void> resendOtp() async {
    if (resendSeconds.value > 0) return;
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

    isLoading.value = true;
    final res = await ApiProvider.post(ApiEndpoints.forgotPassword, body: {
      'email': email.trim(),
    });
    isLoading.value = false;

    if (res.isNetworkError) return;

    if (res.success) {
      _pendingEmail = email.trim();
      _startResendTimer();
      Get.toNamed(AppRoutes.verifyResetOtp);
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

    isLoading.value = true;
    final res = await ApiProvider.post(ApiEndpoints.verifyResetOtp, body: {
      'email': _pendingEmail,
      'otp': otp,
    });
    isLoading.value = false;

    if (res.isNetworkError) return;

    if (res.success) {
      _resetToken = res.data?['reset_token'] ?? '';
      Get.toNamed(AppRoutes.resetPassword);
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

    isLoading.value = true;
    final res = await ApiProvider.post(ApiEndpoints.resetPassword, body: {
      'email': _pendingEmail,
      'reset_token': _resetToken,
      'new_password': password,
      'confirm_password': confirmPassword,
    });
    isLoading.value = false;

    if (res.isNetworkError) return;

    if (res.success) {
      _snack('Password reset successfully'.tr);
      Get.offAllNamed(AppRoutes.login);
    } else {
      _snack(res.message ?? 'Something went wrong'.tr, isError: true);
    }
  }

  // ── LOGOUT ──
  Future<void> logout() async {
    // Fire-and-forget – don't block on network errors during logout
    ApiProvider.post(ApiEndpoints.logout);
    ApiProvider.clearAuth();
    Get.offAllNamed(AppRoutes.login);
  }

  // ── TIMER ──
  void _startResendTimer() {
    resendSeconds.value = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      resendSeconds.value--;
      if (resendSeconds.value <= 0) t.cancel();
    });
  }

  /// Show a snackbar. Closes any existing one first to prevent stacking.
  void _snack(String message, {bool isError = false}) {
    // Close existing snackbar to prevent stacking
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
    Get.snackbar(
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
  void onClose() {
    _resendTimer?.cancel();
    super.onClose();
  }
}
