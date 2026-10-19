import 'package:flutter/material.dart';
import 'package:order/app/theme/theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/localization/app_translations.dart';
import '../../../shared/utils/app_navigator.dart';
import '../../favorites/favorites_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/constants/api_endpoints.dart';
import '../../../app/constants/app_constants.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/providers/api_provider.dart';
import '../../../shared/controllers/language_controller.dart';
import '../../cart/cart_controller.dart';

class ItemDetailView extends StatefulWidget {
  const ItemDetailView({super.key});

  @override
  State<ItemDetailView> createState() => _ItemDetailViewState();
}

class _ItemDetailViewState extends State<ItemDetailView> {
  bool _isLoading = true;
  Map<String, dynamic>? _item;
  int _quantity = 1;

  String _displayName(Map<String, dynamic> data) {
    if (LanguageController.to.isArabic) {
      final ar = data['name_ar']?.toString();
      if (ar != null && ar.isNotEmpty) return ar;
    }
    return data['name']?.toString() ?? '';
  }

  String _displayDesc(Map<String, dynamic> data) {
    if (LanguageController.to.isArabic) {
      final ar = data['description_ar']?.toString();
      if (ar != null && ar.isNotEmpty) return ar;
    }
    return data['description']?.toString() ?? '';
  }

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem() async {
    final itemId = AppNavigator.arguments?['item_id'];
    if (itemId == null) return;

    final res = await ApiProvider.get(ApiEndpoints.itemsGetById,
        queryParams: {'id': itemId.toString()});
    setState(() {
      if (res.success && res.data != null) {
        _item = res.data['item'];
      }
      _isLoading = false;
    });
  }

  void _addToCart() {
    if (_item == null) return;
    final vendorOpen = _item!['is_currently_open'] == 1 ||
        _item!['is_currently_open'] == true ||
        _item!['is_currently_open'] == '1';
    if (!vendorOpen) {
      if (AppNavigator.isSnackbarOpen) AppNavigator.closeCurrentSnackbar();
      AppNavigator.snackbar(
        'Vendor Closed'.tr,
        'This vendor is currently closed. You cannot add items now.'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.store_rounded, color: Colors.white),
      );
      return;
    }
    CartController.to.addToCart(_item!['id'].toString(), quantity: _quantity);
    if (AppNavigator.isSnackbarOpen) AppNavigator.closeCurrentSnackbar();
    AppNavigator.snackbar(
      'Added to Cart'.tr,
      '',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success.withValues(alpha: 0.9),
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.cx.scaffold,
        appBar: AppBar(
            backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(
            child:
                CircularProgressIndicator(color: AppColors.primaryOrange)),
      );
    }

