import 'package:capstone/utils/app_textstyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge!.color;

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
          'Privacy Policy',
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
            Text(
              'Privacy Policy for Kingsley Carwash',
              style: AppTextStyle.withColor(AppTextStyle.h2, textColor!),
            ),
            const SizedBox(height: 16),
            Text(
              'Last updated: October 26, 2025',
              style: AppTextStyle.bodySmall,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('1. Introduction', textColor),
            _buildSectionContent(
              'Welcome to AutoFresh Hub. We are committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
              textColor,
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('2. Information We Collect', textColor),
            _buildSectionContent(
              'We may collect personal identification information, including but not limited to your name, email address, phone number, and vehicle details. We also collect location data to provide geofencing features.',
              textColor,
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('3. How We Use Your Information', textColor),
            _buildSectionContent(
              'Your information is used to: provide and manage your account, process your bookings and payments, send you notifications and updates, and improve our services.',
              textColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(title, style: AppTextStyle.withColor(AppTextStyle.h3, color));
  }

  Widget _buildSectionContent(String content, Color color) {
    return Text(
      content,
      style: AppTextStyle.withColor(AppTextStyle.bodySmall, color),
    );
  }
}
