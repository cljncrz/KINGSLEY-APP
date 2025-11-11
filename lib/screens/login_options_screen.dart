import 'package:capstone/view/home/main_screen.dart';
import 'package:capstone/utils/app_textstyles.dart';
import 'package:capstone/screens/signin_screen.dart';
import 'package:capstone/screens/signup/signup_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginOptionsScreen extends StatelessWidget {
  const LoginOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Using a Scaffold to provide a standard app screen structure.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF131313) : Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png', // Using app logo
                  height: 250,
                ),
                const SizedBox(height: 24),
                Text(
                  'We provide a sparkling cleanliness,\nmaking your car look brand new again',
                  textAlign: TextAlign.center,
                  style: AppTextStyle.withColor(
                    AppTextStyle.bodySmall,
                    isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 48),
                // Log In Button
                SizedBox(
                  width: 250,
                  child: ElevatedButton(
                    onPressed: () => Get.to(() => const SigninScreen()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7F1618),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Log In',
                      style: AppTextStyle.withColor(
                        AppTextStyle.bodyMedium,
                        Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Guest Mode Button
                SizedBox(
                  width: 250,
                  child: ElevatedButton(
                    onPressed: () => Get.offAll(() => const MainScreen()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7F1618),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Guest',
                      style: AppTextStyle.withColor(
                        AppTextStyle.bodyMedium,
                        Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                // Sign up text
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Don’t have an account? ',
                        style: AppTextStyle.withColor(
                          AppTextStyle.bodySmall,
                          isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: 'Sign Up',
                        style: AppTextStyle.withColor(
                          AppTextStyle.bodySmall.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          Theme.of(context).primaryColor,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Get.to(() => const SignupScreen());
                          },
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
