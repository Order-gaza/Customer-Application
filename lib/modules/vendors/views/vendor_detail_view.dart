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
import '../../cart/cart_controller.dart';
import '../../favorites/favorites_controller.dart';

class VendorDetailView extends StatefulWidget {
  const VendorDetailView({super.key});

  @override
  State<VendorDetailView> createState() => _VendorDetailViewState();
}

class _VendorDetailViewState extends State<VendorDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabC;
  bool _isLoading = true;
  Map<String, dynamic>? _vendor;
  List<dynamic> _menuCategories = [];
  List<dynamic> _ratings = [];

  String _displayName(dynamic data) {
    if (LanguageController.to.isArabic) {
      final ar = data['name_ar']?.toString();
      if (ar != null && ar.isNotEmpty) return ar;
    }
    return data['name']?.toString() ?? '';
  }

  String _displayDesc(dynamic data) {
    if (LanguageController.to.isArabic) {
      final ar = data['description_ar']?.toString();
      if (ar != null && ar.isNotEmpty) return ar;
    }
    return data['description']?.toString() ?? '';
  }

  @override
  void initState() {
    super.initState();
    _tabC = TabController(length: 3, vsync: this);
    _loadVendor();
  }

  Future<void> _loadVendor() async {
    final vendorId = Get.arguments?['vendor_id'];
    if (vendorId == null) return;

    final results = await Future.wait([
      ApiProvider.get(ApiEndpoints.vendorsGetById,
          queryParams: {'id': vendorId.toString()}),
      ApiProvider.get(ApiEndpoints.vendorsGetMenu,
          queryParams: {'vendor_id': vendorId.toString()}),
      ApiProvider.get(ApiEndpoints.vendorsGetRatings,
          queryParams: {'vendor_id': vendorId.toString()}),
    ]);

    setState(() {
      if (results[0].success) _vendor = results[0].data?['vendor'];
      // get_menu.php returns data['menu'] as array of {category: {...}, items: [...]}
      if (results[1].success) _menuCategories = results[1].data?['menu'] ?? [];
      if (results[2].success) _ratings = results[2].data?['ratings'] ?? [];
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.cx.scaffold,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _buildLoadingShimmer(),
      );
    }

    if (_vendor == null) {
      return Scaffold(
        backgroundColor: context.cx.scaffold,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 60, color: context.cx.textHint),
              const SizedBox(height: 12),
              Text('Vendor not found'.tr,
                  style: TextStyle(color: context.cx.textSecondary)),
            ],
          ),
        ),
      );
    }

    final isOpen =
        _vendor!['is_currently_open'] == true || _vendor!['is_currently_open'] == 1 ||
        _vendor!['is_currently_open'] == '1';

    return Scaffold(
      backgroundColor: context.cx.scaffold,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: context.cx.appBar,
            iconTheme: IconThemeData(color: context.cx.iconDefault),
            elevation: 0,
            actions: [
              Obx(() {
                final vendorId = _vendor!['id'].toString();
                final isFav = FavoritesController.to.isVendorFavorite(vendorId);
                return IconButton(
                  onPressed: () => FavoritesController.to.toggleFavorite('vendor', vendorId),
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      key: ValueKey(isFav),
                      color: isFav ? AppColors.error : context.cx.iconDefault,
                      size: 26,
                    ),
                  ),
                );
              }),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover image (fallback to logo)
                  CachedNetworkImage(
                    imageUrl: _vendor!['cover_url'] ??
                        _vendor!['logo_url'] ??
                        '',
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: context.cx.surface),
                    errorWidget: (_, __, ___) => Container(
                      color: context.cx.surface,
                      child: Icon(Icons.store,
                          color: context.cx.textSecondary, size: 60),
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                  // Vendor info overlay
                  Positioned(
                    bottom: 60,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        // Logo
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.primaryOrange
                                    .withValues(alpha: 0.5),
                                width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: _vendor!['logo_url'] ?? '',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                width: 60,
                                height: 60,
                                color: context.cx.surface,
                                child: Icon(Icons.store,
                                    color: context.cx.textSecondary),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Vendor name & info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _vendor!['name'] ?? '',
                                style: TextStyle(
                                  color: context.cx.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  // Rating
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.goldenYellow
                                          .withValues(alpha: 0.2),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star_rounded,
                                            color: AppColors.goldenYellow,
                                            size: 14),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${_vendor!['rating'] ?? '0'}',
                                          style: TextStyle(
                                              color: context.cx.textPrimary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Type badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryOrange
                                          .withValues(alpha: 0.2),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      AppConstants.vendorTypeLabel(
                                          _vendor!['type'] ??
                                              'restaurant'),
                                      style: const TextStyle(
                                        color: AppColors.primaryOrange,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Open/Closed
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isOpen
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isOpen ? 'Open'.tr : 'Closed'.tr,
                                    style: TextStyle(
                                        color: context.cx.textPrimary,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottom: TabBar(
              controller: _tabC,
              indicatorColor: AppColors.primaryOrange,
              indicatorWeight: 3,
              labelColor: AppColors.primaryOrange,
              unselectedLabelColor: context.cx.textSecondary,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14),
              tabs: [
                Tab(text: 'Menu'.tr),
                Tab(text: 'Reviews'.tr),
                Tab(text: 'Info'.tr),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabC,
          children: [
            _buildMenu(),
            _buildReviews(),
            _buildInfo(),
          ],
        ),
      ),
    );
  }

  // ── MENU TAB ──
  Widget _buildMenu() {
    if (_menuCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu_rounded,
                size: 56, color: context.cx.textHint),
            const SizedBox(height: 12),
            Text('No items available'.tr,
                style: TextStyle(
                    color: context.cx.textSecondary, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _menuCategories.length,
      itemBuilder: (ctx, ci) {
        final menuEntry = _menuCategories[ci];
        // get_menu.php returns {category: {id, name, ...}, items: [...]}
        final category = menuEntry['category'] ?? {};
        final items = menuEntry['items'] as List? ?? [];
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category['name_ar'] != null && LanguageController.to.isArabic
                        ? category['name_ar']
                        : category['name'] ?? '',
                    style: TextStyle(
                      color: context.cx.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${items.length})',
                    style: TextStyle(
                        color: context.cx.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            ...items.map((item) => _buildMenuItem(item)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildMenuItem(dynamic item) {
    final isOpen = _vendor != null &&
        (_vendor!['is_currently_open'] == true ||
         _vendor!['is_currently_open'] == 1 ||
         _vendor!['is_currently_open'] == '1');
    final available =
        item['is_available'] == 1 || item['is_available'] == true;
    final basePrice = item['base_price'] ?? '0';
    final discountPrice = item['discount_price'];
    final hasDiscount = discountPrice != null &&
        discountPrice.toString().isNotEmpty &&
        double.tryParse(discountPrice.toString()) != null &&
        double.parse(discountPrice.toString()) > 0;
    final displayPrice = hasDiscount ? discountPrice.toString() : basePrice.toString();

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.itemDetail,
          arguments: {'item_id': item['id']}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: context.cx.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: context.cx.divider.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                // Item image
                ClipRRect(
                  borderRadius: const BorderRadiusDirectional.horizontal(
                      start: Radius.circular(14)),
                  child: CachedNetworkImage(
                    imageUrl: item['image_url'] ?? '',
                    width: 95,
                    height: 95,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        width: 95, height: 95, color: context.cx.surface),
                    errorWidget: (_, __, ___) => Container(
                      width: 95,
                      height: 95,
                      color: context.cx.surface,
                      child: Icon(Icons.fastfood,
                          color: context.cx.textSecondary, size: 28),
                    ),
                  ),
                ),
                // Item details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayName(item),
                          style: TextStyle(
                            color: context.cx.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_displayDesc(item).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _displayDesc(item),
                              style: TextStyle(
                                  color: context.cx.textSecondary,
                                  fontSize: 12,
                                  height: 1.3),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Price with discount
                            Expanded(
                              child: Row(
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
                                      '${AppConstants.currency} $basePrice',
                                      style: TextStyle(
                                        color: context.cx.textSecondary,
                                        fontSize: 11,
                                        decoration: TextDecoration.lineThrough,
                                        decorationColor:
                                            context.cx.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (available && isOpen)
                          GestureDetector(
                            onTap: () {
                              CartController.to
                                  .addToCart(item['id'].toString());
                              if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
                              Get.snackbar(
                                'Added to Cart'.tr,
                                '',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor:
                                    AppColors.success.withValues(alpha: 0.9),
                                colorText: Colors.white,
                                margin: const EdgeInsets.all(12),
                                duration: const Duration(seconds: 3),
                                icon: const Icon(Icons.check_circle,
                                    color: Colors.white),
                                mainButton: TextButton(
                                  onPressed: () {
                                    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
                                    Get.offAllNamed(AppRoutes.main, arguments: {'tab': 3});
                                  },
                                  child: Text('View Cart'.tr,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primaryOrange,
                                    AppColors.darkOrange,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryOrange
                                        .withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_rounded,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 2),
                                  Icon(Icons.shopping_cart_rounded,
                                      color: Colors.white, size: 14),
                                ],
                              ),
                            ),
                          )
                        else if (available && !isOpen)
                          GestureDetector(
                            onTap: () {
                              if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
                              Get.snackbar(
                                'Vendor Closed'.tr,
                                'This vendor is currently closed. You cannot add items now.'.tr,
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: AppColors.error.withValues(alpha: 0.9),
                                colorText: Colors.white,
                                margin: const EdgeInsets.all(12),
                                duration: const Duration(seconds: 3),
                                icon: const Icon(Icons.store_rounded, color: Colors.white),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.lock_rounded,
                                      color: AppColors.error, size: 14),
                                  const SizedBox(width: 4),
                                  Text('Closed'.tr,
                                      style: const TextStyle(
                                          color: AppColors.error,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Unavailable'.tr,
                                style: const TextStyle(
                                    color: AppColors.error, fontSize: 11)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Discount badge on image
        if (hasDiscount)
          PositionedDirectional(
            top: 5,
            start: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                '${(((double.parse(basePrice.toString()) - double.parse(discountPrice.toString())) / double.parse(basePrice.toString())) * 100).round()}% ${'OFF'.tr}',
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

  // ── REVIEWS TAB ──
  Widget _buildReviews() {
    if (_ratings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rate_review_outlined,
                size: 56, color: context.cx.textHint),
            const SizedBox(height: 12),
            Text('No reviews yet'.tr,
                style: TextStyle(
                    color: context.cx.textSecondary, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ratings.length,
      itemBuilder: (ctx, i) {
        final r = _ratings[i];
        final score = int.tryParse(r['rating']?.toString() ?? r['score']?.toString() ?? '0') ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.cx.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.cx.divider.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        (r['customer_name'] ?? 'U')
                            .toString()
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      r['customer_name'] ?? '',
                      style: TextStyle(
                        color: context.cx.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  // Stars
                  Row(
                    children: List.generate(
                      5,
                      (si) => Padding(
                        padding: const EdgeInsets.only(left: 1),
                        child: Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: si < score
                              ? AppColors.goldenYellow
                              : context.cx.divider,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (r['comment'] != null &&
                  r['comment'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    r['comment'],
                    style: TextStyle(
                      color: context.cx.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              if (r['created_at'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    r['created_at'].toString().split(' ').first,
                    style: TextStyle(
                      color: context.cx.iconMuted,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── INFO TAB ──
  Widget _buildInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Description
          if (_vendor!['description'] != null &&
              _vendor!['description'].toString().isNotEmpty)
            _infoCard(
              Icons.info_outline_rounded,
              'About'.tr,
              _vendor!['description'],
            ),
          _infoCard(
            Icons.location_on_outlined,
            'Address'.tr,
            _vendor!['address'] ?? '-',
          ),
          _infoCard(
            Icons.phone_outlined,
            'Phone'.tr,
            _vendor!['phone'] ?? '-',
          ),
          _infoCard(
            Icons.access_time_rounded,
            'Est. Delivery'.tr,
            _vendor!['estimated_delivery_time'] != null
                ? '${_vendor!['estimated_delivery_time']} ${'min'.tr}'
                : '-',
          ),
          _infoCard(
            Icons.shopping_bag_outlined,
            'Min Order'.tr,
            '${AppConstants.currency} ${_vendor!['min_order_amount'] ?? '0'}',
          ),
          _infoCard(
            Icons.schedule_rounded,
            'Status'.tr,
            (_vendor!['is_currently_open'] == true || _vendor!['is_currently_open'] == 1 || _vendor!['is_currently_open'] == '1') ? 'Open'.tr : 'Closed'.tr,
          ),
          if (_vendor!['opening_time'] != null)
            _infoCard(
              Icons.wb_sunny_outlined,
              'Operating Hours'.tr,
              '${_vendor!['opening_time']} - ${_vendor!['closing_time'] ?? ''}',
            ),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cx.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryOrange, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: context.cx.textSecondary, fontSize: 12)),
                const SizedBox(height: 3),
                Text(value,
                    style: TextStyle(
                        color: context.cx.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── LOADING SHIMMER ──
  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: context.cx.shimmerBase,
      highlightColor: context.cx.shimmerHighlight,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(height: 260, color: context.cx.card),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: List.generate(
                  5,
                  (_) => Container(
                    height: 95,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: context.cx.card,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
