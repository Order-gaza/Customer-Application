import 'package:get/get.dart';
import 'app_routes.dart';
import '../../modules/splash/splash_view.dart';
import '../../modules/onboarding/onboarding_view.dart';
import '../../modules/auth/views/login_view.dart';
import '../../modules/auth/views/signup_view.dart';
import '../../modules/auth/views/verify_email_view.dart';
import '../../modules/auth/views/forgot_password_view.dart';
import '../../modules/auth/views/verify_reset_otp_view.dart';
import '../../modules/auth/views/reset_password_view.dart';
import '../../modules/main/main_shell.dart';
import '../../modules/vendors/views/vendor_detail_view.dart';
import '../../modules/vendors/views/all_vendors_view.dart';
import '../../modules/vendors/views/item_detail_view.dart';
import '../../modules/search/search_view.dart';
import '../../modules/categories/views/all_categories_view.dart';
import '../../modules/categories/views/category_items_view.dart';
import '../../modules/home/all_items_view.dart';
import '../../modules/checkout/views/checkout_view.dart';
import '../../modules/checkout/views/order_confirmation_view.dart';
import '../../modules/addresses/views/address_list_view.dart';
import '../../modules/addresses/views/add_address_view.dart';
import '../../modules/orders/views/order_detail_view.dart';
import '../../modules/orders/views/order_tracking_view.dart';
import '../../modules/orders/views/rate_order_view.dart';
import '../../modules/notifications/notifications_view.dart';
import '../../modules/profile/views/edit_profile_view.dart';
import '../../modules/profile/views/change_password_view.dart';
import '../../modules/settings/settings_view.dart';

import '../../modules/settings/about_developer_view.dart';

class AppPages {
  static final pages = <GetPage>[
    // ── Launch ──
    GetPage(name: AppRoutes.splash, page: () => const SplashView()),
    GetPage(name: AppRoutes.onboarding, page: () => const OnboardingView()),

    // ── Auth ──
    GetPage(name: AppRoutes.login, page: () => const LoginView()),
    GetPage(name: AppRoutes.signup, page: () => const SignupView()),
    GetPage(name: AppRoutes.verifyEmail, page: () => const VerifyEmailView()),
    GetPage(name: AppRoutes.forgotPassword, page: () => const ForgotPasswordView()),
    GetPage(name: AppRoutes.verifyResetOtp, page: () => const VerifyResetOtpView()),
    GetPage(name: AppRoutes.resetPassword, page: () => const ResetPasswordView()),

    // ── Main Shell (Bottom Nav) ──
    GetPage(name: AppRoutes.main, page: () => const MainShell()),

    // ── Vendors ──
    GetPage(name: AppRoutes.allVendors, page: () => const AllVendorsView()),
    GetPage(name: AppRoutes.vendorDetail, page: () => const VendorDetailView()),
    GetPage(name: AppRoutes.itemDetail, page: () => const ItemDetailView()),

    // ── Categories ──
    GetPage(name: AppRoutes.allCategories, page: () => const AllCategoriesView()),
    GetPage(name: AppRoutes.categoryItems, page: () => const CategoryItemsView()),
    GetPage(name: AppRoutes.allItems, page: () => const AllItemsView()),

    // ── Search ──
    GetPage(name: AppRoutes.search, page: () => const SearchView()),

    // ── Checkout ──
    GetPage(name: AppRoutes.checkout, page: () => const CheckoutView()),
    GetPage(name: AppRoutes.orderConfirmation, page: () => const OrderConfirmationView()),

    // ── Addresses ──
    GetPage(name: AppRoutes.addresses, page: () => const AddressListView()),
    GetPage(name: AppRoutes.addAddress, page: () => const AddAddressView()),
    GetPage(name: AppRoutes.editAddress, page: () => const AddAddressView()),

    // ── Order Detail ──
    GetPage(name: AppRoutes.orderDetail, page: () => const OrderDetailView()),
    GetPage(name: AppRoutes.orderTracking, page: () => const OrderTrackingView()),
    GetPage(name: AppRoutes.rateOrder, page: () => const RateOrderView()),

    // ── Notifications ──
    GetPage(name: AppRoutes.notifications, page: () => const NotificationsView()),

    // ── Profile ──
    GetPage(name: AppRoutes.editProfile, page: () => const EditProfileView()),
    GetPage(name: AppRoutes.changePassword, page: () => const ChangePasswordView()),
    GetPage(name: AppRoutes.settings, page: () => const SettingsView()),
    GetPage(name: AppRoutes.aboutDeveloper, page: () => const AboutDeveloperView()),
  ];
}
