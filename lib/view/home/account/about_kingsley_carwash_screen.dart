import 'package:capstone/utils/app_textstyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone/controllers/custom_bottom_navbar.dart';

class AboutKingsleyCarwashScreen extends StatelessWidget {
  const AboutKingsleyCarwashScreen({super.key});

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
          'About Kingsley Carwash',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 150,
                width: 150,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'At Kingsley Carwash and Detailing Services, we treat every vehicle like royalty. Proudly serving, we specialize in premium carwash and detailing solutions designed to bring out the best in your ride—inside and out.',
              style: AppTextStyle.withColor(
                AppTextStyle.bodySmall,
                Theme.of(context).textTheme.bodyLarge!.color!,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Our expert team is committed to delivering high-quality, efficient, and reliable services including:',
              style: AppTextStyle.withColor(
                AppTextStyle.bodySmall,
                Theme.of(context).textTheme.bodySmall!.color!,
              ),
            ),
            const SizedBox(height: 8),
            _buildServiceItem(context, 'Full-service car washing'),
            _buildServiceItem(context, 'Interior and exterior detailing'),
            _buildServiceItem(context, 'Engine cleaning'),
            _buildServiceItem(context, 'Polishing and waxing'),
            _buildServiceItem(context, 'Eco-friendly waterless options'),
            const SizedBox(height: 16),
            Text(
              'With the AutoFreshHub mobile app, you can now book services, customize your preferences, track job progress, and enjoy exclusive geo-fenced promos—all from your phone. Experience the ultimate in car care where every car reigns supreme.',
              style: AppTextStyle.withColor(
                AppTextStyle.bodySmall,
                Theme.of(context).textTheme.bodySmall!.color!,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavbar(),
    );
  }

  Widget _buildServiceItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: AppTextStyle.withColor(
              AppTextStyle.bodyMedium,
              Theme.of(context).textTheme.bodyMedium!.color!,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTextStyle.withColor(
                AppTextStyle.bodySmall,
                Theme.of(context).textTheme.bodySmall!.color!,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
