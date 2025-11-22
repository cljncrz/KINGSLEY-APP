import 'package:capstone/controllers/theme_controller.dart';
import 'package:capstone/controllers/notification_controller.dart';
import 'package:capstone/utils/app_textstyles.dart';
import 'package:capstone/view/home/chat_screen.dart';
import 'package:capstone/view/home/cart_screen.dart';
import 'package:capstone/view/home/notification_screen.dart';
import 'package:capstone/view/home/category.dart';
import 'package:capstone/view/home/our_partners.dart';
import 'package:capstone/view/home/onsite_services.dart';
import 'package:capstone/view/home/promos.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final NotificationController notificationController =
        Get.find<NotificationController>();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // header section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // theme.button
                    GetBuilder<ThemeController>(
                      builder: (controller) => IconButton(
                        onPressed: () => controller.toggleTheme(),
                        icon: Icon(
                          controller.isDarkMode
                              ? Icons.light_mode
                              : Icons.dark_mode,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, Welcome!',
                          style: AppTextStyle.withColor(
                            AppTextStyle.bodyMedium,
                            isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(),
                    // bookcart icon
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Get.to(() => const CartScreen()),
                      icon: const Icon(Icons.book_outlined),
                    ),
                    const SizedBox(width: 2),
                    // notification icon
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Get.to(() => const NotificationScreen()),
                      icon: Obx(() {
                        final unreadCount =
                            notificationController.unreadNotificationCount;
                        return Stack(
                          children: [
                            const Icon(Icons.notifications_outlined),
                            if (unreadCount > 0)
                              Positioned(
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(1),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      }),
                    ),
                    const SizedBox(width: 2),
                    // chat icon
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Get.to(() => const AiChatbotScreen()),
                      icon: const Icon(Icons.chat_outlined),
                    ),
                  ],
                ),
              ),
              // category container
              const Category(),

              // onsite services
              const OnsiteServices(),

              // sale banner
              const Promos(),

              // our partners
              const OurPartners(),
            ],
          ),
        ),
      ),
    );
  }
}
