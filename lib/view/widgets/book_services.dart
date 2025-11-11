import 'package:capstone/utils/app_textstyles.dart';
import 'package:capstone/view/home/cart_screen.dart';
import 'package:capstone/view/home/notification_screen.dart';
import 'package:capstone/view/product/product_grid.dart';
import 'package:capstone/models/product.dart';
import 'package:capstone/view/widgets/features/detailing_services.dart';
import 'package:capstone/controllers/custom_bottom_navbar.dart';
import 'package:capstone/view/widgets/features/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BookServices extends StatefulWidget {
  const BookServices({super.key});

  @override
  State<BookServices> createState() => _BookServicesState();
}

class _BookServicesState extends State<BookServices> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        title: Text(
          'Book Services',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Get.to(() => const CartScreen()),
            icon: const Icon(Icons.book_outlined),
          ),
          IconButton(
            onPressed: () => Get.to(() => const NotificationScreen()),
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Services(
                selectedIndex: selectedIndex,
                onSelected: (index) => setState(() => selectedIndex = index),
              ),
              if (selectedIndex == 0) ProductGrid(products: products),
              if (selectedIndex == 1) const DetailingServices(),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          const CustomBottomNavbar(), // isMainScreen is false by default
    );
  }
}
