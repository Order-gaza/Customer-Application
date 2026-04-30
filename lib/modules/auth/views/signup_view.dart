import 'package:flutter/material.dart';
import 'package:order/app/theme/theme_colors.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/auth_controller.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();
  final _passC = TextEditingController();
  final _confirmPassC = TextEditingController();
  final _authC = AuthController.to;
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
      Get.snackbar('Error'.tr, 'Could not open link'.tr);
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _phoneC.dispose();
    _passC.dispose();
    _confirmPassC.dispose();
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
              Text(
                'Create Your Account'.tr,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: context.cx.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign Up'.tr,
                style: TextStyle(
                  fontSize: 14,
                  color: context.cx.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Name
              TextField(
                controller: _nameC,
                style: TextStyle(color: context.cx.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Full Name'.tr,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),

              // Email
              TextField(
                controller: _emailC,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: context.cx.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Email address'.tr,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Phone
              TextField(
                controller: _phoneC,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: context.cx.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Phone Number'.tr,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Password
              TextField(
                controller: _passC,
                obscureText: _obscure,
                style: TextStyle(color: context.cx.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Password'.tr,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextField(
                controller: _confirmPassC,
                obscureText: _obscureConfirm,
                style: TextStyle(color: context.cx.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Confirm Password'.tr,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Terms and Privacy Policy
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreedToTerms,
                      activeColor: AppColors.primaryOrange,
                      checkColor: Colors.white,
                      side: BorderSide(color: context.cx.textSecondary),
                      onChanged: (val) {
                        setState(() => _agreedToTerms = val ?? false);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Wrap(
                      children: [
                        Text(
                          'I have read and agree to the'.tr + ' ',
                          style: TextStyle(
                            color: context.cx.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _launchUrl('https://appforyou.store/Order/terms.html'),
                          child: Text(
                            'Terms and Services'.tr,
                            style: const TextStyle(
                              color: AppColors.primaryOrange,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(
                          ' ' + 'and'.tr + ' ',
                          style: TextStyle(
                            color: context.cx.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _launchUrl('https://appforyou.store/Order/privacy.html'),
                          child: Text(
                            'Privacy Policy'.tr,
                            style: const TextStyle(
                              color: AppColors.primaryOrange,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Signup button
              Obx(() => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_authC.isLoading.value || !_agreedToTerms)
                          ? null
                          : () => _authC.signup(
                                _nameC.text,
                                _emailC.text,
                                _phoneC.text,
                                _passC.text,
                                _confirmPassC.text,
                              ),
                      child: _authC.isLoading.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('Create Account'.tr,
                              style: const TextStyle(fontSize: 16)),
                    ),
                  )),
              const SizedBox(height: 20),

              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?'.tr,
                    style: TextStyle(
                      color: context.cx.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      'Sign In'.tr,
                      style: const TextStyle(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
