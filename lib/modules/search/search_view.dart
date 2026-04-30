import 'dart:async';
import 'package:order/app/theme/theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/constants/api_endpoints.dart';
import '../../app/constants/app_constants.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../data/providers/api_provider.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});
  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView>
    with SingleTickerProviderStateMixin {
  final _searchC = TextEditingController();
  final _focusNode = FocusNode();
  List<dynamic> _vendorResults = [];
  List<dynamic> _itemResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  late TabController _tabC;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabC = TabController(length: 2, vsync: this);
    // Auto-focus after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.isEmpty) {
      setState(() {
        _vendorResults = [];
        _itemResults = [];
        _hasSearched = false;
        _isLoading = false;
      });
      return;
    }
    // Debounce 400ms to avoid firing on every keystroke
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    setState(() => _isLoading = true);

    final results = await Future.wait([
      ApiProvider.get(ApiEndpoints.vendorsSearch, queryParams: {'q': query}),
      ApiProvider.get(ApiEndpoints.itemsSearch, queryParams: {'q': query}),
    ]);

    // Only update if the query hasn't changed while we were loading
    if (_searchC.text == query) {
      setState(() {
        _vendorResults =
            results[0].success ? (results[0].data?['vendors'] ?? []) : [];
        _itemResults =
            results[1].success ? (results[1].data?['items'] ?? []) : [];
        _hasSearched = true;
        _isLoading = false;
      });
    }
  }

  void _clearSearch() {
    _searchC.clear();
    _focusNode.requestFocus();
    setState(() {
      _vendorResults = [];
      _itemResults = [];
      _hasSearched = false;
      _isLoading = false;
    });
  }

  /// Determine text direction: Arabic locale = RTL, otherwise auto-detect from input
  TextDirection _getTextDirection() {
    // If locale is Arabic, default to RTL
    if (Get.locale?.languageCode == 'ar') return TextDirection.rtl;
    // Auto-detect: if text starts with Arabic char, use RTL
    if (_searchC.text.isNotEmpty) {
      final firstChar = _searchC.text[0];
      if (RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]')
          .hasMatch(firstChar)) {
        return TextDirection.rtl;
      }
    }
    return TextDirection.ltr;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchC.dispose();
    _focusNode.dispose();
    _tabC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cx.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search header ──
            _buildSearchBar(),
            // ── Tab bar (always present once searched) ──
            if (_hasSearched) _buildTabBar(),
            // ── Body ──
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
      decoration: BoxDecoration(
        color: context.cx.appBar,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: context.cx.iconDefault),
            onPressed: () => Get.back(),
          ),
          // Search field
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: context.cx.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 12),
                    child: Icon(Icons.search_rounded,
                        color: context.cx.iconMuted, size: 20),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchC,
                      focusNode: _focusNode,
                      textDirection: _getTextDirection(),
                      style: TextStyle(color: context.cx.textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Search vendors, items...'.tr,
                        hintStyle: TextStyle(
                          color: context.cx.textHint,
                          fontSize: 14,
                        ),
                        hintTextDirection: Get.locale?.languageCode == 'ar'
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 12),
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.search,
                      onChanged: (v) {
                        setState(() {}); // Rebuild for text direction + clear button
                        _onSearchChanged(v);
                      },
                      onSubmitted: (v) {
                        if (v.length >= 2) _performSearch(v);
                      },
                    ),
                  ),
                  if (_searchC.text.isNotEmpty)
                    GestureDetector(
                      onTap: _clearSearch,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(end: 10),
                        child: Icon(Icons.close_rounded,
                            color: context.cx.iconMuted,
                            size: 20),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: context.cx.appBar,
      child: TabBar(
        controller: _tabC,
        indicatorColor: AppColors.primaryOrange,
        indicatorWeight: 3,
        labelColor: AppColors.primaryOrange,
        unselectedLabelColor: context.cx.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: [
          Tab(text: '${'Vendors'.tr} (${_vendorResults.length})'),
          Tab(text: '${'Items'.tr} (${_itemResults.length})'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
            color: AppColors.primaryOrange, strokeWidth: 2.5),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded,
                size: 60, color: context.cx.textHint),
            const SizedBox(height: 14),
            Text(
              'Search for vendors and items'.tr,
              style: TextStyle(
                  color: context.cx.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              'Start typing to search'.tr,
              style: TextStyle(
                  color: context.cx.textHint, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_vendorResults.isEmpty && _itemResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 60, color: context.cx.textHint),
            const SizedBox(height: 14),
            Text('No results found'.tr,
                style: TextStyle(
                    color: context.cx.textSecondary, fontSize: 15)),
            const SizedBox(height: 6),
            Text(
              'Try a different search term'.tr,
              style: TextStyle(
                  color: context.cx.textHint, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabC,
      children: [
        _buildVendorList(),
        _buildItemList(),
      ],
    );
  }

  // ── Vendor results tab ──
  Widget _buildVendorList() {
    if (_vendorResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store_outlined,
                size: 48, color: context.cx.textHint),
            const SizedBox(height: 12),
            Text('No vendors found'.tr,
                style: TextStyle(color: context.cx.textSecondary)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _vendorResults.length,
      itemBuilder: (ctx, i) => _buildVendorResult(_vendorResults[i]),
    );
  }

  Widget _buildVendorResult(dynamic v) {
    final isOpen = v['is_currently_open'] == true || v['is_currently_open'] == 1 ||
        v['is_currently_open'] == '1';
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.vendorDetail,
          arguments: {'vendor_id': v['id']}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.cx.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Logo
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: v['logo_url'] ?? '',
                width: 55,
                height: 55,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                    width: 55, height: 55, color: context.cx.surface),
                errorWidget: (_, __, ___) => Container(
                  width: 55,
                  height: 55,
                  color: context.cx.surface,
                  child: Icon(Icons.store,
                      color: context.cx.textSecondary, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v['name'] ?? '',
                      style: TextStyle(
                          color: context.cx.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.goldenYellow, size: 14),
                      const SizedBox(width: 3),
                      Text('${v['rating'] ?? '0'}',
                          style: TextStyle(
                              color: context.cx.textSecondary, fontSize: 12)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primaryOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppConstants.vendorTypeLabel(v['type'] ?? ''),
                          style: const TextStyle(
                              color: AppColors.primaryOrange,
                              fontSize: 10,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOpen ? AppColors.success : AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOpen ? 'Open'.tr : 'Closed'.tr,
                        style: TextStyle(
                            color: context.cx.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: context.cx.iconMuted),
          ],
        ),
      ),
    );
  }

  // ── Item results tab ──
  Widget _buildItemList() {
    if (_itemResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fastfood_outlined,
                size: 48, color: context.cx.textHint),
            const SizedBox(height: 12),
            Text('No items found'.tr,
                style: TextStyle(color: context.cx.textSecondary)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _itemResults.length,
      itemBuilder: (ctx, i) => _buildItemResult(_itemResults[i]),
    );
  }

  Widget _buildItemResult(dynamic item) {
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
        margin: const EdgeInsets.only(bottom: 10),
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
                    width: 85,
                    height: 85,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        width: 85, height: 85, color: context.cx.surface),
                    errorWidget: (_, __, ___) => Container(
                      width: 85,
                      height: 85,
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
                          (Get.locale?.languageCode == 'ar' && item['name_ar'] != null && item['name_ar'].toString().isNotEmpty)
                              ? item['name_ar']
                              : (item['name'] ?? ''),
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
                            Icon(Icons.store_rounded,
                                size: 12,
                                color: context.cx.iconMuted),
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
                                fontSize: 15,
                              ),
                            ),
                            if (hasDiscount) ...[
                              const SizedBox(width: 6),
                              Text(
                                '${AppConstants.currency} ${item['base_price']}',
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
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 10),
                  child: Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: context.cx.iconMuted),
                ),
              ],
            ),
            // Discount badge
            if (hasDiscount)
              PositionedDirectional(
                top: 5,
                start: 5,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
}
