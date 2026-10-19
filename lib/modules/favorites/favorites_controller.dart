import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/constants/api_endpoints.dart';
import '../../data/providers/api_provider.dart';

/// Global favorites controller — manages favorite state across the entire app.
class FavoritesController extends ChangeNotifier {
  static FavoritesController? _instance;
  static FavoritesController get to => _instance ??= FavoritesController();

  bool isLoading = false;
  List<dynamic> favoriteVendors = [];
  List<dynamic> favoriteItems = [];

  // In-memory sets for instant UI lookups (no API call needed)
  final Set<String> _favVendorIds = <String>{};
  final Set<String> _favItemIds = <String>{};

  /// Check if a vendor is favorited
  bool isVendorFavorite(String vendorId) => _favVendorIds.contains(vendorId);

  /// Check if an item is favorited
  bool isItemFavorite(String itemId) => _favItemIds.contains(itemId);

  int get totalCount => favoriteVendors.length + favoriteItems.length;

  FavoritesController() {
    _instance = this;
    loadFavorites();
  }

  /// Load all favorites from server
  Future<void> loadFavorites() async {
    isLoading = true;
    notifyListeners();

    final res = await ApiProvider.get(ApiEndpoints.favoritesGetAll);
    if (res.success && res.data != null) {
      favoriteVendors = res.data['vendors'] ?? [];
      favoriteItems = res.data['items'] ?? [];

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
    isLoading = false;
    notifyListeners();
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
    notifyListeners();

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
      notifyListeners();
    } else {
      // Reload full data to get complete objects for newly added favorites
      loadFavorites();
    }
  }
}

final favoritesProvider = ChangeNotifierProvider<FavoritesController>(
    (ref) => FavoritesController.to);
