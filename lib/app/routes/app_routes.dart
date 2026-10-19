/// Route name constants for the Order user app
abstract class AppRoutes {
  // ── Launch ──
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';

  // ── Auth ──
  static const String login = '/login';
  static const String signup = '/signup';
  static const String verifyEmail = '/verify-email';
  static const String forgotPassword = '/forgot-password';
  static const String verifyResetOtp = '/verify-reset-otp';
  static const String resetPassword = '/reset-password';

  // ── Main (Tab Shell) ──
  static const String main = '/main';

  // ── Home ──
  static const String home = '/home';

  // ── Vendors ──
  static const String vendors = '/vendors';
  static const String allVendors = '/all-vendors';
  static const String vendorDetail = '/vendor-detail';
  static const String itemDetail = '/item-detail';

  // ── Categories ──
  static const String allCategories = '/all-categories';
  static const String categoryItems = '/category-items';
  static const String allItems = '/all-items';

  // ── Search ──
  static const String search = '/search';

  // ── Cart ──
  static const String cart = '/cart';

  // ── Checkout ──
  static const String checkout = '/checkout';
  static const String orderConfirmation = '/order-confirmation';

  // ── Addresses ──
  static const String addresses = '/addresses';
  static const String addAddress = '/add-address';
  static const String editAddress = '/edit-address';

  // ── Orders ──
  static const String orders = '/orders';
  static const String orderDetail = '/order-detail';
  static const String orderTracking = '/order-tracking';
  static const String rateOrder = '/rate-order';

  // ── Notifications ──
  static const String notifications = '/notifications';

  // ── Profile ──
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String changePassword = '/change-password';
  static const String myPoints = '/my-points';
  static const String settings = '/settings';
  static const String aboutDeveloper = '/about-developer';
}
