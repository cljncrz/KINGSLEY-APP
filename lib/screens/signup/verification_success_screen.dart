import 'package:capstone/utils/app_textstyles.dart';
import 'package:capstone/screens/signup/enable_location_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VerificationSuccessScreen extends StatelessWidget {
  const VerificationSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // After a short delay, navigate to the enable location screen.
    Future.delayed(const Duration(seconds: 4), () {
      Get.offAll(() => const EnableLocationScreen());
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/check.png', // Make sure you have this image.
              width: 150,
            ),
            const SizedBox(height: 32),
            Text(
              'You are Verified!',
              style: AppTextStyle.withColor(
                AppTextStyle.h2,
                isDark ? Colors.white : const Color(0xFF141414),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
