import 'package:flutter/material.dart';
import 'package:order/app/theme/theme_colors.dart';
import 'package:get/get.dart';
import '../../../app/constants/api_endpoints.dart';
import '../../../app/constants/app_constants.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/providers/api_provider.dart';
import '../../../shared/services/location_data.dart';
import '../../cart/cart_controller.dart';

class CheckoutView extends StatefulWidget {
  const CheckoutView({super.key});
  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  List<dynamic> _addresses = [];
  String? _selectedAddressId;
  String _paymentMethod = 'cash_on_delivery';
  final _notesC = TextEditingController();
  bool _isLoading = false;
  bool _isPlacing = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    final res = await ApiProvider.get(ApiEndpoints.addressesGetAll);
    if (res.success) {
      _addresses = res.data?['addresses'] ?? [];
      final def = _addresses.firstWhereOrNull((a) => a['is_default'] == 1 || a['is_default'] == true);
      if (def != null) {
        _selectedAddressId = def['id'].toString();
        CartController.to.loadDeliveryFee(_selectedAddressId!);
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _placeOrder() async {
    if (_selectedAddressId == null) {
      Get.snackbar('Error'.tr, 'Please select a delivery address'.tr, snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.error.withValues(alpha: 0.9), colorText: Colors.white, margin: const EdgeInsets.all(12));
      return;
    }
    setState(() => _isPlacing = true);
    final res = await ApiProvider.post(ApiEndpoints.ordersCreate, body: {
      'address_id': _selectedAddressId!,
      'payment_method': _paymentMethod,
      if (_notesC.text.isNotEmpty) 'notes': _notesC.text,
    });
    setState(() => _isPlacing = false);
    if (res.isNetworkError) return;
    if (res.success) {
      CartController.to.loadCart();
      Get.offNamed(AppRoutes.orderConfirmation, arguments: {
        'order_id': res.data?['order_id'],
        'order_number': res.data?['order_number'],
        'total_amount': res.data?['total_amount'],
      });
    } else {
      if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
      Get.snackbar('Error'.tr, res.message ?? 'Something went wrong'.tr, snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.error.withValues(alpha: 0.9), colorText: Colors.white, margin: const EdgeInsets.all(12));
    }
  }

  @override
  void dispose() { _notesC.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cartC = CartController.to;
    return Scaffold(
      backgroundColor: context.cx.scaffold,
      appBar: AppBar(title: Text('Checkout'.tr)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery Address
                  _sectionTitle('Delivery Address'.tr),
                  if (_addresses.isEmpty)
                    _emptyAddressCard()
                  else
                    ..._addresses.map((a) => _addressCard(a)),
                  TextButton.icon(
                    onPressed: () async {
                      await Get.toNamed(AppRoutes.addAddress);
                      _loadAddresses();
                    },
                    icon: const Icon(Icons.add, color: AppColors.primaryOrange, size: 18),
                    label: Text('Add New Address'.tr, style: const TextStyle(color: AppColors.primaryOrange)),
                  ),
                  const SizedBox(height: 20),

                  // Payment method
                  _sectionTitle('Payment Method'.tr),
                  _paymentOption('cash_on_delivery', Icons.money_rounded, 'Cash on Delivery'.tr),
                  const SizedBox(height: 20),

                  // Notes
                  _sectionTitle('Order Notes'.tr),
                  TextField(
                    controller: _notesC,
                    maxLines: 2,
                    style: TextStyle(color: context.cx.textPrimary),
                    decoration: InputDecoration(hintText: 'Add a note for the rider...'.tr),
                  ),
                  const SizedBox(height: 24),

                  // Summary
                  _sectionTitle('Order Summary'.tr),
                  Obx(() => _summaryRow('Subtotal'.tr, cartC.subtotal.value)),
                  Obx(() => _summaryRow('Delivery Fee'.tr, cartC.deliveryFee.value + cartC.serviceFee.value)),
                  // Zone route info
                  Obx(() {
                    if (cartC.zoneFrom.value.isNotEmpty && cartC.zoneTo.value.isNotEmpty) {
                      final fromAr = LocationData.zoneKeyToArabic(cartC.zoneFrom.value);
                      final toAr = LocationData.zoneKeyToArabic(cartC.zoneTo.value);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.route_rounded, size: 14, color: AppColors.info),
                            const SizedBox(width: 6),
                            Text(
                              'التوصيل: $fromAr → $toAr',
                              style: TextStyle(color: AppColors.info, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  // Multi-vendor surcharge (only shown when ordering from 2+ vendors)
                  Obx(() {
                    if (cartC.multiVendorSurcharge.value > 0) {
                      return _summaryRow('رسوم تعدد المتاجر'.tr, cartC.multiVendorSurcharge.value);
                    }
                    return const SizedBox.shrink();
                  }),
                  Divider(color: context.cx.divider, height: 24),
                  Obx(() => _summaryRow('Total'.tr, cartC.total, bold: true)),
                  const SizedBox(height: 24),

                  // Place order
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isPlacing ? null : _placeOrder,
                      child: _isPlacing
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Place Order'.tr, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(t, style: TextStyle(color: context.cx.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _addressCard(dynamic a) {
    final id = a['id'].toString();
    final selected = id == _selectedAddressId;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedAddressId = id);
        CartController.to.loadDeliveryFee(id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cx.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primaryOrange : context.cx.divider, width: selected ? 2 : 0.5),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? AppColors.primaryOrange : context.cx.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a['city'] != null && a['city'].toString().isNotEmpty
                      ? '${a['neighborhood'] ?? ''}, ${a['city']}'
                      : (a['label'] ?? ''),
                      style: TextStyle(color: context.cx.textPrimary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(a['address_line'] ?? '', style: TextStyle(color: context.cx.textSecondary, fontSize: 13), maxLines: 2),
                ],
              ),
            ),
            if (a['is_default'] == 1) Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.primaryOrange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
              child: Text('Default'.tr, style: const TextStyle(color: AppColors.primaryOrange, fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyAddressCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: context.cx.card, borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text('No addresses saved'.tr, style: TextStyle(color: context.cx.textSecondary))),
      );

  Widget _paymentOption(String value, IconData icon, String label) {
    final selected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cx.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primaryOrange : context.cx.divider, width: selected ? 2 : 0.5),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? AppColors.primaryOrange : context.cx.textSecondary, size: 20),
            const SizedBox(width: 12),
            Icon(icon, color: AppColors.primaryOrange, size: 22),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: context.cx.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: bold ? context.cx.textPrimary : context.cx.textSecondary, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
            Text('${AppConstants.currency} ${value.toStringAsFixed(2)}',
                style: TextStyle(color: bold ? AppColors.primaryOrange : context.cx.textPrimary, fontWeight: bold ? FontWeight.bold : FontWeight.w600, fontSize: bold ? 16 : 14)),
          ],
        ),
      );
}
