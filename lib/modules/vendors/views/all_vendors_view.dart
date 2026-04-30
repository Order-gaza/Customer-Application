import 'package:flutter/material.dart';
import 'package:order/app/theme/theme_colors.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../app/constants/api_endpoints.dart';
import '../../../app/constants/app_constants.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/providers/api_provider.dart';

class AllVendorsView extends StatefulWidget {
  const AllVendorsView({super.key});

  @override
  State<AllVendorsView> createState() => _AllVendorsViewState();
}

class _AllVendorsViewState extends State<AllVendorsView> {
  final List<dynamic> _vendors = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasNext = false;
  final ScrollController _scrollC = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadVendors();
    _scrollC.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollC.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollC.position.pixels >= _scrollC.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasNext) {
      _loadMore();
    }
  }

  Future<void> _loadVendors() async {
    setState(() => _isLoading = true);
    _currentPage = 1;
    final res = await ApiProvider.get(ApiEndpoints.vendorsGetAll,
        queryParams: {'page': '1', 'limit': '20'});
    setState(() {
      if (res.success && res.data != null) {
        _vendors.clear();
        _vendors.addAll(res.data['vendors'] ?? []);
        _hasNext = res.data['pagination']?['has_next'] ?? false;
      }
      _isLoading = false;
    });
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    _currentPage++;
    final res = await ApiProvider.get(ApiEndpoints.vendorsGetAll,
        queryParams: {'page': '$_currentPage', 'limit': '20'});
    setState(() {
      if (res.success && res.data != null) {
        _vendors.addAll(res.data['vendors'] ?? []);
        _hasNext = res.data['pagination']?['has_next'] ?? false;
      }
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cx.scaffold,
      appBar: AppBar(
        backgroundColor: context.cx.appBar,
        title: Text('All Vendors'.tr,
            style: TextStyle(
                color: context.cx.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: true,
        iconTheme: IconThemeData(color: context.cx.iconDefault),
        elevation: 0,
      ),
      body: _isLoading
          ? _buildShimmer()
          : _vendors.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.store_mall_directory_outlined,
                          size: 64,
                          color: context.cx.textHint),
                      const SizedBox(height: 16),
                      Text('No vendors available'.tr,
                          style: TextStyle(
                              color: context.cx.textSecondary, fontSize: 15)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primaryOrange,
                  onRefresh: _loadVendors,
                  child: ListView.builder(
                    controller: _scrollC,
                    padding: const EdgeInsets.all(16),
                    itemCount: _vendors.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == _vendors.length) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primaryOrange,
                                  strokeWidth: 2)),
                        );
                      }
                      return _buildVendorTile(_vendors[i]);
                    },
                  ),
                ),
    );
  }

  Widget _buildVendorTile(dynamic v) {
    final isOpen = v['is_currently_open'] == true || v['is_currently_open'] == 1 ||
        v['is_currently_open'] == '1';
    final openingTime = v['opening_time']?.toString();
    final closingTime = v['closing_time']?.toString();
    return GestureDetector(
      onTap: () =>
          Get.toNamed(AppRoutes.vendorDetail, arguments: {'vendor_id': v['id']}),
      child: Opacity(
        opacity: isOpen ? 1.0 : 0.6,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: context.cx.card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Vendor logo
              ClipRRect(
                borderRadius: const BorderRadiusDirectional.horizontal(
                    start: Radius.circular(16)),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: v['logo_url'] ?? '',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          width: 100, height: 100, color: context.cx.surface),
                      errorWidget: (_, __, ___) => Container(
                        width: 100,
                        height: 100,
                        color: context.cx.surface,
                        child: Icon(Icons.store,
                            color: context.cx.textSecondary, size: 36),
                      ),
                    ),
                    if (!isOpen)
                      Container(
                        width: 100,
                        height: 100,
                        color: Colors.black.withValues(alpha: 0.4),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Closed'.tr,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Vendor info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v['name'] ?? '',
                        style: TextStyle(
                          color: context.cx.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppColors.goldenYellow, size: 15),
                          const SizedBox(width: 3),
                          Text(
                            (v['rating'] ?? '0').toString(),
                            style: TextStyle(
                                color: context.cx.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primaryOrange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              AppConstants.vendorTypeLabel(
                                  v['type'] ?? 'restaurant'),
                              style: const TextStyle(
                                color: AppColors.primaryOrange,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOpen ? AppColors.success : AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isOpen ? 'Open'.tr : 'Closed'.tr,
                            style: TextStyle(
                                fontSize: 12, color: context.cx.textSecondary),
                          ),
                          if (v['estimated_delivery_time'] != null && isOpen) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.access_time_rounded,
                                size: 13,
                                color: context.cx.iconMuted),
                            const SizedBox(width: 3),
                            Text(
                              '${v['estimated_delivery_time']} ${'min'.tr}',
                              style: TextStyle(
                                  fontSize: 11, color: context.cx.textSecondary),
                            ),
                          ],
                          if (!isOpen && openingTime != null && openingTime.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.schedule_rounded,
                                size: 13, color: context.cx.iconMuted),
                            const SizedBox(width: 3),
                            Text(
                              '${'Opens'.tr} ${openingTime.substring(0, 5)}',
                              style: TextStyle(
                                  fontSize: 11, color: context.cx.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Arrow
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: context.cx.iconMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: context.cx.shimmerBase,
      highlightColor: context.cx.shimmerHighlight,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (_, __) => Container(
          height: 100,
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
