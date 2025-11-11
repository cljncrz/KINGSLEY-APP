import 'package:capstone/controllers/navigation_controller.dart';
import 'package:capstone/controllers/theme_controller.dart';
import 'package:capstone/view/home/account/account_screen.dart';
import 'package:capstone/view/home/track_booking_screen.dart';
import 'package:capstone/controllers/custom_bottom_navbar.dart';
import 'package:capstone/view/home/favorites.dart';
import 'package:capstone/view/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NavigationController navigationController =
        Get.find<NavigationController>();
    return GetBuilder<ThemeController>(
      builder: (themeController) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Obx(
            () => IndexedStack(
              key: ValueKey(navigationController.currentIndex.value),
              index: navigationController.currentIndex.value,
              children: const [
                HomeScreen(),
                TrackBookingScreen(),
                FavoritesScreen(),
                AccountScreen(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const CustomBottomNavbar(),
      ),
    );
  }
}
