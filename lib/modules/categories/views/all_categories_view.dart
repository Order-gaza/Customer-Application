import 'package:flutter/material.dart';
import 'package:order/app/theme/theme_colors.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../../app/constants/api_endpoints.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/providers/api_provider.dart';
import '../../../shared/controllers/language_controller.dart';

class AllCategoriesView extends StatefulWidget {
  const AllCategoriesView({super.key});
  @override
  State<AllCategoriesView> createState() => _AllCategoriesViewState();
}

class _AllCategoriesViewState extends State<AllCategoriesView> {
  List<dynamic> _categories = [];
  bool _isLoading = true;

  static const _gradients = [
    [Color(0xFFFF6B35), Color(0xFFFF8F65)],
    [Color(0xFF4ECDC4), Color(0xFF6EE7DE)],
    [Color(0xFF845EC2), Color(0xFFA178DF)],
    [Color(0xFFFF6F91), Color(0xFFFF9AB5)],
    [Color(0xFF008F7A), Color(0xFF00BFA5)],
    [Color(0xFFFC5C7D), Color(0xFF6A82FB)],
    [Color(0xFFF7971E), Color(0xFFFFD200)],
    [Color(0xFF0083B0), Color(0xFF00B4DB)],
    [Color(0xFFED4264), Color(0xFFFFEDBC)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
  ];

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await ApiProvider.get(
      ApiEndpoints.homeTopCategories,
      queryParams: {'limit': '50'},
    );
    if (res.success && res.data != null) {
      _categories = res.data['categories'] ?? [];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cx.scaffold,
      appBar: AppBar(
        title: Text('All Categories'.tr),
        backgroundColor: context.cx.scaffold,
        foregroundColor: context.cx.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _isLoading
          ? _buildShimmer(context)
          : _categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.category_outlined,
                          size: 64, color: context.cx.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        'No categories found'.tr,
                        style: TextStyle(
                          color: context.cx.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primaryOrange,
                  onRefresh: () async {
                    setState(() => _isLoading = true);
                    await _load();
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.0,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (ctx, i) {
                      final cat = _categories[i];
                      final gradColors = _gradients[i % _gradients.length];
                      return _buildCategoryCard(context, cat, gradColors);
                    },
                  ),
                ),
    );
  }

  Widget _buildCategoryCard(
      BuildContext context, dynamic cat, List<Color> gradColors) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.categoryItems, arguments: {
        'category_id': cat['id'],
        'category_name': _catDisplayName(cat),
      }),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradColors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradColors[0].withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern icon
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                _resolveIcon(cat['icon_name']?.toString()),
                size: 100,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _resolveIcon(cat['icon_name']?.toString()),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _catDisplayName(cat),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Show vendors count instead of vendor name
                  Text(
                    '${cat['vendors_count'] ?? 0} ${'vendors'.tr}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${cat['items_count'] ?? 0} ${'items'.tr}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
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
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
        ),
        itemCount: 6,
        itemBuilder: (ctx, i) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
