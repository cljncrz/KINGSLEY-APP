import 'package:capstone/utils/app_textstyles.dart';
import 'package:capstone/utils/custom_textfield.dart';
import 'package:capstone/view/home/account/privacy_policy_screen.dart';
import 'package:capstone/view/home/account/terms_and_conditions_screen.dart';
import 'package:capstone/screens/signup/otp_verification_screen.dart';
import 'package:capstone/screens/signin_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _confirmpasswordController =
      TextEditingController();
  bool _agreeToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _confirmpasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_formKey.currentState!.validate()) {
      if (!_agreeToTerms) {
        Get.snackbar(
          'Error',
          'Please agree to the terms.',
          titleText: Text(
            'Terms and Conditions',
            style: AppTextStyle.withColor(
              AppTextStyle.bodySmall,
              isDark ? const Color(0xFF7F1618) : Colors.white,
            ),
          ),
          messageText: Text(
            'Please agree to the Privacy Policy and Terms of Use',
            style: AppTextStyle.withColor(
              AppTextStyle.bodySmall,
              isDark ? const Color(0xFF7F1618) : Colors.white,
            ),
          ),
          snackPosition: SnackPosition.TOP,
          backgroundColor: isDark ? Colors.white : const Color(0xFF7F1618),
          colorText: isDark ? const Color(0xFF7F1618) : Colors.white,
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Step 1: First create the email/password account
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

        if (userCredential.user != null) {
          // Step 2: Now send OTP to phone number for verification (security purposes)
          String phoneNumber = _phoneController.text.trim();
          if (!phoneNumber.startsWith('+')) {
            phoneNumber = '+63$phoneNumber';
          }

          await FirebaseAuth.instance.verifyPhoneNumber(
            phoneNumber: phoneNumber,
            verificationCompleted: (PhoneAuthCredential credential) async {
              // Auto-verification (iOS specific)
              await _completeSignUp(userCredential.user!.uid);
            },
            verificationFailed: (FirebaseAuthException e) {
              Get.snackbar(
                'Error',
                'Phone verification failed.',
                titleText: Text(
                  'Phone Verification Failed',
                  style: AppTextStyle.withColor(
                    AppTextStyle.bodySmall,
                    isDark ? const Color(0xFF7F1618) : Colors.white,
                  ),
                ),
                messageText: Text(
                  e.message ?? 'An unknown error occurred.',
                  style: AppTextStyle.withColor(
                    AppTextStyle.bodySmall,
                    isDark ? const Color(0xFF7F1618) : Colors.white,
                  ),
                ),
                snackPosition: SnackPosition.TOP,
                backgroundColor: isDark
                    ? Colors.white
                    : const Color(0xFF7F1618),
                colorText: isDark ? const Color(0xFF7F1618) : Colors.white,
              );
              setState(() {
                _isLoading = false;
              });
            },
            codeSent: (String verificationId, int? resendToken) {
              setState(() {
                _isLoading = false;
              });
              // Navigate to OTP verification screen
              Get.off(
                () => OtpVerificationScreen(
                  phoneNumber: _phoneController.text.trim(),
                  verificationId: verificationId,
                  resendToken: resendToken,
                  userName: _nameController.text.trim(),
                  userEmail: _emailController.text.trim(),
                  userId: userCredential.user!.uid,
                ),
              );
            },
            codeAutoRetrievalTimeout: (String verificationId) {},
            timeout: const Duration(seconds: 120),
          );
        }
      } on FirebaseAuthException catch (e) {
        Get.snackbar(
          'Error',
          'Sign up failed.',
          titleText: Text(
            'Sign Up Failed',
            style: AppTextStyle.withColor(
              AppTextStyle.bodySmall,
              isDark ? const Color(0xFF7F1618) : Colors.white,
            ),
          ),
          messageText: Text(
            e.message ?? 'An unknown error occurred.',
            style: AppTextStyle.withColor(
              AppTextStyle.bodySmall,
              isDark ? const Color(0xFF7F1618) : Colors.white,
            ),
          ),
          snackPosition: SnackPosition.TOP,
          backgroundColor: isDark ? Colors.white : const Color(0xFF7F1618),
          colorText: isDark ? const Color(0xFF7F1618) : Colors.white,
        );
        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        Get.snackbar(
          'Error',
          'An unexpected error occurred.',
          titleText: Text(
            'Error',
            style: AppTextStyle.withColor(
              AppTextStyle.bodySmall,
              isDark ? const Color(0xFF7F1618) : Colors.white,
            ),
          ),
          messageText: Text(
            e.toString(),
            style: AppTextStyle.withColor(
              AppTextStyle.bodySmall,
              isDark ? const Color(0xFF7F1618) : Colors.white,
            ),
          ),
          snackPosition: SnackPosition.TOP,
          backgroundColor: isDark ? Colors.white : const Color(0xFF7F1618),
          colorText: isDark ? const Color(0xFF7F1618) : Colors.white,
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _completeSignUp(String userId) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    try {
      // Get FCM token
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      // Store user data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'phoneVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
        'fcmToken': fcmToken,
        'role': 'user',
      });

      // Create a welcome notification
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'title': 'Welcome to Kingsley Carwash!',
            'body':
                'Your phone number has been verified. Explore our services now!',
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
            'type': 'welcome',
          });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to complete signup.',
        titleText: Text(
          'Error',
          style: AppTextStyle.withColor(
            AppTextStyle.bodySmall,
            isDark ? const Color(0xFF7F1618) : Colors.white,
          ),
        ),
        messageText: Text(
          e.toString(),
          style: AppTextStyle.withColor(
            AppTextStyle.bodySmall,
            isDark ? const Color(0xFF7F1618) : Colors.white,
          ),
        ),
        snackPosition: SnackPosition.TOP,
        backgroundColor: isDark ? Colors.white : const Color(0xFF7F1618),
        colorText: isDark ? const Color(0xFF7F1618) : Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // back button
              IconButton(
                onPressed: () => Get.back(),
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),

              const SizedBox(height: 15),
              Text(
                'Create Account',
                style: AppTextStyle.withColor(
                  AppTextStyle.h1,
                  isDark ? Colors.white : Colors.black,
                ),
              ),

              const SizedBox(height: 8),
              Text(
                'Sign up to get started!',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodyMedium,
                  isDark ? Colors.grey[400]! : Colors.grey[600]!,
                ),
              ),

              const SizedBox(height: 40),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // full name text field
                    CustomTextfield(
                      label: 'Full Name',
                      prefixIcon: Icons.person_outline,
                      keyboardType: TextInputType.name,
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // email text field
                    CustomTextfield(
                      label: 'Email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!GetUtils.isEmail(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // phone number text field
                    CustomTextfield(
                      label: 'Phone Number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      controller: _phoneController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (!GetUtils.isPhoneNumber(value)) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),
                    // password text field
                    CustomTextfield(
                      label: 'Password',
                      prefixIcon: Icons.lock_outline,
                      keyboardType: TextInputType.visiblePassword,
                      isPassword: true,
                      controller: _passwordController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // confirm password text field
                    CustomTextfield(
                      label: 'Confirm Password',
                      prefixIcon: Icons.lock_outline,
                      keyboardType: TextInputType.visiblePassword,
                      isPassword: true,
                      controller: _confirmpasswordController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Checkbox(
                    value: _agreeToTerms,
                    onChanged: (value) {
                      setState(() {
                        _agreeToTerms = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: 'I agree to the ',
                        style: AppTextStyle.withColor(
                          AppTextStyle.bodySmall,
                          isDark ? Colors.white : Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: 'Privacy Policy',
                            style: AppTextStyle.withColor(
                              AppTextStyle.bodySmall.copyWith(
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold,
                              ),
                              Theme.of(context).primaryColor,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Get.to(() => const PrivacyPolicyScreen());
                              },
                          ),
                          const TextSpan(text: ' and the '),
                          TextSpan(
                            text: 'Terms of Use',
                            style: AppTextStyle.withColor(
                              AppTextStyle.bodySmall.copyWith(
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold,
                              ),
                              Theme.of(context).primaryColor,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Get.to(() => const TermsAndConditionsScreen());
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // sign up button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                      : Text(
                          'Create Account',
                          style: AppTextStyle.withColor(
                            AppTextStyle.buttonMedium,
                            Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: AppTextStyle.withColor(
                      AppTextStyle.bodySmall,
                      isDark ? Colors.grey[400]! : Colors.grey[600]!,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.off(() => const SigninScreen()),
                    child: Text(
                      'Log In',
                      style: AppTextStyle.withColor(
                        AppTextStyle.bodyMedium,
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
