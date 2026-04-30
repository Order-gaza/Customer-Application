import 'package:flutter/material.dart';
import 'package:order/app/theme/theme_colors.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/auth_controller.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _passC = TextEditingController();
  final _confirmC = TextEditingController();
  final _authC = AuthController.to;
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passC.dispose();
    _confirmC.dispose();
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
                'Reset Password'.tr,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: context.cx.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Password must be at least 6 characters'.tr,
                style: TextStyle(
                  fontSize: 14,
                  color: context.cx.textSecondary,
                ),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _passC,
                obscureText: _obscure,
                style: TextStyle(color: context.cx.textPrimary),
                decoration: InputDecoration(
                  hintText: 'New Password'.tr,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _confirmC,
                obscureText: _obscureConfirm,
                style: TextStyle(color: context.cx.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Confirm New Password'.tr,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Obx(() => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _authC.isLoading.value
                          ? null
                          : () => _authC.resetPassword(
                                _passC.text,
                                _confirmC.text,
                              ),
                      child: _authC.isLoading.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text('Reset Password'.tr,
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
