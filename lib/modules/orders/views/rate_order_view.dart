import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:order/app/theme/theme_colors.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import '../../../app/constants/api_endpoints.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/providers/api_provider.dart';

class RateOrderView extends StatefulWidget {
  const RateOrderView({super.key});
  @override
  State<RateOrderView> createState() => _RateOrderViewState();
}

class _RateOrderViewState extends State<RateOrderView> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<dynamic> _vendors = [];

  // Per-vendor rating data
  final Map<String, double> _ratings = {};
  final Map<String, TextEditingController> _commentControllers = {};

  @override
  void initState() {
    super.initState();
    _loadOrderVendors();
  }

  Future<void> _loadOrderVendors() async {
    final orderId = Get.arguments?['order_id']?.toString();
    if (orderId == null || orderId.isEmpty || orderId == 'null') {
      setState(() => _isLoading = false);
      return;
    }
    final res = await ApiProvider.get(ApiEndpoints.ordersGetDetail, queryParams: {'id': orderId});
    if (res.success && res.data != null) {
      _vendors = res.data['vendors'] ?? [];
      for (final v in _vendors) {
        final vendorId = v['vendor_id']?.toString() ?? '';
        _ratings[vendorId] = 0;
        _commentControllers[vendorId] = TextEditingController();
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _submit() async {
    // Validate all vendors have ratings
    for (final v in _vendors) {
      final vendorId = v['vendor_id']?.toString() ?? '';
      if ((_ratings[vendorId] ?? 0) == 0) {
        final vendorName = v['name'] ?? '';
        Get.snackbar(
          ''.tr,
          '${'Please select a rating'.tr} - $vendorName',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.warning.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
        );
        return;
      }
    }

    final orderId = Get.arguments?['order_id']?.toString();
    if (orderId == null || orderId.isEmpty || orderId == 'null') {
      Get.snackbar('Error'.tr, 'Order not found'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(12));
      return;
    }

    setState(() => _isSubmitting = true);

    // Build ratings array
    final List<Map<String, dynamic>> ratingsData = [];
    for (final v in _vendors) {
      final vendorId = v['vendor_id']?.toString() ?? '';
      final comment = _commentControllers[vendorId]?.text.trim() ?? '';
      ratingsData.add({
        'vendor_id': vendorId,
        'rating': (_ratings[vendorId] ?? 0).toInt(),
        if (comment.isNotEmpty) 'comment': comment,
      });
    }

    final res = await ApiProvider.post(ApiEndpoints.ordersRate, body: {
      'order_id': orderId,
      'ratings': jsonEncode(ratingsData),
    });

    setState(() => _isSubmitting = false);
    if (res.isNetworkError) return;
    if (res.success) {
      Get.back();
      if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
      Get.snackbar('Success'.tr, 'Thank you for your feedback!'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(12));
    } else {
      if (kDebugMode) debugPrint('Rate order failed: ${res.message}');
      if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
      Get.snackbar('Error'.tr, (res.message ?? 'Something went wrong').tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(12));
    }
  }

  @override
  void dispose() {
    for (final c in _commentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cx.scaffold,
      appBar: AppBar(title: Text('Rate Your Experience'.tr)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
          : _vendors.isEmpty
              ? Center(child: Text('Something went wrong'.tr, style: TextStyle(color: context.cx.textSecondary)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      const Icon(Icons.star_rounded, color: AppColors.goldenYellow, size: 60),
                      const SizedBox(height: 12),
                      Text(
                        'How was your order?'.tr,
                        style: TextStyle(color: context.cx.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_vendors.length > 1)
                        Text(
                          'Rate each vendor separately'.tr,
                          style: TextStyle(color: context.cx.textSecondary, fontSize: 14),
                        ),
                      const SizedBox(height: 24),

                      // Vendor rating cards
                      ..._vendors.map((v) {
                        final vendorId = v['vendor_id']?.toString() ?? '';
                        final vendorName = v['name'] ?? '';
                        return _vendorRatingCard(context, vendorId, vendorName);
                      }),

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text('Submit Rating'.tr, style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _vendorRatingCard(BuildContext context, String vendorId, String vendorName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cx.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cx.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vendor name header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.store_rounded, color: AppColors.primaryOrange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  vendorName,
                  style: TextStyle(
                    color: context.cx.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rating stars centered
          Center(
            child: RatingBar.builder(
              initialRating: 0,
              minRating: 1,
              direction: Axis.horizontal,
              itemCount: 5,
              itemSize: 40,
              glowColor: AppColors.goldenYellow.withValues(alpha: 0.3),
              unratedColor: context.cx.divider,
              itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: AppColors.goldenYellow),
              onRatingUpdate: (r) => _ratings[vendorId] = r,
            ),
          ),
          const SizedBox(height: 14),

          // Comment field
          TextField(
            controller: _commentControllers[vendorId],
            maxLines: 3,
            style: TextStyle(color: context.cx.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Write a review (optional)'.tr,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
