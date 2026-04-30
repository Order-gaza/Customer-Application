import 'package:get/get.dart';
import '../../shared/services/secure_storage_service.dart';
import '../../app/constants/api_endpoints.dart';
import '../../data/providers/api_provider.dart';

class HomeController extends GetxController {
  static HomeController get to => Get.find();

  // Per-section loading flags — sections render as soon as their data arrives
  final RxBool isAdsLoading = true.obs;
  final RxBool isFeaturedLoading = true.obs;
  final RxBool isPopularLoading = true.obs;
  final RxBool isCategoriesLoading = true.obs;

  final RxList<dynamic> advertisements = <dynamic>[].obs;
  final RxList<dynamic> featuredVendors = <dynamic>[].obs;
  final RxList<dynamic> popularItems = <dynamic>[].obs;
  final RxList<dynamic> topCategories = <dynamic>[].obs;
  final RxString userName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadHome();
  }

  Future<void> loadHome() async {
    // Show name from cache instantly
    userName.value = ApiProvider.storedUserName ?? '';

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
        userName.value = name.toString();
        // Update local storage so it's fresh everywhere
        SecureStorageService.instance.write('user_name', name.toString());
      }
    }
  }

  Future<void> _loadAds() async {
    try {
      final res = await ApiProvider.get(ApiEndpoints.homeAdvertisements);
      if (res.success && res.data != null) {
        advertisements.value = res.data['advertisements'] ?? [];
      }
    } finally {
      isAdsLoading.value = false;
    }
  }

  Future<void> _loadFeatured() async {
    try {
      final res = await ApiProvider.get(ApiEndpoints.homeFeaturedVendors,
          queryParams: {'limit': '6'});
      if (res.success && res.data != null) {
        featuredVendors.value = res.data['vendors'] ?? [];
      }
    } finally {
      isFeaturedLoading.value = false;
    }
  }

  Future<void> _loadPopular() async {
    try {
      final res = await ApiProvider.get(ApiEndpoints.homePopularItems,
          queryParams: {'limit': '8'});
      if (res.success && res.data != null) {
        popularItems.value = res.data['items'] ?? [];
      }
    } finally {
      isPopularLoading.value = false;
    }
  }

  Future<void> _loadTopCategories() async {
    try {
      final res = await ApiProvider.get(ApiEndpoints.homeTopCategories,
          queryParams: {'limit': '8'});
      if (res.success && res.data != null) {
        topCategories.value = res.data['categories'] ?? [];
      }
    } finally {
      isCategoriesLoading.value = false;
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
