import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/theme_colors.dart';
import '../../shared/controllers/language_controller.dart';
import '../../shared/controllers/theme_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final langC = LanguageController.to;
    final themeC = ThemeController.to;

    return Scaffold(
      backgroundColor: context.cx.scaffold,
      appBar: AppBar(title: Text('Settings'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Theme ──
          Text('Appearance'.tr,
              style: TextStyle(
                  color: context.cx.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Obx(() => _themeOption(
                context,
                themeC,
                isDark: true,
                icon: Icons.dark_mode_rounded,
                title: 'Dark Mode'.tr,
                subtitle: 'Dark background with orange accents'.tr,
              )),
          Obx(() => _themeOption(
                context,
                themeC,
                isDark: false,
                icon: Icons.light_mode_rounded,
                title: 'Light Mode'.tr,
                subtitle: 'Light background with orange accents'.tr,
              )),
          const SizedBox(height: 28),

          // ── Language ──
          Text('Language'.tr,
              style: TextStyle(
                  color: context.cx.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Obx(() => _languageOption(context, langC, 'ar', 'العربية', 'Arabic'.tr)),
          Obx(() => _languageOption(context, langC, 'en', 'English', 'English'.tr)),
          const SizedBox(height: 28),

          // ── About ──
          Text('About'.tr,
              style: TextStyle(
                  color: context.cx.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _infoTile(context, Icons.info_outline, 'App Version'.tr, '1.0.0'),
          _infoTile(context, Icons.article_outlined, 'Terms & Conditions'.tr, '', onTap: () async {
            final uri = Uri.parse('https://appforyou.store/Order/terms.html');
            if (!await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
              Get.snackbar('Error'.tr, 'Could not open link'.tr);
            }
          }),
          _infoTile(context, Icons.shield_outlined, 'Privacy Policy'.tr, '', onTap: () async {
            final uri = Uri.parse('https://appforyou.store/Order/privacy.html');
            if (!await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
              Get.snackbar('Error'.tr, 'Could not open link'.tr);
            }
          }),
          _infoTile(context, Icons.person_outline, 'About Developer'.tr, '', onTap: () => Get.toNamed('/about-developer')),
          const SizedBox(height: 32),
          Center(
              child: Text('© 2026 Order'.tr,
                  style: TextStyle(
                      color: context.cx.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _themeOption(
    BuildContext context,
    ThemeController c, {
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = c.isDark == isDark;
    return GestureDetector(
      onTap: () => isDark ? c.setDark() : c.setLight(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cx.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryOrange : context.cx.divider,
            width: selected ? 2 : 0.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primaryOrange.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primaryOrange.withValues(alpha: 0.15)
                    : context.cx.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: selected
                      ? AppColors.primaryOrange
                      : context.cx.textSecondary,
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: context.cx.textPrimary,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          color: context.cx.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_off_rounded,
              color:
                  selected ? AppColors.primaryOrange : context.cx.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(BuildContext context, LanguageController c,
      String code, String nativeName, String localName) {
    final selected = c.currentLanguage.value == code;
    return GestureDetector(
      onTap: () => c.changeLanguage(code),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cx.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primaryOrange : context.cx.divider,
            width: selected ? 2 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color:
                  selected ? AppColors.primaryOrange : context.cx.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(nativeName,
                style: TextStyle(
                    color: context.cx.textPrimary,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 15)),
            const SizedBox(width: 8),
            Text('($localName)',
                style:
                    TextStyle(color: context.cx.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(
      BuildContext context, IconData icon, String label, String value, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: context.cx.card, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.primaryOrange),
        title: Text(label,
            style: TextStyle(color: context.cx.textPrimary, fontSize: 15)),
        trailing: value.isNotEmpty
            ? Text(value,
                style:
                    TextStyle(color: context.cx.textSecondary, fontSize: 13))
            : Icon(Icons.arrow_forward_ios_rounded,
                color: context.cx.textSecondary, size: 16),
      ),
    );
  }
}