    if (_item == null) {
      return Scaffold(
        backgroundColor: context.cx.scaffold,
        appBar: AppBar(
            backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 60, color: context.cx.textHint),
              const SizedBox(height: 12),
              Text('Item not found'.tr,
                  style: TextStyle(color: context.cx.textSecondary)),
            ],
          ),
        ),
      );
    }

    final available =
        _item!['is_available'] == 1 || _item!['is_available'] == true;
    final hasDiscount = _item!['discount_price'] != null &&
        _item!['discount_price'].toString().isNotEmpty &&
        double.tryParse(_item!['discount_price'].toString()) != null &&
        double.parse(_item!['discount_price'].toString()) > 0;
    final displayPrice = hasDiscount
        ? _item!['discount_price'].toString()
        : _item!['base_price'].toString();

    return Scaffold(
      backgroundColor: context.cx.scaffold,
      body: CustomScrollView(
        slivers: [
          // ── Hero image ──
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: context.cx.appBar,
            iconTheme: IconThemeData(color: context.cx.iconDefault),
            actions: [
              Consumer(builder: (context, ref, _) {
                final fav = ref.watch(favoritesProvider);
                final itemId = _item!['id'].toString();
                final isFav = fav.isItemFavorite(itemId);
                return IconButton(
                  onPressed: () => fav.toggleFavorite('item', itemId),
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
                  CachedNetworkImage(
                    imageUrl: _item!['image_url'] ?? '',
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: context.cx.surface),
                    errorWidget: (_, __, ___) => Container(
                      color: context.cx.surface,
                      child: Icon(Icons.fastfood,
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
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item name
                  Text(
                    _displayName(_item!),
                    style: TextStyle(
                      color: context.cx.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Category badge
                  if (_item!['category_name'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            AppColors.primaryOrange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _item!['category_name'],
                        style: const TextStyle(
                          color: AppColors.primaryOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Price
                  Row(
                    children: [
                      Text(
                        '${AppConstants.currency} $displayPrice',
                        style: const TextStyle(
                          color: AppColors.primaryOrange,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 10),
                        Text(
                          '${AppConstants.currency} ${_item!['base_price']}',
                          style: TextStyle(
                            color: context.cx.textSecondary,
                            fontSize: 16,
                            decoration: TextDecoration.lineThrough,
                            decorationColor:
                                context.cx.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  if (_displayDesc(_item!).isNotEmpty) ...[
                    Text(
                      'Description'.tr,
                      style: TextStyle(
                        color: context.cx.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _displayDesc(_item!),
                      style: TextStyle(
                        color: context.cx.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Preparation time
                  if (_item!['preparation_time'] != null) ...[
                    Container(
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
                              color: AppColors.primaryOrange
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.access_time_rounded,
                                color: AppColors.primaryOrange, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Preparation Time'.tr,
                                  style: TextStyle(
                                      color: context.cx.textSecondary,
                                      fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(
                                '${_item!['preparation_time']} ${'min'.tr}',
                                style: TextStyle(
                                    color: context.cx.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Vendor info
                  GestureDetector(
                    onTap: () => AppNavigator.toNamed(AppRoutes.vendorDetail,
                        arguments: {
                          'vendor_id': _item!['vendor_id']
                        }),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.cx.card,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: _item!['vendor_logo'] ?? '',
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                width: 44,
                                height: 44,
                                color: context.cx.surface,
                                child: Icon(Icons.store,
                                    color: context.cx.textSecondary, size: 22),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _item!['vendor_name'] ?? '',
                                  style: TextStyle(
                                      color: context.cx.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: (_item!['is_currently_open'] == 1 ||
                                                _item!['is_currently_open'] == true ||
                                                _item!['is_currently_open'] == '1')
                                            ? AppColors.success
                                            : AppColors.error,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      (_item!['is_currently_open'] == 1 ||
                                              _item!['is_currently_open'] == true ||
                                              _item!['is_currently_open'] == '1')
                                          ? 'Open'.tr
                                          : 'Closed'.tr,
                                      style: TextStyle(
                                          color: context.cx.textSecondary,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: context.cx.iconMuted),
                        ],
                      ),
                    ),
                  ),
                  // Bottom spacing for the fixed button
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      // ── Bottom add-to-cart bar ──
      bottomNavigationBar: !available
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: context.cx.appBar,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'Currently Unavailable'.tr,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            )
          : !(_item!['is_currently_open'] == 1 ||
                  _item!['is_currently_open'] == true ||
                  _item!['is_currently_open'] == '1')
              ? Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  decoration: BoxDecoration(
                    color: context.cx.appBar,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.store_rounded,
                              color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Vendor is Currently Closed'.tr,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  decoration: BoxDecoration(
                    color: context.cx.appBar,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Quantity controls
                      Container(
                        decoration: BoxDecoration(
                          color: context.cx.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (_quantity > 1) {
                                  setState(() => _quantity--);
                                }
                              },
                              icon: Icon(Icons.remove_rounded,
                                  color: context.cx.iconDefault, size: 20),
                              constraints: const BoxConstraints(
                                  minWidth: 40, minHeight: 40),
                            ),
                            SizedBox(
                              width: 32,
                              child: Text(
                                '$_quantity',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: context.cx.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _quantity++),
                              icon: const Icon(Icons.add_rounded,
                                  color: AppColors.primaryOrange, size: 20),
                              constraints: const BoxConstraints(
                                  minWidth: 40, minHeight: 40),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Add to cart button
                      Expanded(
                        child: GestureDetector(
                          onTap: _addToCart,
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primaryOrange,
                                  AppColors.darkOrange,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryOrange
                                      .withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.shopping_cart_rounded,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Add to Cart'.tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${AppConstants.currency} ${(double.parse(displayPrice) * _quantity).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
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
