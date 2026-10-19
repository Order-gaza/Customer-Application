import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../localization/app_translations.dart';
import '../utils/app_navigator.dart';

class ConnectivityController extends ChangeNotifier {
  static ConnectivityController? _instance;
  static ConnectivityController get to =>
      _instance ??= ConnectivityController();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isConnected = true;
  bool get isConnected => _isConnected;
  bool _snackBarVisible = false;

  ConnectivityController() {
    _instance = this;
    _checkInitialConnection();
    _subscription = _connectivity.onConnectivityChanged.listen(_onChanged);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _checkInitialConnection() async {
    final result = await _connectivity.checkConnectivity();
    _onChanged(result);
  }

  void _onChanged(List<ConnectivityResult> results) {
    final connected = results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none);

    if (connected && !_isConnected) {
      // Came back online
      _isConnected = true;
      notifyListeners();
      _dismissSnackBar();
      _showBackOnline();
    } else if (!connected && _isConnected) {
      // Went offline
      _isConnected = false;
      notifyListeners();
      _showNoConnection();
    }
  }

  void _showNoConnection() {
    if (_snackBarVisible) return;
    _snackBarVisible = true;
    AppNavigator.rawSnackbar(
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
    );
  }

  void _dismissSnackBar() {
    if (_snackBarVisible) {
      if (AppNavigator.isSnackbarOpen) {
        AppNavigator.closeCurrentSnackbar();
      }
      _snackBarVisible = false;
    }
  }

  void _showBackOnline() {
    AppNavigator.rawSnackbar(
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
      isDismissible: true,
    );
  }
}

final connectivityProvider = ChangeNotifierProvider<ConnectivityController>(
    (ref) => ConnectivityController.to);
