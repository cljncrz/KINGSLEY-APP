import 'package:capstone/controllers/navigation_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomBottomNavbar extends StatelessWidget {
  final bool isMainScreen;
  const CustomBottomNavbar({super.key, this.isMainScreen = false});

  @override
  Widget build(BuildContext context) {
    final NavigationController navigationController =
        Get.find<NavigationController>();

    void handleOnTap(int index) {
      // If we are on a screen that is not one of the main tabs, pop back to the main screen.
      if (!isMainScreen) {
        Get.back();
      }
      // Change the index to navigate to the correct tab on the MainScreen.
      // This works because the CustomBottomNavbar on other screens will be replaced by the one on MainScreen after Get.back().
      navigationController.changeIndex(index);
    }

    return Obx(
      () => BottomNavigationBar(
        currentIndex: navigationController.currentIndex.value,
        onTap: handleOnTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes_outlined),
            label: 'Track Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
