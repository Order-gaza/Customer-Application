import 'package:flutter/material.dart';
import 'package:order/app/theme/theme_colors.dart';
import '../../../shared/localization/app_translations.dart';
import '../../../shared/utils/app_navigator.dart';
import '../../../app/constants/api_endpoints.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/providers/api_provider.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});
  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _nameC = TextEditingController();
  final _phoneC = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final res = await ApiProvider.get(ApiEndpoints.profileGet);
    if (res.success && res.data?['user'] != null) {
      _nameC.text = res.data['user']['name'] ?? '';
      _phoneC.text = res.data['user']['phone'] ?? '';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final body = <String, String>{};
    if (_nameC.text.isNotEmpty) body['name'] = _nameC.text.trim();
    if (_phoneC.text.isNotEmpty) body['phone'] = _phoneC.text.trim();
    final res = await ApiProvider.post(ApiEndpoints.profileUpdate, body: body);
    setState(() => _isSaving = false);
    if (res.isNetworkError) return;
    if (res.success) {
      AppNavigator.back();
      if (AppNavigator.isSnackbarOpen) AppNavigator.closeCurrentSnackbar();
      AppNavigator.snackbar('Success'.tr, 'Profile updated'.tr, snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.success.withValues(alpha: 0.9), colorText: Colors.white, margin: const EdgeInsets.all(12));
    } else {
      if (AppNavigator.isSnackbarOpen) AppNavigator.closeCurrentSnackbar();
      AppNavigator.snackbar('Error'.tr, res.message ?? 'Something went wrong'.tr, snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.error.withValues(alpha: 0.9), colorText: Colors.white, margin: const EdgeInsets.all(12));
    }
  }

  @override
  void dispose() { _nameC.dispose(); _phoneC.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cx.scaffold,
      appBar: AppBar(title: Text('Edit Profile'.tr)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(controller: _nameC, style: TextStyle(color: context.cx.textPrimary), decoration: InputDecoration(labelText: 'Full Name'.tr, prefixIcon: const Icon(Icons.person_outline))),
                  const SizedBox(height: 16),
                  TextField(controller: _phoneC, keyboardType: TextInputType.phone, style: TextStyle(color: context.cx.textPrimary), decoration: InputDecoration(labelText: 'Phone Number'.tr, prefixIcon: const Icon(Icons.phone_outlined))),
                  const SizedBox(height: 32),
                  SizedBox(width: double.infinity, child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Update Profile'.tr, style: const TextStyle(fontSize: 16)),
                  )),
                ],
              ),
            ),
    );
  }
}
