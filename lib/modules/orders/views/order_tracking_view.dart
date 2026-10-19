import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:order/app/theme/theme_colors.dart';
import '../../../shared/localization/app_translations.dart';
import '../../../shared/utils/app_navigator.dart';
import '../../../app/constants/api_endpoints.dart';
import '../../../app/constants/app_constants.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/providers/api_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderTrackingView extends StatefulWidget {
  const OrderTrackingView({super.key});
  @override
  State<OrderTrackingView> createState() => _OrderTrackingViewState();
}

class _OrderTrackingViewState extends State<OrderTrackingView> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final orderId = AppNavigator.arguments?['order_id'];
    if (orderId == null) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await ApiProvider.get(
        ApiEndpoints.ordersTrack,
        queryParams: {'id': orderId.toString()},
      );
      if (res.success && res.data != null) {
        _data = res.data as Map<String, dynamic>;
      } else {
        _data = null;
        if (kDebugMode) debugPrint('Track order failed: ${res.message}');
      }
    } catch (e) {
      _data = null;
      if (kDebugMode) debugPrint('Track order error: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cx.scaffold,
      appBar: AppBar(title: Text('Order Tracking'.tr)),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryOrange))
          : _data == null
              ? _buildError(context)
              : _buildContent(context),
    );
  }

  // ── Error state ──────────────────────────────────────────
  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 60, color: context.cx.textHint),
            const SizedBox(height: 12),
            Text(
              'Could not load tracking info'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.cx.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 160,
              child: ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text('Retry'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main content ─────────────────────────────────────────
  Widget _buildContent(BuildContext context) {
    final isCancelled = _data!['is_cancelled'] == true;
    final steps =
        (_data!['steps'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return RefreshIndicator(
      color: AppColors.primaryOrange,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        // KEY FIX: stretch so every child (including Row+Expanded) gets a bounded width
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order number
            Text(
              '#${_data!['order_number'] ?? ''}',
              style: TextStyle(
                color: context.cx.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppConstants.orderStatusLabel(_data!['current_status'] ?? ''),
              style: const TextStyle(
                color: AppColors.primaryOrange,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            // Cancelled banner
            if (isCancelled)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cancel_rounded,
                        color: AppColors.error, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This order has been cancelled'.tr,
                        style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            // Steps timeline
            if (!isCancelled)
              for (final step in steps) _buildStep(context, step),

            const SizedBox(height: 32),

            // Support card
            _buildSupportCard(context),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Timeline step ─────────────────────────────────────────
  Widget _buildStep(BuildContext context, Map<String, dynamic> step) {
    final completed = step['completed'] == true;
    final current = step['current'] == true;
    final label = step['label']?.toString().tr ??
        AppConstants.orderStatusLabel(step['status'] ?? '');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dot + line
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completed
                    ? AppColors.primaryOrange
                    : current
                        ? AppColors.primaryOrange.withValues(alpha: 0.3)
                        : context.cx.surface,
                border: Border.all(
                  color: completed || current
                      ? AppColors.primaryOrange
                      : context.cx.divider,
                  width: 2,
                ),
              ),
              child: completed
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            Container(
                width: 2,
                height: 40,
                color:
                    completed ? AppColors.primaryOrange : context.cx.divider),
          ],
        ),
        const SizedBox(width: 14),
        // Label
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: completed || current
                        ? context.cx.textPrimary
                        : context.cx.textSecondary,
                    fontWeight: current ? FontWeight.bold : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
                if (current)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Current Step'.tr,
                      style: TextStyle(
                        color: AppColors.primaryOrange.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Support card ──────────────────────────────────────────
  Widget _buildSupportCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cx.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cx.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.headset_mic_rounded,
                    color: AppColors.primaryOrange, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need Help?'.tr,
                      style: TextStyle(
                        color: context.cx.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Order is too late? Contact us here'.tr,
                      style: TextStyle(
                          color: context.cx.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => _showSupportOptions(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Contact Us'.tr,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Support bottom sheet ──────────────────────────────────
  void _showSupportOptions(BuildContext context) {
    AppNavigator.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.cx.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Contact Support'.tr,
                    style: TextStyle(
                        color: context.cx.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                IconButton(
                    onPressed: () => AppNavigator.back(),
                    icon: Icon(Icons.close_rounded,
                        color: context.cx.textSecondary)),
              ],
            ),
            const SizedBox(height: 24),
            _buildContactItem(
              context,
              icon: Icons.phone_in_talk_rounded,
              title: 'Call Support'.tr,
              subtitle: '+970599261116',
              onTap: () async {
                AppNavigator.back();
                final uri = Uri.parse('tel:+970599261116');
                if (await canLaunchUrl(uri)) launchUrl(uri);
              },
            ),
            const SizedBox(height: 12),
            _buildContactItem(
              context,
              icon: Icons.message_rounded,
              title: 'WhatsApp'.tr,
              subtitle: 'Send us a message'.tr,
              onTap: () async {
                AppNavigator.back();
                final msg = 'مرحباً، طلبي متأخر أو أحتاج إلى مساعدة';
                final uri = Uri.parse(
                    'https://wa.me/+970599261116?text=${Uri.encodeComponent(msg)}');
                if (await canLaunchUrl(uri)) {
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildContactItem(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: context.cx.divider, width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: context.cx.surface, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primaryOrange, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: context.cx.textPrimary,
                          fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: TextStyle(
                          color: context.cx.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: context.cx.textHint, size: 14),
          ],
        ),
      ),
    );
  }
}
