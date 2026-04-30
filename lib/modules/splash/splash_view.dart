import 'package:flutter/material.dart';
import 'package:order/app/theme/theme_colors.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../app/constants/app_constants.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../data/providers/api_provider.dart';
import '../../app/constants/api_endpoints.dart';
import '../../shared/services/fcm_service.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      _navigate();
    });
  }

  Future<void> _navigate() async {
    final storage = GetStorage();

    // Check if onboarding has been seen
    final onboardingSeen =
        storage.read<bool>(AppConstants.storageOnboardingSeen) ?? false;
    if (!onboardingSeen) {
      Get.offAllNamed(AppRoutes.onboarding);
      return;
    }

    // Try auto-login
    if (ApiProvider.isLoggedIn) {
      try {
        final response = await ApiProvider.get(ApiEndpoints.validateSession);
        if (response.success) {
          // Re-register FCM token on auto-login
          if (Get.isRegistered<FcmService>()) {
            Get.find<FcmService>().refreshToken();
          }
          Get.offAllNamed(AppRoutes.main);
          return;
        }
        // If it's a network error, don't logout — proceed with cached credentials
        if (response.isNetworkError) {
          Get.offAllNamed(AppRoutes.main);
          return;
        }
      } catch (_) {
        // Network exception — proceed to main with cached credentials
        Get.offAllNamed(AppRoutes.main);
        return;
      }
      // Session explicitly rejected by server — clear & go to login
      ApiProvider.clearAuth();
    }

    Get.offAllNamed(AppRoutes.login);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cx.scaffold,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.primaryOrange.withValues(alpha: 0.4),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.asset(
                          'assets/launcher_icon.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Order'.tr,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
