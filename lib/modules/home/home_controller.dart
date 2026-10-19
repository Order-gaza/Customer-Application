import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/secure_storage_service.dart';
import '../../app/constants/api_endpoints.dart';
import '../../data/providers/api_provider.dart';

class HomeController extends ChangeNotifier {
  static HomeController? _instance;
  static HomeController get to => _instance ??= HomeController();

  // Per-section loading flags — sections render as soon as their data arrives
  bool isAdsLoading = true;
  bool isFeaturedLoading = true;
  bool isPopularLoading = true;
  bool isCategoriesLoading = true;

  List<dynamic> advertisements = [];
  List<dynamic> featuredVendors = [];
  List<dynamic> popularItems = [];
  List<dynamic> topCategories = [];
  String userName = '';

  HomeController() {
    _instance = this;
    loadHome();
  }

  Future<void> loadHome() async {
    // Show name from cache instantly
    userName = ApiProvider.storedUserName ?? '';
    notifyListeners();

    // Fire all in parallel — each section resolves independently
    await Future.wait([
      _loadAds(),
      _loadFeatured(),
      _loadPopular(),
      _loadTopCategories(),
      _loadUserName(),
    ]);
  }

  Future<void> _loadUserName() async {
    final res = await ApiProvider.get(ApiEndpoints.profileGet);
    if (res.success && res.data != null) {
      final name = res.data['user']?['name'] ?? res.data['name'] ?? '';
      if (name.toString().isNotEmpty) {
        userName = name.toString();
        // Update local storage so it's fresh everywhere
        SecureStorageService.instance.write('user_name', name.toString());
        notifyListeners();
      }
    }
  }

  Future<void> _loadAds() async {
    try {
      final res = await ApiProvider.get(ApiEndpoints.homeAdvertisements);
      if (res.success && res.data != null) {
        advertisements = res.data['advertisements'] ?? [];
      }
    } finally {
      isAdsLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFeatured() async {
    try {
      final res = await ApiProvider.get(ApiEndpoints.homeFeaturedVendors,
          queryParams: {'limit': '6'});
      if (res.success && res.data != null) {
        featuredVendors = res.data['vendors'] ?? [];
      }
    } finally {
      isFeaturedLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadPopular() async {
    try {
      final res = await ApiProvider.get(ApiEndpoints.homePopularItems,
          queryParams: {'limit': '8'});
      if (res.success && res.data != null) {
        popularItems = res.data['items'] ?? [];
      }
    } finally {
      isPopularLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadTopCategories() async {
    try {
      final res = await ApiProvider.get(ApiEndpoints.homeTopCategories,
          queryParams: {'limit': '8'});
      if (res.success && res.data != null) {
        topCategories = res.data['categories'] ?? [];
      }
    } finally {
      isCategoriesLoading = false;
      notifyListeners();
    }
  }

  /// Fire-and-forget: record ad click for analytics
  void recordAdClick(String adId) {
    ApiProvider.post(
      ApiEndpoints.homeRecordAdClick,
      body: {'ad_id': adId},
    );
  }
}

final homeProvider =
    ChangeNotifierProvider<HomeController>((ref) => HomeController.to);
