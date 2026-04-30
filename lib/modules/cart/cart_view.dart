import 'package:flutter/material.dart';
import 'package:order/app/theme/theme_colors.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/constants/app_constants.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import 'cart_controller.dart';

class CartView extends StatelessWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = CartController.to;

    return Scaffold(
      backgroundColor: context.cx.scaffold,
      appBar: AppBar(
        title: Text('My Cart'.tr),
        actions: [
          Obx(() => c.vendors.isNotEmpty
              ? TextButton(
                  onPressed: () => _confirmClearCart(context, c),
                  child: Text('Clear Cart'.tr,
                      style: const TextStyle(color: AppColors.error)),
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() {
        if (c.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryOrange));
        }
        if (c.vendors.isEmpty) return _buildEmpty(context);
        return _buildCartContent(context, c);
      }),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 80, color: context.cx.textHint),
          const SizedBox(height: 16),
          Text('Your cart is empty'.tr,
              style: TextStyle(color: context.cx.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Start browsing vendors to add items'.tr,
              style: TextStyle(color: context.cx.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildCartContent(BuildContext context, CartController c) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: c.vendors.length,
            itemBuilder: (ctx, i) => _buildVendorSection(context, c, c.vendors[i]),
          ),
        ),

        // Bottom summary
        _buildBottomSummary(context, c),
      ],
    );
  }

  Widget _buildVendorSection(BuildContext context, CartController c, dynamic vendorData) {
    final items = vendorData['items'] as List<dynamic>? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vendor info header
        GestureDetector(
          onTap: () => Get.toNamed(AppRoutes.vendorDetail, arguments: {'vendor_id': vendorData['id']?.toString()}),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.cx.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: vendorData['logo_url'] ?? '',
                  width: 40, height: 40, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 40, height: 40, color: context.cx.surface,
                    child: Icon(Icons.store, size: 20, color: context.cx.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(vendorData['name'] ?? '',
                    style: TextStyle(color: context.cx.textPrimary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          ),
        ),
        // Vendor Items
        ...items.map((item) => _buildCartItem(context, c, item)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCartItem(BuildContext context, CartController c, dynamic item) {
    final qty = int.tryParse(item['quantity'].toString()) ?? 1;
    final basePrice = double.tryParse(item['base_price'].toString()) ?? 0;
    final discountPrice = double.tryParse(item['discount_price']?.toString() ?? '') ?? 0;
    final hasDiscount = discountPrice > 0 && discountPrice < basePrice;
    final effectivePrice = hasDiscount ? discountPrice : basePrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cx.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: item['image_url'] ?? '',
              width: 65, height: 65, fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 65, height: 65, color: context.cx.surface,
                child: Icon(Icons.fastfood, color: context.cx.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'] ?? '',
                    style: TextStyle(color: context.cx.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                // Price row with discount
                Row(
                  children: [
                    Text('${AppConstants.currency} ${effectivePrice.toStringAsFixed(2)}',
                        style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 14)),
                    if (hasDiscount) ...[
                      const SizedBox(width: 6),
                      Text('${AppConstants.currency} ${basePrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: context.cx.textSecondary,
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: context.cx.textSecondary,
                          )),
                    ],
                  ],
                ),
                // Savings badge
                if (hasDiscount)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${'You save'.tr} ${AppConstants.currency} ${((basePrice - discountPrice) * qty).toStringAsFixed(2)}',
                        style: const TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                if (item['notes'] != null && item['notes'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(item['notes'], style: TextStyle(color: context.cx.textSecondary, fontSize: 11)),
                  ),
              ],
            ),
          ),
          // Qty controls
          Column(
            children: [
              // Delete
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => c.removeItem(item['cart_item_id'].toString()),
                  borderRadius: BorderRadius.circular(8),
                  splashColor: AppColors.error.withValues(alpha: 0.2),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: context.cx.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _qtyButton(Icons.remove, () {
                      if (qty > 1) {
                        c.updateQuantity(item['cart_item_id'].toString(), qty - 1);
                      } else {
                        c.removeItem(item['cart_item_id'].toString());
                      }
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('$qty', style: TextStyle(color: context.cx.textPrimary, fontWeight: FontWeight.w600)),
                    ),
                    _qtyButton(Icons.add, () {
                      c.updateQuantity(item['cart_item_id'].toString(), qty + 1);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: AppColors.primaryOrange.withValues(alpha: 0.2),
        highlightColor: AppColors.primaryOrange.withValues(alpha: 0.1),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: AppColors.primaryOrange),
        ),
      ),
    );
  }

  Widget _buildBottomSummary(BuildContext context, CartController c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      decoration: BoxDecoration(
        color: context.cx.appBar,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, -3))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal'.tr, style: TextStyle(color: context.cx.textSecondary)),
              Text('${AppConstants.currency} ${c.subtotal.value.toStringAsFixed(2)}',
                  style: TextStyle(color: context.cx.textPrimary, fontWeight: FontWeight.w600)),
            ],
          ),
          if (!c.meetsMinimum.value) ...[
            const SizedBox(height: 8),
            Text(
              'One or more vendors do not meet their minimum order amount'.tr,
              style: const TextStyle(color: AppColors.warning, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: c.meetsMinimum.value
                  ? () => Get.toNamed(AppRoutes.checkout)
                  : null,
              child: Text('Proceed to Checkout'.tr, style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearCart(BuildContext context, CartController c) {
    Get.dialog(AlertDialog(
      backgroundColor: context.cx.card,
      title: Text('Clear cart?'.tr, style: TextStyle(color: context.cx.textPrimary)),
      content: Text('Remove all items from your cart?'.tr,
          style: TextStyle(color: context.cx.textSecondary)),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text('Cancel'.tr)),
        TextButton(
          onPressed: () { Get.back(); c.clearCart(); },
          child: Text('Clear Cart'.tr, style: const TextStyle(color: AppColors.error)),
        ),
      ],
    ));
  }
}
