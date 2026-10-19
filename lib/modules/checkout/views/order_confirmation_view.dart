import 'package:flutter/material.dart';
import 'package:order/app/theme/theme_colors.dart';
import '../../../shared/localization/app_translations.dart';
import '../../../shared/utils/app_navigator.dart';
import '../../../app/constants/app_constants.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';

class OrderConfirmationView extends StatelessWidget {
  const OrderConfirmationView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = AppNavigator.arguments as Map<String, dynamic>? ?? {};
    return Scaffold(
      backgroundColor: context.cx.scaffold,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success.withValues(alpha: 0.15),
                  ),
                  child: const Icon(Icons.check_circle_outline_rounded, size: 60, color: AppColors.success),
                ),
                const SizedBox(height: 24),
                Text('Order Placed!'.tr, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: context.cx.textPrimary)),
                const SizedBox(height: 12),
                Text('Your order has been placed successfully'.tr, style: TextStyle(color: context.cx.textSecondary, fontSize: 14), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: context.cx.card, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      _row(context, 'Order Number'.tr, args['order_number'] ?? '-'),
                      Divider(color: context.cx.divider, height: 20),
                      _row(context, 'Total'.tr, '${AppConstants.currency} ${args['total_amount'] ?? '0'}'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => AppNavigator.toNamed(AppRoutes.orderTracking, arguments: {'order_id': args['order_id']}),
                    child: Text('Track Order'.tr, style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => AppNavigator.offAllNamed(AppRoutes.main),
                    child: Text('Back to Home'.tr, style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String l, String v) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: TextStyle(color: context.cx.textSecondary, fontSize: 14)),
          Text(v, style: TextStyle(color: context.cx.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      );
}
