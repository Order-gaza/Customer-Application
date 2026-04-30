import 'package:flutter/material.dart';
import 'package:order/app/theme/theme_colors.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../app/constants/api_endpoints.dart';
import '../../../app/constants/app_constants.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/providers/api_provider.dart';
import '../../../shared/controllers/language_controller.dart';

class CategoryItemsView extends StatefulWidget {
  const CategoryItemsView({super.key});
  @override
  State<CategoryItemsView> createState() => _CategoryItemsViewState();
}

class _CategoryItemsViewState extends State<CategoryItemsView>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _category;
  List<dynamic> _vendors = [];
  List<dynamic> _items = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Get display name based on current language
  String _displayName(dynamic data, {String key = 'name', String arKey = 'name_ar'}) {
    if (LanguageController.to.isArabic) {
      final ar = data[arKey]?.toString();
      if (ar != null && ar.isNotEmpty) return ar;
    }
    return data[key]?.toString() ?? '';
  }

  String _displayDesc(dynamic data) {
    if (LanguageController.to.isArabic) {
      final ar = data['description_ar']?.toString();
      if (ar != null && ar.isNotEmpty) return ar;
    }
    return data['description']?.toString() ?? '';
  }

  Future<void> _load() async {
    final categoryId = Get.arguments?['category_id'];
    if (categoryId == null) return;

    final res = await ApiProvider.get(
      ApiEndpoints.itemsByGlobalCategory,
      queryParams: {'category_id': categoryId.toString()},
    );
    if (res.success && res.data != null) {
      _category = res.data['category'];
      _vendors = res.data['vendors'] ?? [];
      _items = res.data['items'] ?? [];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final categoryName =
        Get.arguments?['category_name'] ?? _displayName(_category ?? {});

    return Scaffold(
      backgroundColor: context.cx.scaffold,
      appBar: AppBar(
        title: Text(categoryName,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.cx.textPrimary)),
        backgroundColor: context.cx.scaffold,
        foregroundColor: context.cx.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: _isLoading
            ? null
            : TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryOrange,
                unselectedLabelColor: context.cx.textSecondary,
                indicatorColor: AppColors.primaryOrange,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.store_rounded, size: 18),
                        const SizedBox(width: 6),
                        Text('Vendors'.tr),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${_vendors.length}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fastfood_rounded, size: 18),
                        const SizedBox(width: 6),
                        Text('Items'.tr),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${_items.length}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      body: _isLoading
          ? _buildShimmer(context)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVendorsTab(context),
                _buildItemsTab(context),
              ],
            ),
    );
  }

  // ─── Vendors Tab ───
  Widget _buildVendorsTab(BuildContext context) {
    if (_vendors.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store_outlined,
                size: 64, color: context.cx.textSecondary),
            const SizedBox(height: 16),
            Text('No vendors in this category'.tr,
                style: TextStyle(
                    color: context.cx.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primaryOrange,
      onRefresh: () async {
        setState(() => _isLoading = true);
        await _load();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _vendors.length,
        itemBuilder: (ctx, i) => _buildVendorCard(context, _vendors[i]),
      ),
    );
  }

  Widget _buildVendorCard(BuildContext context, dynamic vendor) {
    final isOpen = (vendor['is_currently_open'] ?? vendor['is_open'] ?? 1) == 1;
    final rating = double.tryParse(vendor['rating_avg']?.toString() ?? '0') ?? 0;
    final ratingCount = int.tryParse(vendor['rating_count']?.toString() ?? '0') ?? 0;

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.vendorDetail,
          arguments: {'vendor_id': vendor['id']}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: vendor['cover_url'] ?? '',
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        height: 120, color: context.cx.surface),
                    errorWidget: (_, __, ___) => Container(
                      height: 120,
                      color: context.cx.surface,
                      child: Icon(Icons.store,
                          size: 40, color: context.cx.textSecondary),
                    ),
                  ),
                  // Open/closed badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? AppColors.success.withValues(alpha: 0.9)
                            : AppColors.error.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isOpen ? 'Open'.tr : 'Closed'.tr,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: vendor['logo_url'] ?? '',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          width: 48,
                          height: 48,
                          color: context.cx.surface),
                      errorWidget: (_, __, ___) => Container(
                        width: 48,
                        height: 48,
                        color: AppColors.primaryOrange.withValues(alpha: 0.1),
                        child: const Icon(Icons.store,
                            color: AppColors.primaryOrange, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vendor['name'] ?? '',
                            style: TextStyle(
                                color: context.cx.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (rating > 0) ...[
                              Icon(Icons.star_rounded,
                                  color: AppColors.goldenYellow, size: 16),
                              const SizedBox(width: 2),
                              Text(rating.toStringAsFixed(1),
                                  style: TextStyle(
                                      color: context.cx.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              Text(' ($ratingCount)',
                                  style: TextStyle(
                                      color: context.cx.textSecondary,
                                      fontSize: 11)),
                              const SizedBox(width: 12),
                            ],
                            Icon(Icons.fastfood_rounded,
                                size: 14,
                                color: context.cx.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                                '${vendor['items_count'] ?? 0} ${'items'.tr}',
                                style: TextStyle(
                                    color: context.cx.textSecondary,
                                    fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: context.cx.textSecondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Items Tab ───
  Widget _buildItemsTab(BuildContext context) {
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: context.cx.textSecondary),
            const SizedBox(height: 16),
            Text('No items in this category'.tr,
                style: TextStyle(
                    color: context.cx.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primaryOrange,
      onRefresh: () async {
        setState(() => _isLoading = true);
        await _load();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (ctx, i) => _buildItemCard(context, _items[i]),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, dynamic item) {
    final hasDiscount = item['discount_price'] != null &&
        item['discount_price'].toString().isNotEmpty &&
        double.tryParse(item['discount_price'].toString()) != null &&
        double.parse(item['discount_price'].toString()) > 0;
    final displayPrice = hasDiscount
        ? item['discount_price'].toString()
        : item['base_price'].toString();

    return GestureDetector(
      onTap: () =>
          Get.toNamed(AppRoutes.itemDetail, arguments: {'item_id': item['id']}),
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
                ClipRRect(
                  borderRadius: const BorderRadiusDirectional.horizontal(
                      start: Radius.circular(14)),
                  child: CachedNetworkImage(
                    imageUrl: item['image_url'] ?? '',
                    width: 100,
                    height: 110,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        width: 100, height: 110, color: context.cx.surface),
                    errorWidget: (_, __, ___) => Container(
                      width: 100,
                      height: 110,
                      color: context.cx.surface,
                      child: Icon(Icons.fastfood,
                          color: context.cx.textSecondary, size: 30),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayName(item, key: 'name', arKey: 'name_ar'),
                          style: TextStyle(
                            color: context.cx.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_displayDesc(item).isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            _displayDesc(item),
                            style: TextStyle(
                                color: context.cx.textSecondary,
                                fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        // Vendor name
                        Row(
                          children: [
                            if (item['vendor_logo'] != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: CachedNetworkImage(
                                  imageUrl: item['vendor_logo'],
                                  width: 16,
                                  height: 16,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Flexible(
                              child: Text(
                                _displayName(item, key: 'vendor_name', arKey: 'vendor_name_ar'),
                                style: TextStyle(
                                  color: AppColors.primaryOrange
                                      .withValues(alpha: 0.8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
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
                                fontSize: 15,
                              ),
                            ),
                            if (hasDiscount) ...[
                              const SizedBox(width: 6),
                              Text(
                                '${AppConstants.currency} ${item['base_price']}',
                                style: TextStyle(
                                  color: context.cx.textSecondary,
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor:
                                      context.cx.textSecondary,
                                ),
                              ),
                            ],
                            const Spacer(),
                            if (item['preparation_time'] != null)
                              Row(
                                children: [
                                  Icon(Icons.schedule_rounded,
                                      size: 14,
                                      color: context.cx.textSecondary),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${item['preparation_time']} ${'min'.tr}',
                                    style: TextStyle(
                                      color: context.cx.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Discount badge
            if (hasDiscount)
              PositionedDirectional(
                top: 6,
                start: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.error,
                      AppColors.error.withValues(alpha: 0.8),
                    ]),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${(((double.parse(item['base_price'].toString()) - double.parse(item['discount_price'].toString())) / double.parse(item['base_price'].toString())) * 100).round()}% ${'OFF'.tr}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.cx.shimmerBase,
      highlightColor: context.cx.shimmerHighlight,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (ctx, i) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
