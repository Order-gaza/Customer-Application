import 'package:flutter/material.dart';
import 'package:order/app/theme/theme_colors.dart';
import '../../../shared/localization/app_translations.dart';
import '../../../app/constants/api_endpoints.dart';
import '../../../app/constants/app_constants.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/providers/api_provider.dart';

class PointsView extends StatefulWidget {
  const PointsView({super.key});
  @override
  State<PointsView> createState() => _PointsViewState();
}

class _PointsViewState extends State<PointsView> {
  bool _loading = true;
  int _balance = 0;
  double _shekelEquiv = 0;
  double _pointsPerShekel = 10;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiProvider.get(ApiEndpoints.getPoints);
    if (res.success && res.data != null) {
      _balance = (res.data['points_balance'] ?? 0) as int;
      _shekelEquiv = (res.data['shekel_equivalent'] ?? 0).toDouble();
      _pointsPerShekel = (res.data['points_per_shekel'] ?? 10).toDouble();
      _transactions = res.data['transactions'] ?? [];
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cx.scaffold,
      appBar: AppBar(title: Text('My Points'.tr)),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primaryOrange,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Balance card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryOrange, AppColors.darkOrange],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(children: [
                      const Icon(Icons.stars, color: Colors.white, size: 40),
                      const SizedBox(height: 12),
                      Text('$_balance', style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
                      Text('points'.tr, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '≈ ${AppConstants.currency} ${_shekelEquiv.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_pointsPerShekel.toStringAsFixed(0)} ${'points'.tr} = ${AppConstants.currency} 1',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  // Transaction history
                  Text('History'.tr, style: TextStyle(color: context.cx.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_transactions.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text('No transactions yet'.tr, style: TextStyle(color: context.cx.textSecondary)),
                      ),
                    )
                  else
                    ..._transactions.map((t) => _txnTile(t)),
                ],
              ),
            ),
    );
  }

  Widget _txnTile(dynamic t) {
    final isEarned = t['type'] == 'earned';
    final points = t['points'] ?? 0;
    final orderNum = t['order_number']?.toString();
    final date = t['created_at']?.toString().split(' ').first ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cx.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: (isEarned ? AppColors.success : AppColors.primaryOrange).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isEarned ? Icons.add_circle_outline : Icons.remove_circle_outline,
            color: isEarned ? AppColors.success : AppColors.primaryOrange, size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              _localizeDesc(t['description']?.toString(), isEarned),
              style: TextStyle(color: context.cx.textPrimary, fontWeight: FontWeight.w500, fontSize: 14),
            ),
            if (orderNum != null)
              Text('${'Order'.tr} #$orderNum', style: TextStyle(color: context.cx.textSecondary, fontSize: 12)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            '${isEarned ? '+' : '-'}$points',
            style: TextStyle(
              color: isEarned ? AppColors.success : AppColors.primaryOrange,
              fontWeight: FontWeight.bold, fontSize: 16,
            ),
          ),
          Text(date, style: TextStyle(color: context.cx.textSecondary, fontSize: 10)),
        ]),
      ]),
    );
  }

  String _localizeDesc(String? desc, bool isEarned) {
    if (desc == null) return isEarned ? 'Points earned'.tr : 'Points redeemed'.tr;
    const map = {
      'Earned from order': 'Earned from order',
      'Redeemed for order discount': 'Redeemed for order discount',
    };
    final key = map[desc];
    return key != null ? key.tr : desc;
  }
}
