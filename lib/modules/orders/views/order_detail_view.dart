import 'package:flutter/material.dart';
import 'package:order/app/theme/theme_colors.dart';
import 'package:get/get.dart';
import '../../../app/constants/api_endpoints.dart';
import '../../../app/constants/app_constants.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/providers/api_provider.dart';

class OrderDetailView extends StatefulWidget {
  const OrderDetailView({super.key});
  @override
  State<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<OrderDetailView> {
  Map<String, dynamic>? _order;
  List<dynamic> _vendors = [];
  List<dynamic> _history = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final orderId = Get.arguments?['order_id'];
    if (orderId == null) {
      setState(() => _isLoading = false);
      return;
    }
    final res = await ApiProvider.get(ApiEndpoints.ordersGetDetail, queryParams: {'id': orderId});
    if (res.success && res.data != null) {
      _order = res.data['order'];
      _vendors = res.data['vendors'] ?? [];
      _history = res.data['status_history'] ?? [];
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cx.scaffold,
      appBar: AppBar(title: Text('Order Details'.tr)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
          : _order == null
              ? Center(child: Text('Something went wrong'.tr, style: TextStyle(color: context.cx.textSecondary)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order header
                      _section(Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('#${_order!['order_number'] ?? ''}', style: TextStyle(color: context.cx.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                        _statusBadge(_order!['status'] ?? ''),
                      ])),

                      // Vendor and Items
                      const SizedBox(height: 12),
                      ..._vendors.map((v) {
                        final vItems = v['items'] as List<dynamic>? ?? [];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _section(Row(children: [
                              const Icon(Icons.store_mall_directory_outlined, color: AppColors.primaryOrange, size: 20),
                              const SizedBox(width: 10),
                              Text(v['name'] ?? '', style: TextStyle(color: context.cx.textPrimary, fontWeight: FontWeight.w600)),
                            ])),
                            const SizedBox(height: 8),
                            ...vItems.map((item) => _itemRow(item)),
                            const SizedBox(height: 12),
                          ],
                        );
                      }),

                      // Price breakdown
                      const SizedBox(height: 12),
                      _sectionTitle('Price Breakdown'.tr),
                      _section(Column(children: [
                        _priceRow('Subtotal'.tr, _order!['subtotal']),
                        _priceRow('Delivery Fee'.tr, (double.tryParse(_order!['delivery_fee']?.toString() ?? '0') ?? 0) + (double.tryParse(_order!['service_fee']?.toString() ?? '0') ?? 0)),
                        if (_order!['multi_vendor_surcharge'] != null && (double.tryParse(_order!['multi_vendor_surcharge']?.toString() ?? '0') ?? 0) > 0)
                          _priceRow('رسوم تعدد المتاجر'.tr, _order!['multi_vendor_surcharge']),
                        if (_order!['platform_fee'] != null && (double.tryParse(_order!['platform_fee']?.toString() ?? '0') ?? 0) > 0) 
                          _priceRow('Platform Fee'.tr, _order!['platform_fee']),
                        Divider(color: context.cx.divider, height: 16),
                        _priceRow('Total'.tr, _order!['total_amount'], bold: true),
                      ])),

                      // Status history
                      if (_history.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _sectionTitle('Status History'.tr),
                        ..._history.map((h) => _historyRow(h)),
                      ],

                      const SizedBox(height: 20),
                      // Actions
                      if (_order!['status'] != 'delivered' && _order!['status'] != 'cancelled')
                        SizedBox(width: double.infinity, child: OutlinedButton.icon(
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                          onPressed: () {
                            if (_order!['status'] == 'pending') {
                              _cancelOrder();
                            } else {
                              final isAr = Get.locale?.languageCode == 'ar';
                              final textDir = isAr ? TextDirection.rtl : TextDirection.ltr;
                              Get.snackbar(
                                'Cannot Cancel'.tr,
                                'This order has been confirmed and can no longer be cancelled. Please contact support for assistance.'.tr,
                                titleText: Text('Cannot Cancel'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), textAlign: isAr ? TextAlign.right : TextAlign.left, textDirection: textDir),
                                messageText: Text('This order has been confirmed and can no longer be cancelled. Please contact support for assistance.'.tr, style: const TextStyle(color: Colors.white, fontSize: 14), textAlign: isAr ? TextAlign.right : TextAlign.left, textDirection: textDir),
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: AppColors.error.withValues(alpha: 0.9),
                                colorText: Colors.white,
                                margin: const EdgeInsets.all(12),
                                duration: const Duration(seconds: 4),
                                icon: const Icon(Icons.info_outline, color: Colors.white),
                              );
                            }
                          },
                          label: Text('Cancel Order'.tr),
                        )),
                      if (_order!['status'] == 'delivered') ...[
                        SizedBox(width: double.infinity, child: ElevatedButton(
                          onPressed: () => Get.toNamed(AppRoutes.rateOrder, arguments: {'order_id': _order!['id']}),
                          child: Text('Rate Your Experience'.tr),
                        )),
                      ],
                      const SizedBox(height: 8),
                      SizedBox(width: double.infinity, child: TextButton(
                        onPressed: () => Get.toNamed(AppRoutes.orderTracking, arguments: {'order_id': _order!['id']}),
                        child: Text('Track Order'.tr, style: const TextStyle(color: AppColors.primaryOrange)),
                      )),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Future<void> _cancelOrder() async {
    final confirmed = await Get.dialog<bool>(AlertDialog(
      backgroundColor: context.cx.card,
      title: Text('Cancel order?'.tr, style: TextStyle(color: context.cx.textPrimary)),
      content: Text('Are you sure you want to cancel this order?'.tr, style: TextStyle(color: context.cx.textSecondary)),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: Text('No'.tr)),
        TextButton(onPressed: () => Get.back(result: true), child: Text('Yes'.tr, style: const TextStyle(color: AppColors.error))),
      ],
    ));
    if (confirmed == true) {
      final res = await ApiProvider.post(ApiEndpoints.ordersCancel, body: {'order_id': _order!['id']});
      if (res.success) { _load(); Get.snackbar('Success'.tr, 'Order cancelled'.tr, snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.success.withValues(alpha: 0.9), colorText: Colors.white, margin: const EdgeInsets.all(12)); }
    }
  }

