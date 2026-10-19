import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order/app/theme/theme_colors.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/localization/app_translations.dart';
import '../../../shared/utils/app_navigator.dart';
import '../controllers/auth_controller.dart';

class VerifyEmailView extends ConsumerStatefulWidget {
  const VerifyEmailView({super.key});

  @override
  ConsumerState<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends ConsumerState<VerifyEmailView> {
  final _otpC = TextEditingController();

  @override
  void dispose() {
    _otpC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authC = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: context.cx.scaffold,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => AppNavigator.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryOrange.withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.mark_email_read_outlined,
                    size: 40, color: AppColors.primaryOrange),
              ),
              const SizedBox(height: 24),
              Text(
                'Verify Email'.tr,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.cx.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${'We sent a 6-digit code to'.tr}\n${authC.pendingEmail}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: context.cx.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // OTP input
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

              // Verify button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authC.isLoading
                      ? null
                      : () => authC.verifyEmail(_otpC.text.trim()),
                  child: authC.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Verify Code'.tr,
                          style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),

              // Resend OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Didn\'t receive code?'.tr,
                    style: TextStyle(
                      color: context.cx.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  authC.resendSeconds > 0
                      ? Text(
                          '${'Resend in'.tr} ${authC.resendSeconds}s',
                          style: TextStyle(
                            color: context.cx.textHint,
                            fontSize: 14,
                          ),
                        )
                      : TextButton(
                          onPressed: () => authC.resendOtp(),
                          child: Text(
                            'Resend'.tr,
                            style: const TextStyle(
                              color: AppColors.primaryOrange,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
