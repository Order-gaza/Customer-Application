import 'package:flutter/material.dart';
import '../../../shared/localization/app_translations.dart';
import '../../../shared/utils/app_navigator.dart';
import '../../../app/constants/api_endpoints.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/theme_colors.dart';
import '../../../data/providers/api_provider.dart';
import '../../../shared/services/location_data.dart';
import '../../../shared/widgets/city_picker_dialog.dart';

class AddAddressView extends StatefulWidget {
  const AddAddressView({super.key});

  @override
  State<AddAddressView> createState() => _AddAddressViewState();
}

class _AddAddressViewState extends State<AddAddressView> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _addressDetailCtrl = TextEditingController();

  String? _selectedCity;
  String? _selectedNeighborhood;
  bool _isDefault = false;
  bool _isSaving = false;

  // For edit mode
  bool get _isEdit => _editId != null;
  String? _editId;
  Map<String, dynamic>? _editData;

  @override
  void initState() {
    super.initState();
    // Check if editing
    if (AppNavigator.arguments is Map<String, dynamic>) {
      _editData = AppNavigator.arguments as Map<String, dynamic>;
      _editId = _editData!['id'];
      _selectedCity = _editData!['city'];
      _selectedNeighborhood = _editData!['neighborhood'];
      _phoneCtrl.text = _editData!['phone'] ?? '';
      _notesCtrl.text = _editData!['notes'] ?? '';
      _addressDetailCtrl.text = _editData!['address_line'] ?? '';
      _isDefault = _editData!['is_default'] == 1 ||
          _editData!['is_default'] == true;
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    _addressDetailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCity() async {
    final result = await CityPickerDialog.show(
      initialCity: _selectedCity,
      initialNeighborhood: _selectedNeighborhood,
    );
    if (result != null) {
      setState(() {
        _selectedCity = result['city'];
        _selectedNeighborhood = result['neighborhood'];
      });
    }
  }

  Future<void> _save() async {
    if (_selectedCity == null || _selectedNeighborhood == null) {
      AppNavigator.snackbar('خطأ'.tr, 'يرجى اختيار المدينة والحي'.tr,
          backgroundColor: Colors.red.withValues(alpha: 0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (_phoneCtrl.text.trim().isEmpty) {
      AppNavigator.snackbar('خطأ'.tr, 'رقم الهاتف مطلوب'.tr,
          backgroundColor: Colors.red.withValues(alpha: 0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _isSaving = true);

    final body = {
      'city': _selectedCity!,
      'neighborhood': _selectedNeighborhood!,
      'phone': _phoneCtrl.text.trim(),
      'notes': _notesCtrl.text.trim(),
      'address_line': _addressDetailCtrl.text.trim().isNotEmpty
          ? _addressDetailCtrl.text.trim()
          : '$_selectedNeighborhood، $_selectedCity',
      'label': '$_selectedCity - $_selectedNeighborhood',
      'is_default': _isDefault ? '1' : '0',
    };

    final res = _isEdit
        ? await ApiProvider.post(ApiEndpoints.addressesUpdate,
            body: {...body, 'address_id': _editId!})
        : await ApiProvider.post(ApiEndpoints.addressesAdd, body: body);

    setState(() => _isSaving = false);

    if (res.success) {
      AppNavigator.back(result: true);
      AppNavigator.snackbar(
        'نجاح'.tr,
        _isEdit ? 'تم تحديث العنوان'.tr : 'تم إضافة العنوان'.tr,
        backgroundColor: Colors.green.withValues(alpha: 0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      AppNavigator.snackbar('خطأ'.tr, res.message ?? 'فشلت العملية'.tr,
          backgroundColor: Colors.red.withValues(alpha: 0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cx.scaffold,
      appBar: AppBar(
        title: Text(_isEdit ? 'تعديل العنوان'.tr : 'إضافة عنوان'.tr),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: AppColors.primaryOrange, strokeWidth: 2),
                  ),
                )
              : IconButton(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  tooltip: 'حفظ'.tr,
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // City & Neighborhood Selection
              _sectionLabel('الموقع'.tr, Icons.location_on_rounded),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickCity,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: context.cx.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (_selectedCity != null)
                          ? AppColors.primaryOrange.withValues(alpha: 0.5)
                          : context.cx.divider,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_city_rounded,
                        color: _selectedCity != null
                            ? AppColors.primaryOrange
                            : context.cx.iconMuted,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_selectedCity != null) ...[
                              Text(
                                _selectedCity!,
                                style: TextStyle(
                                  color: context.cx.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_selectedNeighborhood != null) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _zoneColor(
                                                LocationData.getZoneForCity(
                                                    _selectedCity!))
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        LocationData.getZoneNameAr(
                                            _selectedCity!),
                                        style: TextStyle(
                                          color: _zoneColor(
                                              LocationData.getZoneForCity(
                                                  _selectedCity!)),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _selectedNeighborhood!,
                                      style: TextStyle(
                                        color: context.cx.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ] else
                              Text(
                                'اضغط لاختيار المدينة والحي'.tr,
                                style: TextStyle(
                                  color: context.cx.textHint,
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: context.cx.iconMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Address Details
              _sectionLabel('تفاصيل العنوان (اختياري)'.tr, Icons.edit_location_alt_outlined),
              const SizedBox(height: 10),
              TextFormField(
                controller: _addressDetailCtrl,
                style: TextStyle(color: context.cx.textPrimary),
                decoration: InputDecoration(
                  hintText: 'مثال: برج الشروق، الطابق 3'.tr,
                  prefixIcon: Icon(Icons.apartment_rounded,
                      color: context.cx.iconMuted),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Phone
              _sectionLabel('رقم الهاتف'.tr, Icons.phone_outlined),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneCtrl,
                style: TextStyle(color: context.cx.textPrimary),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '05XXXXXXXX',
                  prefixIcon:
                      Icon(Icons.phone_outlined, color: context.cx.iconMuted),
                ),
              ),
              const SizedBox(height: 24),

              // Notes
              _sectionLabel('ملاحظات (اختياري)'.tr, Icons.notes_outlined),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesCtrl,
                style: TextStyle(color: context.cx.textPrimary),
                decoration: InputDecoration(
                  hintText: 'ملاحظات إضافية للمندوب'.tr,
                  prefixIcon:
                      Icon(Icons.notes_outlined, color: context.cx.iconMuted),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // Default toggle
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: context.cx.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.cx.divider),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star_outline_rounded,
                        color: _isDefault
                            ? AppColors.goldenYellow
                            : context.cx.iconMuted,
                        size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('عنوان افتراضي'.tr,
                          style: TextStyle(
                              color: context.cx.textPrimary, fontSize: 14)),
                    ),
                    Switch(
                      value: _isDefault,
                      onChanged: (v) => setState(() => _isDefault = v),
                      activeTrackColor: AppColors.primaryOrange,
                      thumbColor: WidgetStateProperty.all(Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _isSaving
                        ? 'جاري الحفظ...'.tr
                        : (_isEdit ? 'تحديث العنوان'.tr : 'حفظ العنوان'.tr),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryOrange, size: 18),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(
                color: context.cx.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ],
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
