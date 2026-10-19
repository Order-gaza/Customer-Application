import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/constants/api_endpoints.dart';
import '../../data/providers/api_provider.dart';
import '../../shared/localization/app_translations.dart';
import '../../shared/utils/app_navigator.dart';

class CartController extends ChangeNotifier {
  static CartController? _instance;
  static CartController get to => _instance ??= CartController();

  bool isLoading = false;
  List<dynamic> vendors = [];
  double subtotal = 0.0;
  double deliveryFee = 0.0;
  double multiVendorSurcharge = 0.0;
  double serviceFee = 0.0;
  bool meetsMinimum = true;
  int cartItemCount = 0;

  // ── Promo Code ──
  String promoCode = '';
  String promoCodeId = '';
  double promoDiscount = 0.0;
  double promoPercentage = 0.0;
  double promoMaxCap = 0.0;
  bool promoValidating = false;
  String promoError = '';

  // ── Points ──
  bool usePoints = false;
  int pointsBalance = 0;
  double pointsPerShekel = 10.0;
  double pointsDiscount = 0.0;
  int pointsToRedeem = 0;
  bool pointsActive = false;

  // Zone info for display
  String zoneFrom = '';
  String zoneTo = '';

  /// Debounce timer to avoid back-to-back server syncs
  Timer? _syncDebounce;

  /// Track pending API calls to avoid flickering
  int _pendingUpdates = 0;

  double get total {
    final base =
        subtotal + deliveryFee + multiVendorSurcharge + serviceFee;
    final afterDiscounts = base - promoDiscount - pointsDiscount;
    return afterDiscounts > 0 ? afterDiscounts : 0;
  }

  CartController() {
    _instance = this;
    loadCart();
  }

  @override
  void dispose() {
    _syncDebounce?.cancel();
    super.dispose();
  }

  Future<void> loadCart() async {
    isLoading = true;
    notifyListeners();

    final res = await ApiProvider.get(ApiEndpoints.cartGet);
    if (res.success && res.data != null) {
      vendors = res.data['vendors'] ?? [];
      subtotal = (res.data['subtotal'] ?? 0).toDouble();
      meetsMinimum = res.data['meets_minimum'] ?? true;
      cartItemCount = res.data['items_count'] ?? 0;
    }
    isLoading = false;
    notifyListeners();
  }

  /// Silent refresh — updates cart data without showing the loading spinner.
  Future<void> _silentLoadCart() async {
    if (_pendingUpdates > 0) return;

    final res = await ApiProvider.get(ApiEndpoints.cartGet);
    if (_pendingUpdates > 0) return;

    if (res.success && res.data != null) {
      vendors = res.data['vendors'] ?? [];
      subtotal = (res.data['subtotal'] ?? 0).toDouble();
      meetsMinimum = res.data['meets_minimum'] ?? true;
      cartItemCount = res.data['items_count'] ?? 0;
      notifyListeners();
    }
  }

