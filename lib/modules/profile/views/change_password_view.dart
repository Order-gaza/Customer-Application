import 'package:flutter/material.dart';
import 'package:order/app/theme/theme_colors.dart';
import '../../../shared/localization/app_translations.dart';
import '../../../shared/utils/app_navigator.dart';
import '../../../app/constants/api_endpoints.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/providers/api_provider.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});
  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final _currentC = TextEditingController();
  final _newC = TextEditingController();
  final _confirmC = TextEditingController();
  bool _isSaving = false;
  bool _obsCurrent = true;
  bool _obsNew = true;
  bool _obsConfirm = true;

  Future<void> _change() async {
    if (_currentC.text.isEmpty || _newC.text.isEmpty) {
      AppNavigator.snackbar('Error'.tr, 'Both fields are required'.tr, snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.error.withValues(alpha: 0.9), colorText: Colors.white, margin: const EdgeInsets.all(12));
      return;
    }
    if (_newC.text.length < 6) {
      AppNavigator.snackbar('Error'.tr, 'Password must be at least 6 characters'.tr, snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.error.withValues(alpha: 0.9), colorText: Colors.white, margin: const EdgeInsets.all(12));
      return;
    }
    if (_newC.text != _confirmC.text) {
      AppNavigator.snackbar('Error'.tr, 'Passwords do not match'.tr, snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.error.withValues(alpha: 0.9), colorText: Colors.white, margin: const EdgeInsets.all(12));
      return;
    }
    setState(() => _isSaving = true);
    final res = await ApiProvider.post(ApiEndpoints.changePassword, body: {
      'current_password': _currentC.text,
      'new_password': _newC.text,
      'confirm_password': _confirmC.text,
    });
    setState(() => _isSaving = false);
    if (res.isNetworkError) return;
    if (res.success) {
      if (AppNavigator.isSnackbarOpen) AppNavigator.closeCurrentSnackbar();
      AppNavigator.snackbar('Password Changed'.tr, 'Logging out for security. Please login with your new password.'.tr, snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.success.withValues(alpha: 0.9), colorText: Colors.white, margin: const EdgeInsets.all(12), duration: const Duration(seconds: 3));
      await Future.delayed(const Duration(seconds: 2));
      ApiProvider.clearAuth();
      AppNavigator.offAllNamed(AppRoutes.login);
    } else {
      if (AppNavigator.isSnackbarOpen) AppNavigator.closeCurrentSnackbar();
      AppNavigator.snackbar('Error'.tr, res.message ?? 'Change failed'.tr, snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.error.withValues(alpha: 0.9), colorText: Colors.white, margin: const EdgeInsets.all(12));
    }
  }

  @override
  void dispose() { _currentC.dispose(); _newC.dispose(); _confirmC.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cx.scaffold,
      appBar: AppBar(title: Text('Change Password'.tr)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _currentC, 
              obscureText: _obsCurrent, 
              style: TextStyle(color: context.cx.textPrimary), 
              decoration: InputDecoration(
                labelText: 'Current Password'.tr, 
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obsCurrent ? Icons.visibility_off : Icons.visibility, color: context.cx.iconMuted),
                  onPressed: () => setState(() => _obsCurrent = !_obsCurrent),
                ),
              )
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newC, 
              obscureText: _obsNew, 
              style: TextStyle(color: context.cx.textPrimary), 
              decoration: InputDecoration(
                labelText: 'New Password'.tr, 
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obsNew ? Icons.visibility_off : Icons.visibility, color: context.cx.iconMuted),
                  onPressed: () => setState(() => _obsNew = !_obsNew),
                ),
              )
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmC, 
              obscureText: _obsConfirm, 
              style: TextStyle(color: context.cx.textPrimary), 
              decoration: InputDecoration(
                labelText: 'Confirm New Password'.tr, 
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obsConfirm ? Icons.visibility_off : Icons.visibility, color: context.cx.iconMuted),
                  onPressed: () => setState(() => _obsConfirm = !_obsConfirm),
                ),
              )
            ),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _isSaving ? null : _change,
              child: _isSaving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Change Password'.tr, style: const TextStyle(fontSize: 16)),
            )),
          ],
        ),
      ),
    );
  }
}
