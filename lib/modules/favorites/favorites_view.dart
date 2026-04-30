import 'package:flutter/material.dart';
import 'package:order/app/theme/theme_colors.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/constants/app_constants.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import 'favorites_controller.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.cx.scaffold,
        appBar: AppBar(
          backgroundColor: context.cx.appBar,
          title: Text('Favorites'.tr,
              style: TextStyle(
                  color: context.cx.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          centerTitle: true,
          automaticallyImplyLeading: false,
          bottom: TabBar(
            indicatorColor: AppColors.primaryOrange,
            indicatorWeight: 3,
            labelColor: AppColors.primaryOrange,
            unselectedLabelColor: context.cx.textSecondary,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: [
              Tab(
                icon: const Icon(Icons.store_rounded, size: 20),
                text: 'Vendors'.tr,
              ),
              Tab(
                icon: const Icon(Icons.fastfood_rounded, size: 20),
                text: 'Items'.tr,
              ),
            ],
          ),
        ),
        body: Obx(() {
          final c = FavoritesController.to;
          if (c.isLoading.value && c.totalCount == 0) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryOrange, strokeWidth: 2.5));
          }
          return TabBarView(
            children: [
              _buildVendorsTab(context, c),
              _buildItemsTab(context, c),
            ],
          );
        }),
      ),
    );
  }

  // ── VENDORS TAB ──
  Widget _buildVendorsTab(BuildContext context, FavoritesController c) {
    if (c.favoriteVendors.isEmpty) {
      return _buildEmptyState(
        context,
        Icons.store_mall_directory_outlined,
        'No favorite vendors yet'.tr,
        'Browse vendors and tap the heart icon to save'.tr,
      );
    }
    return RefreshIndicator(
      color: AppColors.primaryOrange,
      onRefresh: c.loadFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: c.favoriteVendors.length,
        itemBuilder: (ctx, i) =>
            _buildVendorCard(context, c, c.favoriteVendors[i]),
      ),
    );
  }

  Widget _buildVendorCard(BuildContext context, FavoritesController c, dynamic v) {
    final isOpen = v['is_currently_open'] == true || v['is_currently_open'] == 1 ||
        v['is_currently_open'] == '1';
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.vendorDetail,
          arguments: {'vendor_id': v['id']}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: context.cx.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Vendor logo
            ClipRRect(
              borderRadius: const BorderRadiusDirectional.horizontal(
                  start: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: v['logo_url'] ?? '',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                    width: 100, height: 100, color: context.cx.surface),
                errorWidget: (_, __, ___) => Container(
                  width: 100,
                  height: 100,
                  color: context.cx.surface,
                  child: Icon(Icons.store,
                      color: context.cx.textSecondary, size: 36),
                ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v['name'] ?? '',
                      style: TextStyle(
                          color: context.cx.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.goldenYellow, size: 15),
                        const SizedBox(width: 3),
                        Text((v['rating'] ?? '0').toString(),
                            style: TextStyle(
                                color: context.cx.textSecondary,
                                fontSize: 12)),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            AppConstants.vendorTypeLabel(
                                v['type'] ?? 'restaurant'),
                            style: const TextStyle(
                                color: AppColors.primaryOrange,
                                fontSize: 10,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isOpen ? AppColors.success : AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isOpen ? 'Open'.tr : 'Closed'.tr,
                          style: TextStyle(
                              fontSize: 12,
                              color: context.cx.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Heart button
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: Obx(() => GestureDetector(
                    onTap: () =>
                        c.toggleFavorite('vendor', v['id'].toString()),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        c.isVendorFavorite(v['id'].toString())
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        key: ValueKey(
                            c.isVendorFavorite(v['id'].toString())),
                        color: AppColors.error,
                        size: 24,
                      ),
                    ),
                  )),
            ),
          ],
        ),
      ),
    );
  }

  // ── ITEMS TAB ──
  Widget _buildItemsTab(BuildContext context, FavoritesController c) {
    if (c.favoriteItems.isEmpty) {
      return _buildEmptyState(
        context,
        Icons.fastfood_outlined,
        'No favorite items yet'.tr,
        'Browse menus and tap the heart icon to save'.tr,
      );
    }
    return RefreshIndicator(
      color: AppColors.primaryOrange,
      onRefresh: c.loadFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: c.favoriteItems.length,
        itemBuilder: (ctx, i) =>
            _buildItemCard(context, c, c.favoriteItems[i]),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, FavoritesController c, dynamic item) {
    final hasDiscount = item['discount_price'] != null &&
        item['discount_price'].toString().isNotEmpty &&
        double.tryParse(item['discount_price'].toString()) != null &&
        double.parse(item['discount_price'].toString()) > 0;
    final displayPrice = hasDiscount
        ? item['discount_price'].toString()
        : item['base_price'].toString();

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.itemDetail,
          arguments: {'item_id': item['id']}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: context.cx.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: const BorderRadiusDirectional.horizontal(
                      start: Radius.circular(14)),
                  child: CachedNetworkImage(
                    imageUrl: item['image_url'] ?? '',
                    width: 95,
                    height: 95,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        width: 95,
                        height: 95,
                        color: context.cx.surface),
                    errorWidget: (_, __, ___) => Container(
                      width: 95,
                      height: 95,
                      color: context.cx.surface,
                      child: Icon(Icons.fastfood,
                          color: context.cx.textSecondary, size: 28),
                    ),
                  ),
                ),
                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] ?? '',
                          style: TextStyle(
                              color: context.cx.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.store_rounded,
                                size: 12,
                                color:
                                    context.cx.iconMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item['vendor_name'] ?? '',
                                style: TextStyle(
                                    color: context.cx.textSecondary,
                                    fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              '${AppConstants.currency} $displayPrice',
                              style: const TextStyle(
                                  color: AppColors.primaryOrange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                            if (hasDiscount) ...[
                              const SizedBox(width: 6),
                              Text(
                                '${AppConstants.currency} ${item['base_price']}',
                                style: TextStyle(
                                  color: context.cx.textSecondary,
                                  fontSize: 11,
                                  decoration:
                                      TextDecoration.lineThrough,
                                  decorationColor: context.cx.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Heart button
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: Obx(() => GestureDetector(
                        onTap: () => c.toggleFavorite(
                            'item', item['id'].toString()),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(
                                  scale: anim, child: child),
                          child: Icon(
                            c.isItemFavorite(item['id'].toString())
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            key: ValueKey(c.isItemFavorite(
                                item['id'].toString())),
                            color: AppColors.error,
                            size: 24,
                          ),
                        ),
                      )),
                ),
              ],
            ),
            // Discount badge
            if (hasDiscount)
              PositionedDirectional(
                top: 5,
                start: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '${(((double.parse(item['base_price'].toString()) - double.parse(item['discount_price'].toString())) / double.parse(item['base_price'].toString())) * 100).round()}% ${'OFF'.tr}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 72, color: context.cx.textHint),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(
                  color: context.cx.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: context.cx.textSecondary,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