  /// Schedule a debounced server sync (waits 600ms after last change)
  void _scheduleSyncAfterUpdate() {
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 600), () {
      _silentLoadCart();
    });
  }

  Future<void> addToCart(String menuItemId,
      {int quantity = 1, String? notes}) async {
    final res = await ApiProvider.post(ApiEndpoints.cartAdd, body: {
      'menu_item_id': menuItemId,
      'quantity': quantity.toString(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    if (res.success) {
      cartItemCount =
          res.data?['cart_items_count'] ?? (cartItemCount + 1);
      notifyListeners();
      loadCart();
    } else if (!res.isNetworkError) {
      AppNavigator.snackbar(
          'Error'.tr, res.message ?? 'Something went wrong'.tr);
    }
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    _updateLocalQuantity(cartItemId, quantity);

    _pendingUpdates++;
    final res = await ApiProvider.post(ApiEndpoints.cartUpdate, body: {
      'cart_item_id': cartItemId,
      'quantity': quantity.toString(),
    });
    _pendingUpdates--;

    if (res.success) {
      _scheduleSyncAfterUpdate();
    } else {
      _silentLoadCart();
    }
  }

  Future<void> removeItem(String cartItemId) async {
    _removeLocalItem(cartItemId);

    _pendingUpdates++;
    final res = await ApiProvider.post(ApiEndpoints.cartRemove, body: {
      'cart_item_id': cartItemId,
    });
    _pendingUpdates--;

    if (res.success) {
      _scheduleSyncAfterUpdate();
    } else {
      _silentLoadCart();
    }
  }

  /// Optimistically update item quantity in local state
  void _updateLocalQuantity(String cartItemId, int newQty) {
    for (var vendor in vendors) {
      final items = vendor['items'] as List<dynamic>? ?? [];
      for (var item in items) {
        if (item['cart_item_id']?.toString() == cartItemId) {
          item['quantity'] = newQty;
          _recalcSubtotal();
          notifyListeners();
          return;
        }
      }
    }
  }

  /// Optimistically remove item from local state
  void _removeLocalItem(String cartItemId) {
    for (int vi = 0; vi < vendors.length; vi++) {
      final items = vendors[vi]['items'] as List<dynamic>? ?? [];
      items.removeWhere(
          (item) => item['cart_item_id']?.toString() == cartItemId);
      if (items.isEmpty) {
        vendors.removeAt(vi);
      }
    }
    cartItemCount = (cartItemCount - 1).clamp(0, 9999);
    _recalcSubtotal();
    notifyListeners();
  }

  /// Recalculate subtotal from local cart data
  void _recalcSubtotal() {
    double total = 0;
    for (var vendor in vendors) {
      final items = vendor['items'] as List<dynamic>? ?? [];
      for (var item in items) {
        final qty = int.tryParse(item['quantity'].toString()) ?? 1;
        final discountPrice =
            double.tryParse(item['discount_price']?.toString() ?? '') ?? 0;
        final basePrice =
            double.tryParse(item['base_price']?.toString() ?? '0') ?? 0;
        final effectivePrice =
            (discountPrice > 0 && discountPrice < basePrice)
                ? discountPrice
                : basePrice;
        total += effectivePrice * qty;
      }
    }
    subtotal = total;
  }

  Future<void> clearCart() async {
    final res = await ApiProvider.post(ApiEndpoints.cartClear);
    if (res.success) {
      vendors.clear();
      subtotal = 0;
      deliveryFee = 0;
      multiVendorSurcharge = 0;
      serviceFee = 0;
      cartItemCount = 0;
      notifyListeners();
    }
  }

  Future<void> loadDeliveryFee(String addressId) async {
    final res = await ApiProvider.get(ApiEndpoints.cartDeliveryFee,
        queryParams: {'address_id': addressId});
    if (res.success && res.data != null) {
      deliveryFee = (res.data['delivery_fee'] ?? 0).toDouble();
      multiVendorSurcharge =
          (res.data['multi_vendor_surcharge'] ?? 0).toDouble();
      serviceFee = (res.data['service_fee'] ?? 0).toDouble();
      zoneFrom = res.data['zone_from']?.toString() ?? '';
      zoneTo = res.data['zone_to']?.toString() ?? '';
      notifyListeners();
    }
  }

  // ── Promo Code Methods ──

  Future<void> validatePromo(String code) async {
    if (code.trim().isEmpty) return;
    promoValidating = true;
    promoError = '';
    notifyListeners();

    final res = await ApiProvider.post(ApiEndpoints.validatePromo, body: {
      'code': code.trim().toUpperCase(),
      'subtotal': subtotal.toString(),
    });
    promoValidating = false;
    if (res.success && res.data != null) {
      promoCode = res.data['code']?.toString() ?? code;
      promoCodeId = res.data['promo_code_id']?.toString() ?? '';
      promoDiscount = (res.data['discount_amount'] ?? 0).toDouble();
      promoPercentage =
          (res.data['discount_percentage'] ?? 0).toDouble();
      promoMaxCap =
          (res.data['max_discount_amount'] ?? 0).toDouble();
      promoError = '';
      _recalcPointsDiscount();
    } else {
      promoError = res.message ?? 'Invalid promo code';
      clearPromo();
    }
    notifyListeners();
  }

  void clearPromo() {
    promoCode = '';
    promoCodeId = '';
    promoDiscount = 0;
    promoPercentage = 0;
    promoMaxCap = 0;
    _recalcPointsDiscount();
    notifyListeners();
  }

  // ── Points Methods ──

  Future<void> loadPointsBalance() async {
    final res = await ApiProvider.get(ApiEndpoints.getPoints);
    if (res.success && res.data != null) {
      pointsBalance = (res.data['points_balance'] ?? 0) as int;
      pointsPerShekel =
          (res.data['points_per_shekel'] ?? 10).toDouble();
      pointsActive =
          res.data['is_active'] == true || res.data['is_active'] == 1;
      notifyListeners();
    }
  }

  void togglePoints(bool value) {
    usePoints = value;
    _recalcPointsDiscount();
    notifyListeners();
  }

  void _recalcPointsDiscount() {
    if (!usePoints || pointsBalance <= 0 || pointsPerShekel <= 0) {
      pointsDiscount = 0;
      pointsToRedeem = 0;
      return;
    }
    final maxShekel =
        (pointsBalance / pointsPerShekel).floorToDouble();
    final remaining = subtotal - promoDiscount;
    final disc =
        maxShekel < remaining ? maxShekel : (remaining > 0 ? remaining : 0.0);
    pointsDiscount = disc;
    pointsToRedeem = (disc * pointsPerShekel).toInt();
  }
}

final cartProvider =
    ChangeNotifierProvider<CartController>((ref) => CartController.to);