  Widget _section(Widget child) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: context.cx.card, borderRadius: BorderRadius.circular(12)), child: child);
  Widget _sectionTitle(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: TextStyle(color: context.cx.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)));

  Widget _itemRow(dynamic item) => Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: context.cx.card, borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item['item_name'] ?? '', style: TextStyle(color: context.cx.textPrimary, fontSize: 14)),
          Text('x${item['quantity']}', style: TextStyle(color: context.cx.textSecondary, fontSize: 12)),
        ])),
        Text('${AppConstants.currency} ${item['line_total'] ?? '0'}', style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.w600)),
      ]));

  Widget _priceRow(String l, dynamic v, {bool bold = false}) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l, style: TextStyle(color: bold ? context.cx.textPrimary : context.cx.textSecondary, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text('${AppConstants.currency} ${v ?? '0'}', style: TextStyle(color: bold ? AppColors.primaryOrange : context.cx.textPrimary, fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
      ]));

  Widget _historyRow(dynamic h) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
        Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryOrange)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AppConstants.orderStatusLabel(h['status'] ?? ''), style: TextStyle(color: context.cx.textPrimary, fontSize: 13)),
          Text(h['changed_at']?.toString() ?? '', style: TextStyle(color: context.cx.textSecondary, fontSize: 11)),
        ])),
      ]));

  Widget _statusBadge(String s) {
    Color c;
    switch (s) {
      case 'pending': c = AppColors.statusPending; break;
      case 'delivered': c = AppColors.statusDelivered; break;
      case 'cancelled': c = AppColors.statusCancelled; break;
      default: c = AppColors.statusConfirmed;
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
        child: Text(AppConstants.orderStatusLabel(s), style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)));
  }
}
