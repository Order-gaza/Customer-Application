import 'package:flutter/material.dart';
import 'package:order/app/theme/theme_colors.dart';
import 'package:get/get.dart';
import '../../../app/constants/api_endpoints.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/providers/api_provider.dart';
import '../../../shared/services/location_data.dart';

class AddressListView extends StatefulWidget {
  const AddressListView({super.key});
  @override
  State<AddressListView> createState() => _AddressListViewState();
}

class _AddressListViewState extends State<AddressListView> {
  List<dynamic> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await ApiProvider.get(ApiEndpoints.addressesGetAll);
    if (res.success) _addresses = res.data?['addresses'] ?? [];
    setState(() => _isLoading = false);
  }

  Future<void> _setDefault(String id) async {
    // Optimistic UI: update local state immediately
    setState(() {
      for (var a in _addresses) {
        a['is_default'] = a['id'].toString() == id ? 1 : 0;
      }
    });

    final res = await ApiProvider.post(
      ApiEndpoints.addressesSetDefault,
      body: {'address_id': id},
    );

    if (res.success) {
      Get.snackbar(
        'Success'.tr,
        'Default address updated'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      );
      // Reload to get fresh server state
      _load();
    } else if (!res.isNetworkError) {
      // Revert on failure
      _load();
      if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
      Get.snackbar(
        'Error'.tr,
        res.message ?? 'Something went wrong'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );
    }
  }

  Future<void> _confirmDelete(String id) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: context.cx.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete address?'.tr,
            style: TextStyle(color: context.cx.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete this address?'.tr,
          style: TextStyle(color: context.cx.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('Delete'.tr, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final res = await ApiProvider.post(
      ApiEndpoints.addressesDelete,
      body: {'address_id': id},
    );
    if (res.success) {
      _load();
      Get.snackbar(
        'Success'.tr,
        'Address deleted'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _editAddress(dynamic address) async {
    await Get.toNamed(AppRoutes.editAddress, arguments: {
      'id': address['id'].toString(),
      'address_id': address['id'].toString(),
      'city': address['city'] ?? '',
      'neighborhood': address['neighborhood'] ?? '',
      'label': address['label'] ?? '',
      'address_line': address['address_line'] ?? '',
      'phone': address['phone'] ?? '',
      'notes': address['notes'] ?? '',
      'is_default': address['is_default'],
    });
    _load();
  }

  void _showAddressDetails(dynamic a) {
    final isDefault = a['is_default'] == 1 || a['is_default'] == true;

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          top: 16,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        decoration: BoxDecoration(
          color: context.cx.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: context.cx.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Label + default badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: AppColors.primaryOrange, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a['label'] ?? '',
                        style: TextStyle(
                          color: context.cx.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isDefault)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Default'.tr,
                                style: const TextStyle(
                                    color: AppColors.primaryOrange,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Address line
            _detailRow(Icons.map_outlined, 'Address Line'.tr, a['address_line'] ?? '-'),

            // Phone
            if (a['phone'] != null && a['phone'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: _detailRow(Icons.phone_outlined, 'Phone'.tr, a['phone']),
              ),

            // Notes
            if (a['notes'] != null && a['notes'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: _detailRow(
                    Icons.note_alt_outlined, 'Additional Notes'.tr, a['notes']),
              ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                // Set as Default button (only if not already default)
                if (!isDefault)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Get.back();
                        _setDefault(a['id'].toString());
                      },
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: Text('Set as Default'.tr, style: const TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryOrange,
                        side: const BorderSide(color: AppColors.primaryOrange),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                if (!isDefault) const SizedBox(width: 10),

                // Edit button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      _editAddress(a);
                    },
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: Text('Edit'.tr, style: const TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Delete button
                SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () {
                      Get.back();
                      _confirmDelete(a['id'].toString());
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: context.cx.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: context.cx.iconMuted),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(color: context.cx.textSecondary, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      color: context.cx.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cx.scaffold,
      appBar: AppBar(title: Text('My Addresses'.tr)),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Get.toNamed(AppRoutes.addAddress);
          _load();
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryOrange))
          : _addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_off_rounded,
                          size: 64, color: context.cx.textHint),
                      const SizedBox(height: 14),
                      Text('No addresses saved'.tr,
                          style: TextStyle(
                              color: context.cx.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text('Add your first delivery address'.tr,
                          style: TextStyle(
                              color: context.cx.textSecondary, fontSize: 13)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primaryOrange,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _addresses.length,
                    itemBuilder: (ctx, i) => _buildAddressCard(_addresses[i]),
                  ),
                ),
    );
  }

  Widget _buildAddressCard(dynamic a) {
    final isDefault = a['is_default'] == 1 || a['is_default'] == true;

    return GestureDetector(
      onTap: () => _showAddressDetails(a),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cx.card,
          borderRadius: BorderRadius.circular(14),
          border: isDefault
              ? Border.all(
                  color: AppColors.primaryOrange.withValues(alpha: 0.5),
                  width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            // Location icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDefault
                    ? AppColors.primaryOrange.withValues(alpha: 0.15)
                    : context.cx.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: isDefault ? AppColors.primaryOrange : context.cx.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Address info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          a['label'] ?? '',
                          style: TextStyle(
                            color: context.cx.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Default'.tr,
                              style: const TextStyle(
                                  color: AppColors.primaryOrange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    a['city'] != null && a['city'].toString().isNotEmpty
                        ? '${a['neighborhood'] ?? ''}, ${a['city']}'
                        : (a['address_line'] ?? ''),
                    style: TextStyle(color: context.cx.textSecondary, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (a['city'] != null && a['city'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _zoneColor(LocationData.getZoneForCity(a['city']))
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          LocationData.getZoneNameAr(a['city']),
                          style: TextStyle(
                            color: _zoneColor(LocationData.getZoneForCity(a['city'])),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  if (a['phone'] != null && a['phone'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.phone_outlined,
                              size: 13, color: context.cx.iconMuted),
                          const SizedBox(width: 4),
                          Text(a['phone'],
                              style: TextStyle(
                                  color: context.cx.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Chevron to indicate tap-to-view
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: context.cx.iconMuted),
          ],
        ),
      ),
    );
  }

  Color _zoneColor(String zone) {
    switch (zone) {
      case 'north':
        return const Color(0xFF2196F3);
      case 'central':
        return const Color(0xFF4CAF50);
      case 'south':
        return const Color(0xFFFF9800);
      default:
        return AppColors.primaryOrange;
    }
  }
}
