import 'package:flutter/material.dart';
import 'package:order/app/theme/theme_colors.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _emailC = TextEditingController();
  final _authC = AuthController.to;

  @override
  void dispose() {
    _emailC.dispose();
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Forgot Password'.tr,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: context.cx.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'll send you a 6-digit code'.tr,
                style: TextStyle(
                  fontSize: 14,
                  color: context.cx.textSecondary,
                ),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _emailC,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: context.cx.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Email address'.tr,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 32),

              Obx(() => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _authC.isLoading.value
                          ? null
                          : () => _authC.forgotPassword(_emailC.text),
                      child: _authC.isLoading.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text('Send Reset Code'.tr,
                              style: const TextStyle(fontSize: 16)),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
