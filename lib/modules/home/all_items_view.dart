import 'package:flutter/material.dart';
import 'package:order/app/theme/theme_colors.dart';
import '../../shared/localization/app_translations.dart';
import '../../shared/utils/app_navigator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../app/constants/api_endpoints.dart';
import '../../app/constants/app_constants.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../data/providers/api_provider.dart';
import '../../shared/controllers/language_controller.dart';

/// View All Items page with category tabs and infinite scroll.
/// Shows all active items from all approved vendors,
/// filterable by global category.
class AllItemsView extends StatefulWidget {
  const AllItemsView({super.key});

  @override
  State<AllItemsView> createState() => _AllItemsViewState();
}

class _AllItemsViewState extends State<AllItemsView> {
  // ── Categories ──
  List<dynamic> _categories = [];
  bool _categoriesLoading = true;
  String? _selectedCategoryId; // null = "All"

  // ── Items ──
  final List<dynamic> _items = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasNext = false;
  final ScrollController _scrollC = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadItems();
    _scrollC.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollC.dispose();
    super.dispose();
  }

  // ── Helpers ──
  String _displayName(dynamic data,
      {String key = 'name', String arKey = 'name_ar'}) {
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

  // ── Data Loading ──
  Future<void> _loadCategories() async {
    final res = await ApiProvider.get(ApiEndpoints.homeTopCategories,
        queryParams: {'limit': '50'});
    setState(() {
      if (res.success && res.data != null) {
        _categories = res.data['categories'] ?? [];
      }
      _categoriesLoading = false;
    });
  }

  Future<void> _loadItems({bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _items.clear();
      });
    }

    final params = <String, String>{
      'page': '$_currentPage',
      'limit': '20',
    };
    if (_selectedCategoryId != null) {
      params['category_id'] = _selectedCategoryId!;
    }

    final res =
        await ApiProvider.get(ApiEndpoints.itemsGetAll, queryParams: params);

    setState(() {
      if (res.success && res.data != null) {
        _items.addAll(res.data['items'] ?? []);
        _hasNext = res.data['pagination']?['has_next'] ?? false;
      }
      _isLoading = false;
      _isLoadingMore = false;
    });
  }

  void _onScroll() {
    if (_scrollC.position.pixels >= _scrollC.position.maxScrollExtent - 300 &&
        !_isLoadingMore &&
        _hasNext) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    _currentPage++;
    await _loadItems(reset: false);
  }

  void _onCategoryTap(String? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _loadItems();
  }

  // ── UI ──
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cx.scaffold,
      appBar: AppBar(
        backgroundColor: context.cx.appBar,
        title: Text('All Items'.tr,
            style: TextStyle(
                color: context.cx.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: true,
        iconTheme: IconThemeData(color: context.cx.iconDefault),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Category Tabs ──
          _buildCategoryTabs(),
          // ── Items List ──
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : _items.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: AppColors.primaryOrange,
                        onRefresh: () => _loadItems(),
                        child: ListView.builder(
                          controller: _scrollC,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount:
                              _items.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (ctx, i) {
                            if (i == _items.length) {
                              return const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                    child: CircularProgressIndicator(
                                        color: AppColors.primaryOrange,
                                        strokeWidth: 2)),
                              );
                            }
                            return _buildItemCard(_items[i]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ── Category Chips (horizontal scrollable) ──
  Widget _buildCategoryTabs() {
    if (_categoriesLoading) {
      return Container(
        height: 52,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Shimmer.fromColors(
          baseColor: context.cx.shimmerBase,
          highlightColor: context.cx.shimmerHighlight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            itemBuilder: (_, __) => Container(
              width: 80,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: context.cx.appBar,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _categories.length + 1, // +1 for "All" tab
        itemBuilder: (ctx, i) {
          if (i == 0) {
            // "All" chip
            final isSelected = _selectedCategoryId == null;
            return _buildChip(
              label: 'All'.tr,
              isSelected: isSelected,
              onTap: () => _onCategoryTap(null),
            );
          }
          final cat = _categories[i - 1];
          final catId = cat['id']?.toString();
          final isSelected = _selectedCategoryId == catId;
          return _buildChip(
            label: _displayName(cat, key: 'name', arKey: 'name_ar'),
            isSelected: isSelected,
            onTap: () => _onCategoryTap(catId),
          );
        },
      ),
    );
  }

  Widget _buildChip(
      {required String label,
      required bool isSelected,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryOrange
              : context.cx.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryOrange
                : context.cx.divider,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : context.cx.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  // ── Item Card ──
  Widget _buildItemCard(dynamic item) {
    final hasDiscount = item['discount_price'] != null &&
        item['discount_price'].toString().isNotEmpty &&
        double.tryParse(item['discount_price'].toString()) != null &&
        double.parse(item['discount_price'].toString()) > 0 &&
        double.parse(item['discount_price'].toString()) <
            (double.tryParse(item['base_price']?.toString() ?? '0') ?? 0);
    final displayPrice = hasDiscount
        ? item['discount_price'].toString()
        : item['base_price'].toString();
    final basePrice =
        double.tryParse(item['base_price']?.toString() ?? '0') ?? 0;
    final discPrice =
        double.tryParse(item['discount_price']?.toString() ?? '0') ?? 0;
    final discountPct = hasDiscount && basePrice > 0
        ? ((basePrice - discPrice) / basePrice * 100).round()
        : 0;

    return GestureDetector(
      onTap: () => AppNavigator.toNamed(AppRoutes.itemDetail,
          arguments: {'item_id': item['id']}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: context.cx.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: const BorderRadiusDirectional.horizontal(
                      start: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: item['image_url'] ?? '',
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        width: 110, height: 110, color: context.cx.surface),
                    errorWidget: (_, __, ___) => Container(
                      width: 110,
                      height: 110,
                      color: context.cx.surface,
                      child: Icon(Icons.fastfood,
                          color: context.cx.textSecondary, size: 30),
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
                        // Price row
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
                                mainAxisSize: MainAxisSize.min,
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
            if (hasDiscount && discountPct > 0)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color:
                            const Color(0xFFFF416C).withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '-$discountPct%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
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

  // ── Empty State ──
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fastfood_outlined, size: 64, color: context.cx.textHint),
          const SizedBox(height: 16),
          Text('No items available'.tr,
              style:
                  TextStyle(color: context.cx.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }

  // ── Shimmer Loading ──
  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: context.cx.shimmerBase,
      highlightColor: context.cx.shimmerHighlight,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          height: 110,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
