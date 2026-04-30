import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';

class ConnectivityController extends GetxController {
  static ConnectivityController get to => Get.find();

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  final RxBool isConnected = true.obs;
  bool _snackBarVisible = false;

  @override
  void onInit() {
    super.onInit();
    _checkInitialConnection();
    _subscription = _connectivity.onConnectivityChanged.listen(_onChanged);
  }

  @override
  void onClose() {
    _subscription.cancel();
    super.onClose();
  }

  Future<void> _checkInitialConnection() async {
    final result = await _connectivity.checkConnectivity();
    _onChanged(result);
  }

  void _onChanged(List<ConnectivityResult> results) {
    final connected = results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none);

    if (connected && !isConnected.value) {
      // Came back online
      isConnected.value = true;
      _dismissSnackBar();
      _showBackOnline();
    } else if (!connected && isConnected.value) {
      // Went offline
      isConnected.value = false;
      _showNoConnection();
    }
  }

  void _showNoConnection() {
    if (_snackBarVisible) return;
    _snackBarVisible = true;
    Get.rawSnackbar(
      messageText: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No Internet Connection'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.error.withValues(alpha: 0.95),
      borderRadius: 12,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      snackPosition: SnackPosition.TOP,
      duration: null, // persistent until connection is restored
      isDismissible: false,
      animationDuration: const Duration(milliseconds: 400),
      snackStyle: SnackStyle.FLOATING,
    );
  }

  void _dismissSnackBar() {
    if (_snackBarVisible) {
      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }
      _snackBarVisible = false;
    }
  }

  void _showBackOnline() {
    Get.rawSnackbar(
      messageText: Row(
        children: [
          const Icon(Icons.wifi_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Back Online'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.success.withValues(alpha: 0.95),
      borderRadius: 12,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 400),
      snackStyle: SnackStyle.FLOATING,
    );
  }
}
