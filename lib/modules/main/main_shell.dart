import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/theme_colors.dart';
import '../home/home_view.dart';
import '../cart/cart_view.dart';
import '../favorites/favorites_view.dart';
import '../orders/views/orders_list_view.dart';
import '../profile/views/profile_view.dart';
import '../cart/cart_controller.dart';
import '../favorites/favorites_controller.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _pages = const [
    HomeView(),
    OrdersListView(),
    FavoritesView(),
    CartView(),
    ProfileView(),
  ];

  @override
  void initState() {
    super.initState();
    Get.put(CartController());
    Get.put(FavoritesController());
    // Support navigating directly to a specific tab (e.g. cart from snackbar)
    final args = Get.arguments;
    if (args is Map && args['tab'] is int) {
      _currentIndex = args['tab'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvoked: (didPop) {
        if (didPop) return;
        setState(() => _currentIndex = 0);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        extendBody: true,
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: context.cx.bottomNav,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: context.cx.shadow,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        height: 68,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(context, index: 1, icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'Orders'.tr),
            _buildNavItem(context, index: 2, icon: Icons.favorite_border_rounded, activeIcon: Icons.favorite_rounded, label: 'Favorites'.tr, badgeWidget: _favBadge(context)),
            _buildCenterButton(context),
            _buildNavItem(context, index: 3, icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart_rounded, label: 'Cart'.tr, badgeWidget: _cartBadge(context)),
            _buildNavItem(context, index: 4, icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'.tr),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {required int index, required IconData icon, required IconData activeIcon, required String label, Widget? badgeWidget}) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            badgeWidget ?? Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primaryOrange : context.cx.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
              color: isActive ? AppColors.primaryOrange : context.cx.textSecondary,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            )),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(top: 3),
              width: isActive ? 5 : 0,
              height: isActive ? 5 : 0,
              decoration: const BoxDecoration(color: AppColors.primaryOrange, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton(BuildContext context) {
    final isActive = _currentIndex == 0;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 0),
      child: Container(
        width: 56, height: 56,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: isActive
                ? [AppColors.primaryOrange, AppColors.darkOrange]
                : [context.cx.surface, context.cx.card],
          ),
          shape: BoxShape.circle,
          boxShadow: isActive ? [BoxShadow(color: AppColors.primaryOrange.withValues(alpha: 0.35), blurRadius: 14, spreadRadius: 1, offset: const Offset(0, 4))] : [],
        ),
        child: Icon(Icons.home_rounded, color: isActive ? Colors.white : context.cx.textSecondary, size: 28),
      ),
    );
  }

  Widget _cartBadge(BuildContext context) {
    final isActive = _currentIndex == 3;
    return Obx(() {
      final count = CartController.to.cartItemCount.value;
      return Badge(
        isLabelVisible: count > 0,
        label: Text('$count', style: const TextStyle(fontSize: 9, color: Colors.white)),
        backgroundColor: AppColors.primaryOrange,
        child: Icon(isActive ? Icons.shopping_cart_rounded : Icons.shopping_cart_outlined, color: isActive ? AppColors.primaryOrange : context.cx.textSecondary, size: 24),
      );
    });
  }

  Widget _favBadge(BuildContext context) {
    final isActive = _currentIndex == 2;
    return Obx(() {
      final count = FavoritesController.to.totalCount;
      return Badge(
        isLabelVisible: count > 0,
        label: Text('$count', style: const TextStyle(fontSize: 9, color: Colors.white)),
        backgroundColor: AppColors.error,
        child: Icon(isActive ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isActive ? AppColors.primaryOrange : context.cx.textSecondary, size: 24),
      );
    });
  }
}
