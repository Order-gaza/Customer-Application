import 'package:flutter/material.dart';
import 'package:order/app/theme/theme_colors.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/constants/app_constants.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../shared/controllers/language_controller.dart';
import '../../shared/services/fcm_service.dart';
import 'home_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  String _greetingKey() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    return Scaffold(
      backgroundColor: context.cx.scaffold,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryOrange,
          onRefresh: () {
            // Reset section loading flags on pull-to-refresh
            controller.isAdsLoading.value = true;
            controller.isFeaturedLoading.value = true;
            controller.isPopularLoading.value = true;
            controller.isCategoriesLoading.value = true;
            return controller.loadHome();
          },
          child: CustomScrollView(
            slivers: [
              // Header — always instant (uses cached name)
              SliverToBoxAdapter(child: _buildHeader(context)),
              // Search bar — always instant
              SliverToBoxAdapter(child: _buildSearchBar(context)),
              // Ads carousel — per-section loading
              SliverToBoxAdapter(child: Obx(() {
                if (controller.isAdsLoading.value) {
                  return _buildSectionShimmer(context, height: 160);
                }
                if (controller.advertisements.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _buildAdsCarousel(context, controller);
              })),
              // Top Categories
              SliverToBoxAdapter(child: Obx(() {
                if (controller.isCategoriesLoading.value) {
                  return _buildCategoryShimmer(context);
                }
                if (controller.topCategories.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _buildTopCategories(context, controller);
              })),
              // Featured vendors
              SliverToBoxAdapter(child: Obx(() {
                if (controller.isFeaturedLoading.value) {
                  return _buildVendorShimmer(context);
                }
                if (controller.featuredVendors.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _buildFeaturedVendors(context, controller);
              })),
              // Popular items
              SliverToBoxAdapter(child: Obx(() {
                if (controller.isPopularLoading.value) {
                  return _buildItemsShimmer(context);
                }
                if (controller.popularItems.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _buildPopularItems(context, controller);
              })),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final controller = HomeController.to;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greetingKey().tr,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.cx.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(() => Text(
                      controller.userName.value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: context.cx.textPrimary,
                      ),
                    )),
              ],
            ),
          ),
          // Notifications with unread badge
          Obx(() {
            final count = FcmService.to.unreadCount.value;
            return IconButton(
              onPressed: () => Get.toNamed(AppRoutes.notifications),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      color: context.cx.iconDefault, size: 28),
                  if (count > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.search),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: context.cx.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.cx.divider, width: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: context.cx.iconMuted),
              const SizedBox(width: 12),
              Text(
                'Search vendors or items...'.tr,
                style: TextStyle(
                  color: context.cx.textHint,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdsCarousel(BuildContext context, HomeController c) {
    final pageController = PageController(viewportFraction: 0.92);
    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: pageController,
            itemCount: c.advertisements.length,
            itemBuilder: (ctx, i) {
              final ad = c.advertisements[i];
              return GestureDetector(
                onTap: () => _onAdTap(ad),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: ad['image_url'] ?? '',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, __) => Container(
                        color: context.cx.surface,
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primaryOrange, strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: context.cx.surface,
                        child: Icon(Icons.image_not_supported,
                            color: context.cx.textSecondary),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SmoothPageIndicator(
          controller: pageController,
          count: c.advertisements.length,
          effect: WormEffect(
            dotWidth: 8,
            dotHeight: 8,
            activeDotColor: AppColors.primaryOrange,
            dotColor: context.cx.divider,
          ),
        ),
      ],
    );
  }

  void _onAdTap(Map<String, dynamic> ad) {
    // Record the click for analytics (fire-and-forget)
    final adId = ad['id']?.toString();
    if (adId != null && adId.isNotEmpty) {
      HomeController.to.recordAdClick(adId);
    }

    // Navigate based on what the ad is linked to
    final vendorId = ad['vendor_id']?.toString();
    final targetUrl = ad['target_url']?.toString();

    if (vendorId != null && vendorId.isNotEmpty) {
      // Navigate to vendor detail page
      Get.toNamed(AppRoutes.vendorDetail, arguments: {'vendor_id': vendorId});
    } else if (targetUrl != null && targetUrl.isNotEmpty) {
      // Open external URL in browser
      launchUrl(Uri.parse(targetUrl), mode: LaunchMode.externalApplication);
    }
    // If neither — it's just a promotional banner, do nothing
  }

  // ── Category icon helper ──
  static const _iconMap = <String, IconData>{
    'restaurant': Icons.restaurant_rounded,
    'local_pharmacy': Icons.local_pharmacy_rounded,
    'local_grocery_store': Icons.local_grocery_store_rounded,
    'local_drink': Icons.local_drink_rounded,
    'cake': Icons.cake_rounded,
    'devices': Icons.devices_rounded,
    'checkroom': Icons.checkroom_rounded,
    'health_and_safety': Icons.health_and_safety_rounded,
    'category': Icons.category_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'sports_esports': Icons.sports_esports_rounded,
    'auto_awesome': Icons.auto_awesome_rounded,
    'pets': Icons.pets_rounded,
    'home_repair_service': Icons.home_repair_service_rounded,
    'menu_book': Icons.menu_book_rounded,
    'local_florist': Icons.local_florist_rounded,
    'build': Icons.build_rounded,
    'directions_car': Icons.directions_car_rounded,
    'child_care': Icons.child_care_rounded,
    'cleaning_services': Icons.cleaning_services_rounded,
  };

  static IconData _resolveIcon(String? iconName) =>
      _iconMap[iconName] ?? Icons.category_rounded;

  /// Get display name based on current language
  static String _catDisplayName(dynamic cat) {
    if (LanguageController.to.isArabic) {
      final ar = cat['name_ar']?.toString();
      if (ar != null && ar.isNotEmpty) return ar;
    }
    return cat['name']?.toString() ?? '';
  }

  static String _displayName(dynamic data,
      {String key = 'name', String arKey = 'name_ar'}) {
    if (LanguageController.to.isArabic) {
      final ar = data[arKey]?.toString();
      if (ar != null && ar.isNotEmpty) return ar;
    }
    return data[key]?.toString() ?? '';
  }

  static String _displayDesc(dynamic data) {
    if (LanguageController.to.isArabic) {
      final ar = data['description_ar']?.toString();
      if (ar != null && ar.isNotEmpty) return ar;
    }
    return data['description']?.toString() ?? '';
  }

  static const _categoryGradients = [
    [Color(0xFFFF6B35), Color(0xFFFF8F65)],
    [Color(0xFF4ECDC4), Color(0xFF6EE7DE)],
    [Color(0xFF845EC2), Color(0xFFA178DF)],
    [Color(0xFFFF6F91), Color(0xFFFF9AB5)],
    [Color(0xFF008F7A), Color(0xFF00BFA5)],
    [Color(0xFFFC5C7D), Color(0xFF6A82FB)],
    [Color(0xFFF7971E), Color(0xFFFFD200)],
    [Color(0xFF0083B0), Color(0xFF00B4DB)],
  ];

  Widget _buildTopCategories(BuildContext context, HomeController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Categories'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.cx.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.allCategories),
                child: Text('View All'.tr,
                    style: const TextStyle(
                        color: AppColors.primaryOrange, fontSize: 13)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: c.topCategories.length,
            itemBuilder: (ctx, i) {
              final cat = c.topCategories[i];
              final gradColors =
                  _categoryGradients[i % _categoryGradients.length];
              return GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.categoryItems, arguments: {
                  'category_id': cat['id'],
                  'category_name': _catDisplayName(cat),
                }),
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradColors,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradColors[0].withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _resolveIcon(cat['icon_name']?.toString()),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          _catDisplayName(cat),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Text(
                        '${cat['items_count'] ?? 0} ${'items'.tr}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedVendors(BuildContext context, HomeController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Vendors'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.cx.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.allVendors),
                child: Text('View All'.tr,
                    style: const TextStyle(
                        color: AppColors.primaryOrange, fontSize: 13)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: c.featuredVendors.length,
            itemBuilder: (ctx, i) {
              final v = c.featuredVendors[i];
              return _buildVendorCard(context, v);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVendorCard(BuildContext context, dynamic v) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.vendorDetail,
          arguments: {'vendor_id': v['id']}),
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: context.cx.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: v['logo_url'] ?? '',
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(height: 100, color: context.cx.surface),
                errorWidget: (_, __, ___) => Container(
                  height: 100,
                  color: context.cx.surface,
                  child: Icon(Icons.store,
                      color: context.cx.textSecondary, size: 36),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName(v, key: 'name', arKey: 'name_ar'),
                    style: TextStyle(
                      color: context.cx.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.goldenYellow, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        (v['rating'] ?? '0').toString(),
                        style: TextStyle(
                            color: context.cx.textSecondary, fontSize: 12),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primaryOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          AppConstants.vendorTypeLabel(
                              v['type'] ?? 'restaurant'),
                          style: const TextStyle(
                            color: AppColors.primaryOrange,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (v['is_currently_open'] == true || v['is_currently_open'] == 1 || v['is_currently_open'] == '1')
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (v['is_currently_open'] == true || v['is_currently_open'] == 1 || v['is_currently_open'] == '1')
                            ? 'Open'.tr
                            : 'Closed'.tr,
                        style: TextStyle(
                            fontSize: 11, color: context.cx.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularItems(BuildContext context, HomeController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Popular Items'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.cx.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.allItems),
                child: Text('View All'.tr,
                    style: const TextStyle(
                        color: AppColors.primaryOrange, fontSize: 13)),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: c.popularItems.length,
          itemBuilder: (ctx, i) {
            final item = c.popularItems[i];
            return _buildPopularItemCard(context, item);
          },
        ),
      ],
    );
  }

  Widget _buildPopularItemCard(BuildContext context, dynamic item) {
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
                                color: context.cx.textSecondary, fontSize: 12),
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
                                _displayName(item,
                                    key: 'vendor_name',
                                    arKey: 'vendor_name_ar'),
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
                                  decorationColor: context.cx.textSecondary,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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

  /// Generic section shimmer (ads banner, etc.)
  Widget _buildSectionShimmer(BuildContext context, {required double height}) {
    return Shimmer.fromColors(
      baseColor: context.cx.shimmerBase,
      highlightColor: context.cx.shimmerHighlight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  /// Category row shimmer
  Widget _buildCategoryShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.cx.shimmerBase,
      highlightColor: context.cx.shimmerHighlight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 18, width: 140,
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(8)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: Row(
                children: List.generate(4, (_) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16)),
                  ),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Vendor cards shimmer
  Widget _buildVendorShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.cx.shimmerBase,
      highlightColor: context.cx.shimmerHighlight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 18, width: 160,
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(8)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: Row(
                children: List.generate(3, (_) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16)),
                  ),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Popular items list shimmer
  Widget _buildItemsShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.cx.shimmerBase,
      highlightColor: context.cx.shimmerHighlight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 18, width: 130,
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(8)),
            ),
            const SizedBox(height: 12),
            ...List.generate(3, (_) => Container(
              height: 110,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14)),
            )),
          ],
        ),
      ),
    );
  }
}

