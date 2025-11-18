import 'package:capstone/utils/app_textstyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone/controllers/custom_bottom_navbar.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

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
          'Terms & Conditions',
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
              'Terms and Conditions for Kingsley Carwash',
              style: AppTextStyle.withColor(AppTextStyle.h2, textColor!),
            ),
            const SizedBox(height: 16),
            Text(
              'Last updated: October 26, 2025',
              style: AppTextStyle.bodySmall,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('1. Introduction & Acceptance', textColor),
            _buildSectionContent(
              'Welcome to Kingsley Carwash! These Terms and Conditions ("Terms") govern your use of our mobile application and services. By creating an account or using our app, you agree to be bound by these Terms. If you do not agree, please do not use our services.',
              textColor,
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('2. Our Services', textColor),
            _buildSectionContent(
              'The Kingsley Carwash app provides a platform to book car wash and detailing services, manage appointments, track service progress, and process payments. We reserve the right to modify or discontinue services at any time.',
              textColor,
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('3. User Accounts', textColor),
            _buildSectionContent(
              'You are responsible for safeguarding your account and for any activities or actions under your password. You agree to provide accurate and complete information when creating an account.',
              textColor,
            ),
            const SizedBox(height: 16),
            _buildSectionTitle(
              '4. Bookings, Payments, and Cancellations',
              textColor,
            ),
            _buildSectionContent(
              'All bookings are subject to availability. Prices for services are listed in the app and are subject to change. Payments can be made via the available methods in the app. If you need to cancel or reschedule, please do so at least 2 hours before your scheduled appointment to avoid potential fees.',
              textColor,
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('5. Damage Policy', textColor),
            _buildSectionContent(
              'While we treat every vehicle with the utmost care, Kingsley Carwash is our responsible for pre-existing damage, loose parts, or electronic malfunctions. Any claim for damage incurred during a service must be reported to our staff before leaving the premises or via the "Damage Report" feature in the app within 24 hours of the service.',
              textColor,
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('6. User Conduct', textColor),
            _buildSectionContent(
              'You agree not to use the app for any unlawful purpose or in any way that could harm our services or reputation. This includes providing false information or interfering with the app\'s security features.',
              textColor,
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('7. Limitation of Liability', textColor),
            _buildSectionContent(
              'To the fullest extent permitted by law, Kingsley Carwash shall not be liable for any indirect, incidental, or consequential damages arising from your use of our app or services.',
              textColor,
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('8. Changes to Terms', textColor),
            _buildSectionContent(
              'We may update these Terms from time to time. We will notify you of any changes by posting the new Terms on this screen. You are advised to review this page periodically for any changes.',
              textColor,
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavbar(),
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
