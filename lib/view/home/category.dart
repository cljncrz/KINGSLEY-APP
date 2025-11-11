import 'package:capstone/utils/app_textstyles.dart';
import 'package:capstone/view/widgets/book_services.dart';
import 'package:capstone/view/home/damage_report_screen.dart';
import 'package:capstone/view/home/technician_profiles_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoryItem {
  final String title;
  final IconData icon;

  CategoryItem({required this.title, required this.icon});
}

class Category extends StatefulWidget {
  const Category({super.key});

  @override
  State<Category> createState() => _CategoryState();
}

class _CategoryState extends State<Category> {
  int selectedIndex = 0;
  final List<CategoryItem> categories = [
    CategoryItem(title: 'Book\nServices', icon: Icons.book_online_outlined),
    CategoryItem(
      title: 'Technician\nProfiles',
      icon: Icons.people_outline_rounded,
    ),
    CategoryItem(title: 'Damage\nReport', icon: Icons.warning_amber_rounded),
  ];

  void _onCategoryTap(int index) {
    // The setState is kept to visually show selection, though navigation happens immediately.
    setState(() {
      selectedIndex = index;
    });

    switch (index) {
      case 0:
        Get.to(() => const BookServices());
        break;
      case 1:
        Get.to(() => const TechnicianProfilesScreen());
        break;
      case 2:
        Get.to(() => const DamageReportScreen());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          categories.length,
          (index) => _CategoryItem(
            icon: categories[index].icon,
            text: categories[index].title,
            isSelected: selectedIndex == index,
            onTap: () => _onCategoryTap(index),
          ),
        ),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.icon,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white : const Color(0xFF7F1618);
    final textColor = Theme.of(context).textTheme.bodySmall!.color!;
    return SizedBox(
      width: 90,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(icon, color: color, size: 40),
            onPressed: onTap,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: AppTextStyle.withColor(
                AppTextStyle.bodySmall.copyWith(height: 1.2),
                textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
