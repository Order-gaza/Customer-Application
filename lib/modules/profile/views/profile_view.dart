import 'package:flutter/material.dart';
import 'package:order/app/theme/theme_colors.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/constants/api_endpoints.dart';
import '../../../app/constants/app_constants.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/providers/api_provider.dart';
import '../../auth/controllers/auth_controller.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});
  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final res = await ApiProvider.get(ApiEndpoints.profileGet);
    if (res.success) _user = res.data?['user'];
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cx.scaffold,
      appBar: AppBar(title: Text('Profile'.tr)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                children: [
                  // Avatar
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: context.cx.surface,
                          backgroundImage: _user?['profile_image'] != null ? CachedNetworkImageProvider(_user!['profile_image']) : null,
                          child: _user?['profile_image'] == null ? Icon(Icons.person, size: 50, color: context.cx.textSecondary) : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(_user?['name'] ?? '', style: TextStyle(color: context.cx.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_user?['email'] ?? '', style: TextStyle(color: context.cx.textSecondary, fontSize: 14)),
                  const SizedBox(height: 24),

                  // Stats
                  Row(
                    children: [
                      _statCard('Total Orders'.tr, '${_user?['total_orders'] ?? 0}', Icons.receipt_long_rounded),
                      const SizedBox(width: 12),
                      _statCard('Total Spent'.tr, '${AppConstants.currency} ${_user?['total_spent'] ?? '0'}', Icons.payments_rounded),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Menu items
                  _menuItem(Icons.person_outline, 'Edit Profile'.tr, () async { await Get.toNamed(AppRoutes.editProfile); _load(); }),
                  _menuItem(Icons.location_on_outlined, 'My Addresses'.tr, () => Get.toNamed(AppRoutes.addresses)),
                  _menuItem(Icons.lock_outline, 'Change Password'.tr, () => Get.toNamed(AppRoutes.changePassword)),
                  _menuItem(Icons.notifications_none_rounded, 'Notifications'.tr, () => Get.toNamed(AppRoutes.notifications)),
                  _menuItem(Icons.settings_outlined, 'Settings'.tr, () => Get.toNamed(AppRoutes.settings)),
                  const SizedBox(height: 12),
                  _menuItem(Icons.logout_rounded, 'Logout'.tr, () => _confirmLogout(), color: AppColors.error),
                ],
              ),
            ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: context.cx.card, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryOrange, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: context.cx.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: context.cx.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: context.cx.card, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color ?? AppColors.primaryOrange),
        title: Text(label, style: TextStyle(color: color ?? context.cx.textPrimary, fontSize: 15)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, color: color ?? context.cx.textSecondary, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _confirmLogout() {
    Get.dialog(AlertDialog(
      backgroundColor: context.cx.card,
      title: Text('Logout'.tr, style: TextStyle(color: context.cx.textPrimary)),
      content: Text('Are you sure you want to logout?'.tr, style: TextStyle(color: context.cx.textSecondary)),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text('Cancel'.tr)),
        TextButton(onPressed: () { Get.back(); Get.put(AuthController()).logout(); }, child: Text('Logout'.tr, style: const TextStyle(color: AppColors.error))),
      ],
    ));
  }
}
