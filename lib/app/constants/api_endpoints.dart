/// API Endpoints for the Order User App
class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://appforyou.store/backendOrder',
  );

  // ── User Auth ──
  static const String login = '$baseUrl/user_auth/login.php';
  static const String signup = '$baseUrl/user_auth/signup.php';
  static const String verifyEmail = '$baseUrl/user_auth/verify_email.php';
  static const String logout = '$baseUrl/user_auth/logout.php';
  static const String validateSession =
      '$baseUrl/user_auth/validate_session.php';
  static const String forgotPassword =
      '$baseUrl/user_auth/forgot_password.php';
  static const String verifyResetOtp =
      '$baseUrl/user_auth/verify_reset_otp.php';
  static const String resetPassword =
      '$baseUrl/user_auth/reset_password.php';
  static const String resendOtp = '$baseUrl/user_auth/resend_otp.php';
  static const String changePassword =
      '$baseUrl/user_auth/change_password.php';
  static const String registerFcmToken =
      '$baseUrl/user_auth/register_fcm_token.php';

  // ── Home / Discovery ──
  static const String homeAdvertisements =
      '$baseUrl/user_home/get_advertisements.php';
  static const String homeFeaturedVendors =
      '$baseUrl/user_home/get_featured_vendors.php';
  static const String homePopularItems =
      '$baseUrl/user_home/get_popular_items.php';
  static const String homeTopCategories =
      '$baseUrl/user_home/get_top_categories.php';
  static const String homeRecordAdClick =
      '$baseUrl/user_home/record_ad_click.php';

  // ── Vendors ──
  static const String vendorsGetAll = '$baseUrl/user_vendors/get_all.php';
  static const String vendorsGetById = '$baseUrl/user_vendors/get_by_id.php';
  static const String vendorsGetByType =
      '$baseUrl/user_vendors/get_by_type.php';
  static const String vendorsGetMenu = '$baseUrl/user_vendors/get_menu.php';
  static const String vendorsGetRatings =
      '$baseUrl/user_vendors/get_ratings.php';
  static const String vendorsSearch = '$baseUrl/user_vendors/search.php';

  // ── Items ──
  static const String itemsGetByCategory =
      '$baseUrl/user_items/get_by_category.php';
  static const String itemsGetById = '$baseUrl/user_items/get_by_id.php';
  static const String itemsSearch = '$baseUrl/user_items/search.php';
  static const String itemsGetAll = '$baseUrl/user_items/get_all.php';
  static const String itemsByGlobalCategory =
      '$baseUrl/user_items/get_by_global_category.php';

  // ── Favorites ──
  static const String favoritesToggle =
      '$baseUrl/user_favorites/toggle.php';
  static const String favoritesGetAll =
      '$baseUrl/user_favorites/get_all.php';
  static const String favoritesCheck =
      '$baseUrl/user_favorites/check.php';

  // ── Cart ──
  static const String cartAdd = '$baseUrl/user_cart/add_to_cart.php';
  static const String cartGet = '$baseUrl/user_cart/get_cart.php';
  static const String cartUpdate = '$baseUrl/user_cart/update_item.php';
  static const String cartRemove = '$baseUrl/user_cart/remove_item.php';
  static const String cartClear = '$baseUrl/user_cart/clear_cart.php';
  static const String cartDeliveryFee =
      '$baseUrl/user_cart/get_delivery_fee.php';

  // ── Orders ──
  static const String ordersCreate = '$baseUrl/user_orders/create_order.php';
  static const String ordersGetAll = '$baseUrl/user_orders/get_orders.php';
  static const String ordersGetDetail =
      '$baseUrl/user_orders/get_order_detail.php';
  static const String ordersTrack = '$baseUrl/user_orders/track_order.php';
  static const String ordersCancel = '$baseUrl/user_orders/cancel_order.php';
  static const String ordersRate = '$baseUrl/user_orders/rate_order.php';

  // ── Addresses ──
  static const String addressesGetAll =
      '$baseUrl/user_addresses/get_addresses.php';
  static const String addressesAdd =
      '$baseUrl/user_addresses/add_address.php';
  static const String addressesUpdate =
      '$baseUrl/user_addresses/update_address.php';
  static const String addressesDelete =
      '$baseUrl/user_addresses/delete_address.php';
  static const String addressesSetDefault =
      '$baseUrl/user_addresses/set_default.php';
  static const String getLocations =
      '$baseUrl/user_addresses/get_locations.php';

  // ── Notifications ──
  static const String notificationsGetAll =
      '$baseUrl/user_notifications/get_all.php';
  static const String notificationsUnreadCount =
      '$baseUrl/user_notifications/get_unread_count.php';
  static const String notificationsMarkRead =
      '$baseUrl/user_notifications/mark_read.php';
  static const String notificationsMarkAllRead =
      '$baseUrl/user_notifications/mark_all_read.php';
  static const String notificationsDelete =
      '$baseUrl/user_notifications/delete.php';

  // ── Profile ──
  static const String profileGet = '$baseUrl/user_profile/get_profile.php';
  static const String profileUpdate =
      '$baseUrl/user_profile/update_profile.php';
  static const String profileUploadImage =
      '$baseUrl/user_profile/upload_profile_image.php';
  static const String profileDeleteImage =
      '$baseUrl/user_profile/delete_profile_image.php';
  static const String profileChangePassword =
      '$baseUrl/user_profile/change_password.php';
  static const String profileDeleteAccount =
      '$baseUrl/user_profile/delete_account.php';
}
