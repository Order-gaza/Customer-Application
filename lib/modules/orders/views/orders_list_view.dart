import 'package:flutter/material.dart';
import 'package:order/app/theme/theme_colors.dart';
import 'package:get/get.dart';
import '../../../app/constants/api_endpoints.dart';
import '../../../app/constants/app_constants.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/providers/api_provider.dart';

class OrdersListView extends StatefulWidget {
  const OrdersListView({super.key});
  @override
  State<OrdersListView> createState() => _OrdersListViewState();
}

class _OrdersListViewState extends State<OrdersListView> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String _statusFilter = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final params = <String, String>{'page': '1', 'limit': '50'};
    if (_statusFilter.isNotEmpty) params['status'] = _statusFilter;
    final res = await ApiProvider.get(ApiEndpoints.ordersGetAll, queryParams: params);
    if (res.success) _orders = res.data?['orders'] ?? [];
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cx.scaffold,
      appBar: AppBar(title: Text('My Orders'.tr)),
      body: Column(
        children: [
          // Status filter chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _chip('', 'All'.tr),
                _chip('pending', 'Pending'.tr),
                _chip('preparing', 'Preparing'.tr),
                _chip('out_for_delivery', 'Out for Delivery'.tr),
                _chip('delivered', 'Delivered'.tr),
                _chip('cancelled', 'Cancelled'.tr),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
                : _orders.isEmpty
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.receipt_long_rounded, size: 60, color: context.cx.textHint),
                        const SizedBox(height: 12),
                        Text('No orders yet'.tr, style: TextStyle(color: context.cx.textSecondary, fontSize: 16)),
                      ]))
                    : RefreshIndicator(
                        color: AppColors.primaryOrange,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _orders.length,
                          itemBuilder: (ctx, i) => _orderCard(_orders[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String value, String label) {
    final selected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(color: selected ? Colors.white : context.cx.textSecondary, fontSize: 12)),
        selected: selected,
        selectedColor: AppColors.primaryOrange,
        backgroundColor: context.cx.surface,
        side: BorderSide.none,
        onSelected: (_) { setState(() => _statusFilter = value); _load(); },
      ),
    );
  }

  Widget _orderCard(dynamic o) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.orderDetail, arguments: {'order_id': o['id']}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: context.cx.card, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('#${o['order_number'] ?? ''}', style: TextStyle(color: context.cx.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                _statusBadge(o['status'] ?? ''),
              ],
            ),
            const SizedBox(height: 8),
            if (o['vendor_name'] != null)
              Row(children: [
                Icon(Icons.store_mall_directory_outlined, color: context.cx.textSecondary, size: 16),
                const SizedBox(width: 6),
                Text(o['vendor_name'], style: TextStyle(color: context.cx.textSecondary, fontSize: 13)),
              ]),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${AppConstants.currency} ${o['total_amount'] ?? '0'}', style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 15)),
                Text(o['created_at']?.toString().substring(0, 10) ?? '', style: TextStyle(color: context.cx.textSecondary, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bgColor;
    switch (status) {
      case 'pending': bgColor = AppColors.statusPending; break;
      case 'admin_confirmed': case 'sent_to_vendor': case 'vendor_accepted': bgColor = AppColors.statusConfirmed; break;
      case 'preparing': bgColor = AppColors.statusPreparing; break;
      case 'ready_for_pickup': bgColor = AppColors.statusReady; break;
      case 'out_for_delivery': bgColor = AppColors.statusDispatched; break;
      case 'delivered': bgColor = AppColors.statusDelivered; break;
      case 'cancelled': bgColor = AppColors.statusCancelled; break;
      default: bgColor = context.cx.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
      child: Text(AppConstants.orderStatusLabel(status), style: TextStyle(color: bgColor, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
