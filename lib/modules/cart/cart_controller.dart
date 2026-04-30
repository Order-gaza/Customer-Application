import 'dart:async';
import 'package:get/get.dart';
import '../../app/constants/api_endpoints.dart';
import '../../data/providers/api_provider.dart';

class CartController extends GetxController {
  static CartController get to => Get.find();

  final RxBool isLoading = false.obs;
  final RxList<dynamic> vendors = <dynamic>[].obs;
  final RxDouble subtotal = 0.0.obs;
  final RxDouble deliveryFee = 0.0.obs;
  final RxDouble multiVendorSurcharge = 0.0.obs;
  final RxDouble serviceFee = 0.0.obs;
  final RxBool meetsMinimum = true.obs;
  final RxInt cartItemCount = 0.obs;

  /// Debounce timer to avoid back-to-back server syncs
  Timer? _syncDebounce;

  /// Track pending API calls to avoid flickering
  int _pendingUpdates = 0;

  double get total => subtotal.value + deliveryFee.value + multiVendorSurcharge.value + serviceFee.value;

  @override
  void onInit() {
    super.onInit();
    loadCart();
  }

  @override
  void onClose() {
    _syncDebounce?.cancel();
    super.onClose();
  }

  Future<void> loadCart() async {
    isLoading.value = true;
    final res = await ApiProvider.get(ApiEndpoints.cartGet);
    if (res.success && res.data != null) {
      vendors.value = res.data['vendors'] ?? [];
      subtotal.value = (res.data['subtotal'] ?? 0).toDouble();
      meetsMinimum.value = res.data['meets_minimum'] ?? true;
      cartItemCount.value = res.data['items_count'] ?? 0;
    }
    isLoading.value = false;
  }

  /// Silent refresh — updates cart data without showing the loading spinner.
  /// Skipped if there are pending updates to avoid overwriting optimistic values.
  Future<void> _silentLoadCart() async {
    // Don't sync if another update is in-flight — wait for it to finish
    if (_pendingUpdates > 0) return;

    final res = await ApiProvider.get(ApiEndpoints.cartGet);
    // Re-check after await — a new update may have started while we were loading
    if (_pendingUpdates > 0) return;

    if (res.success && res.data != null) {
      vendors.value = res.data['vendors'] ?? [];
      subtotal.value = (res.data['subtotal'] ?? 0).toDouble();
      meetsMinimum.value = res.data['meets_minimum'] ?? true;
      cartItemCount.value = res.data['items_count'] ?? 0;
    }
  }

  /// Schedule a debounced server sync (waits 600ms after last change)
  void _scheduleSyncAfterUpdate() {
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 600), () {
      _silentLoadCart();
    });
  }

  Future<void> addToCart(String menuItemId, {int quantity = 1, String? notes}) async {
    final res = await ApiProvider.post(ApiEndpoints.cartAdd, body: {
      'menu_item_id': menuItemId,
      'quantity': quantity.toString(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    if (res.success) {
      cartItemCount.value = res.data?['cart_items_count'] ?? (cartItemCount.value + 1);
      update();
      loadCart();
    } else if (!res.isNetworkError) {
      if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
      Get.snackbar('Error'.tr, res.message ?? 'Something went wrong'.tr);
    }
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    // Optimistically update local UI immediately
    _updateLocalQuantity(cartItemId, quantity);

    _pendingUpdates++;
    final res = await ApiProvider.post(ApiEndpoints.cartUpdate, body: {
      'cart_item_id': cartItemId,
      'quantity': quantity.toString(),
    });
    _pendingUpdates--;

    // Schedule a debounced sync instead of immediate reload
    if (res.success) {
      _scheduleSyncAfterUpdate();
    } else {
      // On failure, force sync to revert
      _silentLoadCart();
    }
  }

  Future<void> removeItem(String cartItemId) async {
    // Optimistically remove the item from local vendors list
    _removeLocalItem(cartItemId);

    _pendingUpdates++;
    final res = await ApiProvider.post(ApiEndpoints.cartRemove, body: {
      'cart_item_id': cartItemId,
    });
    _pendingUpdates--;

    // Schedule a debounced sync
    if (res.success) {
      _scheduleSyncAfterUpdate();
    } else {
      // On failure, force sync to revert
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
          vendors.refresh();
          _recalcSubtotal();
          return;
        }
      }
    }
  }

  /// Optimistically remove item from local state
  void _removeLocalItem(String cartItemId) {
    for (int vi = 0; vi < vendors.length; vi++) {
      final items = vendors[vi]['items'] as List<dynamic>? ?? [];
      items.removeWhere((item) => item['cart_item_id']?.toString() == cartItemId);
      if (items.isEmpty) {
        vendors.removeAt(vi);
      }
    }
    cartItemCount.value = (cartItemCount.value - 1).clamp(0, 9999);
    _recalcSubtotal();
    vendors.refresh();
  }

  /// Recalculate subtotal from local cart data
  void _recalcSubtotal() {
    double total = 0;
    for (var vendor in vendors) {
      final items = vendor['items'] as List<dynamic>? ?? [];
      for (var item in items) {
        final qty = int.tryParse(item['quantity'].toString()) ?? 1;
        final discountPrice = double.tryParse(item['discount_price']?.toString() ?? '') ?? 0;
        final basePrice = double.tryParse(item['base_price']?.toString() ?? '0') ?? 0;
        final effectivePrice = (discountPrice > 0 && discountPrice < basePrice) ? discountPrice : basePrice;
        total += effectivePrice * qty;
      }
    }
    subtotal.value = total;
  }

  Future<void> clearCart() async {
    final res = await ApiProvider.post(ApiEndpoints.cartClear);
    if (res.success) {
      vendors.clear();
      subtotal.value = 0;
      deliveryFee.value = 0;
      multiVendorSurcharge.value = 0;
      serviceFee.value = 0;
      cartItemCount.value = 0;
      update();
    }
  }

  // Zone info for display
  final RxString zoneFrom = ''.obs;
  final RxString zoneTo = ''.obs;

  Future<void> loadDeliveryFee(String addressId) async {
    final res = await ApiProvider.get(ApiEndpoints.cartDeliveryFee,
        queryParams: {'address_id': addressId});
    if (res.success && res.data != null) {
      deliveryFee.value = (res.data['delivery_fee'] ?? 0).toDouble();
      multiVendorSurcharge.value = (res.data['multi_vendor_surcharge'] ?? 0).toDouble();
      serviceFee.value = (res.data['service_fee'] ?? 0).toDouble();
      zoneFrom.value = res.data['zone_from']?.toString() ?? '';
      zoneTo.value = res.data['zone_to']?.toString() ?? '';
    }
  }
}
