import '../../shared/localization/app_translations.dart';

/// Application-wide constants matching the PHP backend
class AppConstants {
  AppConstants._();

  // ── User Roles ──
  static const String roleSuperAdmin = 'super_admin';
  static const String roleAdmin = 'admin';
  static const String roleVendor = 'vendor';
  static const String roleCustomer = 'customer';

  // ── Order Statuses ──
  static const String orderPending = 'pending';
  static const String orderAdminConfirmed = 'admin_confirmed';
  static const String orderSentToVendor = 'sent_to_vendor';
  static const String orderVendorAccepted = 'vendor_accepted';
  static const String orderPreparing = 'preparing';
  static const String orderReadyForPickup = 'ready_for_pickup';
  static const String orderOutForDelivery = 'out_for_delivery';
  static const String orderDelivered = 'delivered';
  static const String orderCancelled = 'cancelled';

  // ── Vendor Types ──
  static const String vendorTypeRestaurant = 'restaurant';
  static const String vendorTypeStore = 'store';
  static const String vendorTypeCafe = 'cafe';

  // ── Payment ──
  static const String payCash = 'cash_on_delivery';
  static const String payBank = 'bank_transfer';
  static const String paymentPending = 'pending';
  static const String paymentCollected = 'collected';
  static const String paymentFailed = 'failed';

  // ── Storage Keys ──
  static const String storageToken = 'auth_token';
  static const String storageRole = 'user_role';
  static const String storageUserId = 'user_id';
  static const String storageUserName = 'user_name';
  static const String storageUserEmail = 'user_email';
  static const String storageUserPhone = 'user_phone';
  static const String storageProfileImage = 'profile_image';
  static const String storageOnboardingSeen = 'onboarding_seen';

  // ── Currency ──
  static const String currency = '₪';

  // ── Human-readable status labels ──
  static String orderStatusLabel(String status) {
    switch (status) {
      case orderPending:
        return 'Pending'.tr;
      case orderAdminConfirmed:
        return 'Confirmed'.tr;
      case orderSentToVendor:
        return 'Sent to Vendor'.tr;
      case orderVendorAccepted:
        return 'Accepted'.tr;
      case orderPreparing:
        return 'Preparing'.tr;
      case orderReadyForPickup:
        return 'Ready for Pickup'.tr;
      case orderOutForDelivery:
        return 'Out for Delivery'.tr;
      case orderDelivered:
        return 'Delivered'.tr;
      case orderCancelled:
        return 'Cancelled'.tr;
      default:
        return status.tr;
    }
  }

  static String vendorTypeLabel(String type) {
    switch (type) {
      case vendorTypeRestaurant:
        return 'Restaurant'.tr;
      case vendorTypeStore:
        return 'Store'.tr;
      case vendorTypeCafe:
        return 'Café'.tr;
      default:
        return type.tr;
    }
  }

  static String paymentMethodLabel(String method) {
    switch (method) {
      case payCash:
        return 'Cash on Delivery'.tr;
      case payBank:
        return 'Bank Transfer'.tr;
      default:
        return method.tr;
    }
  }
}
