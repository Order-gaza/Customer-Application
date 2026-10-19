import 'package:flutter/material.dart';
import '../../shared/localization/app_translations.dart';
import '../utils/app_navigator.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/theme_colors.dart';
import '../services/location_data.dart';

/// A bottom sheet dialog for selecting city and neighborhood.
class CityPickerDialog extends StatefulWidget {
  final String? initialCity;
  final String? initialNeighborhood;

  const CityPickerDialog({
    super.key,
    this.initialCity,
    this.initialNeighborhood,
  });

  /// Show the picker and return {city, neighborhood} or null if cancelled
  static Future<Map<String, String>?> show({
    String? initialCity,
    String? initialNeighborhood,
    bool mandatory = false,
  }) async {
    return await AppNavigator.bottomSheet<Map<String, String>>(
      CityPickerDialog(
        initialCity: initialCity,
        initialNeighborhood: initialNeighborhood,
      ),
      isScrollControlled: true,
      isDismissible: !mandatory,
      enableDrag: !mandatory,
    );
  }

  @override
  State<CityPickerDialog> createState() => _CityPickerDialogState();
}

class _CityPickerDialogState extends State<CityPickerDialog>
    with SingleTickerProviderStateMixin {
  String? _selectedCity;
  String? _selectedNeighborhood;
  List<String> _neighborhoods = [];
  late AnimationController _animController;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    if (widget.initialCity != null && widget.initialCity!.isNotEmpty) {
      _selectedCity = widget.initialCity;
      _neighborhoods = LocationData.getNeighborhoods(_selectedCity!);
      _animController.forward();
      if (widget.initialNeighborhood != null &&
          widget.initialNeighborhood!.isNotEmpty) {
        _selectedNeighborhood = widget.initialNeighborhood;
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onCitySelected(String city) {
    setState(() {
      _selectedCity = city;
      _selectedNeighborhood = null;
      _neighborhoods = LocationData.getNeighborhoods(city);
    });
    _animController.forward(from: 0);
  }

  void _confirm() {
    if (_selectedCity != null && _selectedNeighborhood != null) {
      AppNavigator.back(result: {
        'city': _selectedCity!,
        'neighborhood': _selectedNeighborhood!,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: context.cx.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: context.cx.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryOrange, AppColors.darkOrange],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.location_city_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اختر موقعك'.tr,
                          style: TextStyle(
                            color: context.cx.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'اختر المدينة والحي لتحديد سعر التوصيل'.tr,
                          style: TextStyle(
                            color: context.cx.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: context.cx.divider, height: 1),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step 1: City selection
                    _stepHeader('1', 'المدينة'.tr, Icons.location_city_outlined),
                    const SizedBox(height: 10),
                    ...LocationData.zones.expand((zone) {
                      return [
                        // Zone header
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 6),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _zoneColor(zone.zone)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  zone.zoneNameAr,
                                  style: TextStyle(
                                    color: _zoneColor(zone.zone),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Cities in zone
                        ...zone.cities.map((city) => _cityTile(city.name)),
                      ];
                    }),

                    // Step 2: Neighborhood selection (animated)
                    SizeTransition(
                      sizeFactor: _slideAnim,
                      axisAlignment: -1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _stepHeader(
                              '2', 'الحي / المنطقة'.tr, Icons.map_outlined),
                          const SizedBox(height: 10),
                          if (_neighborhoods.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _neighborhoods
                                  .map((n) => _neighborhoodChip(n))
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Confirm button
            Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: bottomPad + 16,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_selectedCity != null &&
                          _selectedNeighborhood != null)
                      ? _confirm
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    disabledBackgroundColor:
                        AppColors.primaryOrange.withValues(alpha: 0.3),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white60,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'تأكيد الموقع'.tr,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepHeader(String step, String label, IconData icon) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: AppColors.primaryOrange,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(step,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: context.cx.textSecondary, size: 18),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: context.cx.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _cityTile(String city) {
    final selected = _selectedCity == city;
    return GestureDetector(
      onTap: () => _onCitySelected(city),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryOrange.withValues(alpha: 0.12)
              : context.cx.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primaryOrange
                : context.cx.divider.withValues(alpha: 0.5),
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? AppColors.primaryOrange
                  : context.cx.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.location_on_outlined,
              color: selected
                  ? AppColors.primaryOrange
                  : context.cx.iconMuted,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                city,
                style: TextStyle(
                  color: selected
                      ? AppColors.primaryOrange
                      : context.cx.textPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _neighborhoodChip(String neighborhood) {
    final selected = _selectedNeighborhood == neighborhood;
    return GestureDetector(
      onTap: () => setState(() => _selectedNeighborhood = neighborhood),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryOrange
              : context.cx.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primaryOrange
                : context.cx.divider,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Text(
          neighborhood,
          style: TextStyle(
            color: selected ? Colors.white : context.cx.textPrimary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
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
