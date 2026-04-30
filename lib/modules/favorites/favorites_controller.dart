import 'package:get/get.dart';
import '../../app/constants/api_endpoints.dart';
import '../../data/providers/api_provider.dart';

/// Global favorites controller — manages favorite state across the entire app.
/// Registered in MainShell so it persists across all tabs.
class FavoritesController extends GetxController {
  static FavoritesController get to => Get.find();

  final RxBool isLoading = false.obs;
  final RxList<dynamic> favoriteVendors = <dynamic>[].obs;
  final RxList<dynamic> favoriteItems = <dynamic>[].obs;

  // In-memory sets for instant UI lookups (no API call needed)
  final RxSet<String> _favVendorIds = <String>{}.obs;
  final RxSet<String> _favItemIds = <String>{}.obs;

  /// Check if a vendor is favorited
  bool isVendorFavorite(String vendorId) => _favVendorIds.contains(vendorId);

  /// Check if an item is favorited
  bool isItemFavorite(String itemId) => _favItemIds.contains(itemId);

  int get totalCount => favoriteVendors.length + favoriteItems.length;

  @override
  void onInit() {
    super.onInit();
    loadFavorites();
  }

  /// Load all favorites from server
  Future<void> loadFavorites() async {
    isLoading.value = true;
    final res = await ApiProvider.get(ApiEndpoints.favoritesGetAll);
    if (res.success && res.data != null) {
      favoriteVendors.value = res.data['vendors'] ?? [];
      favoriteItems.value = res.data['items'] ?? [];

      // Rebuild ID sets
      _favVendorIds.clear();
      for (final v in favoriteVendors) {
        _favVendorIds.add(v['id'].toString());
      }
      _favItemIds.clear();
      for (final i in favoriteItems) {
        _favItemIds.add(i['id'].toString());
      }
    }
    isLoading.value = false;
  }

  /// Toggle favorite — instant UI update + API call
  Future<void> toggleFavorite(String type, String targetId) async {
    // Optimistic UI update
    if (type == 'vendor') {
      if (_favVendorIds.contains(targetId)) {
        _favVendorIds.remove(targetId);
        favoriteVendors.removeWhere((v) => v['id'].toString() == targetId);
      } else {
        _favVendorIds.add(targetId);
      }
    } else {
      if (_favItemIds.contains(targetId)) {
        _favItemIds.remove(targetId);
        favoriteItems.removeWhere((i) => i['id'].toString() == targetId);
      } else {
        _favItemIds.add(targetId);
      }
    }
    update(); // Notify GetBuilder listeners

    // API call
    final res = await ApiProvider.post(ApiEndpoints.favoritesToggle, body: {
      'type': type,
      'target_id': targetId,
    });

    if (!res.success) {
      // Revert on failure
      if (type == 'vendor') {
        if (_favVendorIds.contains(targetId)) {
          _favVendorIds.remove(targetId);
        } else {
          _favVendorIds.add(targetId);
        }
      } else {
        if (_favItemIds.contains(targetId)) {
          _favItemIds.remove(targetId);
        } else {
          _favItemIds.add(targetId);
        }
      }
      update();
    } else {
      // Reload full data to get complete objects for newly added favorites
      loadFavorites();
    }
  }
}
