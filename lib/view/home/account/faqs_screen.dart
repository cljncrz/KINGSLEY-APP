import 'package:capstone/utils/app_textstyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone/controllers/custom_bottom_navbar.dart';

class _FaqItem {
  final String question;
  final String answer;

  _FaqItem(this.question, this.answer);
}

class FaqsScreen extends StatelessWidget {
  const FaqsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<_FaqItem> faqItems = [
      _FaqItem(
        'What is AutoFresh Hub?',
        'AutoFresh Hub is a mobile and web-based application designed to streamline carwash and detailing services through location-based geofencing, online booking, real-time updates, and service monitoring for both customers and administrators.',
      ),
      _FaqItem(
        'What is geofencing and how does it work in this app?',
        "Geofencing uses GPS to detect when a customer enters or exits a specific location range. AutoFresh Hub uses this technology to notify the carwash team when you're nearby, preparing them in advance for your arrival.",
      ),
      _FaqItem(
        'Can I reschedule or cancel my appointment?',
        'Yes, go to your appointment history, tap on the scheduled booking, and choose to reschedule or cancel. Please try to make changes at least 1 hour before your appointment time.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black, // Use context theme
          ),
        ),
        title: Text(
          'Frequently Asked Questions',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? Colors.white : Colors.black, // Use context theme
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: Image.asset('assets/images/logo.png', height: 150),
            ), // <-- This logo will be updated when you replace the file.
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: faqItems.length,
              itemBuilder: (context, index) {
                final item = faqItems[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    title: Text(
                      item.question,
                      style: AppTextStyle.withColor(
                        AppTextStyle.bodyMedium,
                        Theme.of(context).textTheme.bodyLarge!.color!,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                        child: Text(item.answer, style: AppTextStyle.bodySmall),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavbar(),
    );
  }
}
