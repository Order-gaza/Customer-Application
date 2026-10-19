import 'package:flutter/material.dart';
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
import '../../modules/profile/views/points_view.dart';
import '../../modules/settings/settings_view.dart';
import '../../modules/settings/about_developer_view.dart';

class AppPages {
  static final Map<String, WidgetBuilder> routes = {
    // ── Launch ──
    AppRoutes.splash: (context) => const SplashView(),
    AppRoutes.onboarding: (context) => const OnboardingView(),

    // ── Auth ──
    AppRoutes.login: (context) => const LoginView(),
    AppRoutes.signup: (context) => const SignupView(),
    AppRoutes.verifyEmail: (context) => const VerifyEmailView(),
    AppRoutes.forgotPassword: (context) => const ForgotPasswordView(),
    AppRoutes.verifyResetOtp: (context) => const VerifyResetOtpView(),
    AppRoutes.resetPassword: (context) => const ResetPasswordView(),

    // ── Main Shell (Bottom Nav) ──
    AppRoutes.main: (context) => const MainShell(),

    // ── Vendors ──
    AppRoutes.allVendors: (context) => const AllVendorsView(),
    AppRoutes.vendorDetail: (context) => const VendorDetailView(),
    AppRoutes.itemDetail: (context) => const ItemDetailView(),

    // ── Categories ──
    AppRoutes.allCategories: (context) => const AllCategoriesView(),
    AppRoutes.categoryItems: (context) => const CategoryItemsView(),
    AppRoutes.allItems: (context) => const AllItemsView(),

    // ── Search ──
    AppRoutes.search: (context) => const SearchView(),

    // ── Checkout ──
    AppRoutes.checkout: (context) => const CheckoutView(),
    AppRoutes.orderConfirmation: (context) => const OrderConfirmationView(),

    // ── Addresses ──
    AppRoutes.addresses: (context) => const AddressListView(),
    AppRoutes.addAddress: (context) => const AddAddressView(),
    AppRoutes.editAddress: (context) => const AddAddressView(),

    // ── Order Detail ──
    AppRoutes.orderDetail: (context) => const OrderDetailView(),
    AppRoutes.orderTracking: (context) => const OrderTrackingView(),
    AppRoutes.rateOrder: (context) => const RateOrderView(),

    // ── Notifications ──
    AppRoutes.notifications: (context) => const NotificationsView(),

    // ── Profile ──
    AppRoutes.editProfile: (context) => const EditProfileView(),
    AppRoutes.changePassword: (context) => const ChangePasswordView(),
    AppRoutes.myPoints: (context) => const PointsView(),
    AppRoutes.settings: (context) => const SettingsView(),
    AppRoutes.aboutDeveloper: (context) => const AboutDeveloperView(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final builder = routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute(
        builder: builder,
        settings: settings,
      );
    }
    return null;
  }
}
