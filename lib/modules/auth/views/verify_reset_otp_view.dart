import 'package:flutter/material.dart';
import 'package:order/app/theme/theme_colors.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/auth_controller.dart';

class VerifyResetOtpView extends StatefulWidget {
  const VerifyResetOtpView({super.key});

  @override
  State<VerifyResetOtpView> createState() => _VerifyResetOtpViewState();
}

class _VerifyResetOtpViewState extends State<VerifyResetOtpView> {
  final _otpC = TextEditingController();
  final _authC = AuthController.to;

  @override
  void dispose() {
    _otpC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cx.scaffold,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.info.withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.lock_reset_rounded,
                    size: 40, color: AppColors.info),
              ),
              const SizedBox(height: 24),
              Text(
                'Enter verification code'.tr,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.cx.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${'We sent a 6-digit code to'.tr}\n${_authC.pendingEmail}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: context.cx.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _otpC,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.cx.textPrimary,
                  fontSize: 24,
                  letterSpacing: 12,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '------',
                  counterText: '',
                  hintStyle: TextStyle(
                    color: context.cx.textHint,
                    letterSpacing: 12,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Obx(() => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _authC.isLoading.value
                          ? null
                          : () => _authC.verifyResetOtp(_otpC.text),
                      child: _authC.isLoading.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text('Verify Code'.tr,
                              style: const TextStyle(fontSize: 16)),
                    ),
                  )),
              const SizedBox(height: 24),
              Obx(() {
                if (_authC.resendSeconds.value > 0) {
                  return Text(
                    '${'Resend in'.tr} ${_authC.resendSeconds.value}s',
                    style: TextStyle(
                      color: context.cx.textSecondary,
                      fontSize: 14,
                    ),
                  );
                }
                return TextButton(
                  onPressed: () => _authC.resendOtp(),
                  child: Text(
                    '${'Didn\'t receive code?'.tr} ${'Resend'.tr}',
                    style: const TextStyle(
                      color: AppColors.primaryOrange,
                      fontSize: 14,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
