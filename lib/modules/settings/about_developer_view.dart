import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../shared/localization/app_translations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/theme_colors.dart';

class AboutDeveloperView extends StatelessWidget {
  const AboutDeveloperView({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (kDebugMode) debugPrint('Could not launch \$url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cx.scaffold,
      appBar: AppBar(
        title: Text('About Developer'.tr),
        backgroundColor: context.cx.scaffold,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryOrange, width: 2),
                image: const DecorationImage(
                  image: AssetImage('assets/yasser.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Yasser Ashraf'.tr,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.cx.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Flutter Developer'.tr,
              style: TextStyle(
                fontSize: 16,
                color: context.cx.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            // Dynamic short bio
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cx.card,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'about_developer_bio'.tr,
                style: TextStyle(
                  fontSize: 15,
                  color: context.cx.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.start,
              ),
            ),
            const SizedBox(height: 24),

            // Contacts
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                'Connect with me'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.cx.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildContactTile(
              context,
              icon: Icons.work,
              title: 'Portfolio'.tr,
              subtitle: 'View my production-ready apps'.tr,
              onTap: () => _launchUrl('https://yasser-ashraf-production-ready-mobile-apps.vercel.app/'),
            ),
            const SizedBox(height: 8),
            _buildContactTile(
              context,
              icon: Icons.link,
              title: 'LinkedIn'.tr,
              subtitle: 'linkedin.com/in/yasserashraf',
              onTap: () => _launchUrl('https://www.linkedin.com/in/yasserashraf/'),
            ),
            const SizedBox(height: 8),
            _buildContactTile(
              context,
              icon: Icons.message,
              title: 'Whatsapp'.tr,
              subtitle: '+201003640081',
              onTap: () => _launchUrl('https://wa.me/201003640081'),
            ),
            const SizedBox(height: 8),
            _buildContactTile(
              context,
              icon: Icons.email,
              title: 'email'.tr,
              subtitle: 'yasserashraf3142@gmail.com',
              onTap: () => _launchUrl('mailto:yasserashraf3142@gmail.com'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cx.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.cx.divider, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryOrange, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.cx.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.cx.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: context.cx.textSecondary),
          ],
        ),
      ),
    );
  }
}
