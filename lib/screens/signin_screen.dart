import 'package:capstone/provider/auth_provider.dart';
import 'package:capstone/utils/app_textstyles.dart';
import 'package:capstone/utils/custom_textfield.dart';
import 'package:capstone/screens/forgot_password_screen.dart';
import 'package:capstone/view/home/main_screen.dart';
import 'package:capstone/screens/signup/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _storage = GetStorage();

  bool _rememberMe = false;
  bool _isLoggingIn = false;
  bool _isGoogleLoggingIn = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
              const SizedBox(height: 20),
              Text(
                'Welcome Back!',
                style: AppTextStyle.withColor(
                  AppTextStyle.h1,
                  Theme.of(context).textTheme.bodyLarge!.color!,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Log in to continue booking',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodySmall,
                  isDark ? Colors.grey[500]! : Colors.grey[600]!,
                ),
              ),

              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextfield(
                      label: 'Email or Phone Number',
                      prefixIcon: Icons.person_outline,
                      keyboardType: TextInputType.emailAddress,
                      controller: _loginController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email or phone number';
                        }
                        if (!GetUtils.isEmail(value) &&
                            !GetUtils.isPhoneNumber(value)) {
                          return 'Please enter a valid email or phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
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
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                            ),
                            Text(
                              'Remember Me',
                              style: AppTextStyle.withColor(
                                AppTextStyle.bodySmall,
                                isDark
                                    ? const Color(0xFF7F1618)
                                    : const Color(0xFF7F1618),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => Get.to(() => ForgotPasswordScreen()),
                          child: Text(
                            'Forgot Password?',
                            style: AppTextStyle.withColor(
                              AppTextStyle.bodySmall,
                              isDark
                                  ? const Color(0xFF7F1618)
                                  : const Color(0xFF7F1618),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // sign in button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoggingIn ? null : _handleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoggingIn
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                      : Text(
                          'Log In',
                          style: AppTextStyle.withColor(
                            AppTextStyle.buttonMedium,
                            Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              // Divider
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Divider(
                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                      thickness: 1,
                      indent: 60,
                      endIndent: 5,
                    ),
                  ),
                  Text(
                    'Or sign in with',
                    style: AppTextStyle.withColor(
                      AppTextStyle.labelMedium,
                      isDark ? Colors.grey[400]! : Colors.grey[600]!,
                    ),
                  ),
                  Flexible(
                    child: Divider(
                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                      thickness: 1,
                      indent: 5,
                      endIndent: 60,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Google Button
              Center(
                child: SizedBox(
                  width: 72,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _isGoogleLoggingIn ? null : _handleGoogleSignIn,
                    child: _isGoogleLoggingIn
                        ? const CircularProgressIndicator()
                        : const Image(
                            image: AssetImage('assets/images/google_logo.png'),
                            width: 28.0,
                          ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: AppTextStyle.withColor(
                      AppTextStyle.bodySmall,
                      isDark ? Colors.grey[500]! : Colors.grey[600]!,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.to(() => const SignupScreen()),
                    child: Text(
                      'Sign Up',
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

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  // sign in button onPressed
  Future<void> _handleSignIn() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // This is the correct _handleSignIn
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoggingIn = true;
    });

    try {
      // The validator allows a phone number, but we'll try to sign in with email.
      // Firebase will handle the error if it's not a valid email format.
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _loginController.text.trim(), // Added .trim() for password
        password: _passwordController.text.trim(),
      );

      // If login is successful, save "Remember Me" and navigate
      _saveRememberMe();
      Get.offAll(() => const MainScreen());
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Login Failed',
        e.message ??
            'An unknown error occurred. Please try again.', // Using TOP for snackbar
        titleText: Text(
          'Login Failed',
          style: AppTextStyle.withColor(
            AppTextStyle.bodySmall,
            isDark ? const Color(0xFF7F1618) : Colors.white,
          ),
        ),
        messageText: Text(
          e.message ?? 'An unknown error occurred. Please try again.',
          style: AppTextStyle.withColor(
            AppTextStyle.bodySmall,
            isDark ? const Color(0xFF7F1618) : Colors.white,
          ),
        ),
        snackPosition: SnackPosition.TOP,
        backgroundColor: isDark ? Colors.white : const Color(0xFF7F1618),
        colorText: isDark ? Colors.white : const Color(0xFF7F1618),
      );
    } finally {
      // Ensure the loading state is turned off, even if login fails
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoggingIn = true;
    });

    try {
      await AutProvider.signinWithGoogle();
      // The mounted check might not be necessary with GetX, but it's good practice.
      if (Get.isSnackbarOpen) {
        await Get.closeCurrentSnackbar();
      }
      if (mounted) {
        // Check if the widget is still in the tree
        Get.offAll(() => const MainScreen());
      }
    } on FirebaseAuthException catch (e) {
      // Don't show an error if the user just cancelled the sign-in prompt.
      if (e.code == 'SIGN_IN_CANCELLED' || e.code == 'sign_in_canceled') return;
      Get.snackbar(
        'Google Sign-In Failed',
        e.message ?? 'An unknown error occurred. Please try again.',
        titleText: Text(
          'Google Sign-In Failed',
          style: AppTextStyle.withColor(AppTextStyle.h3, Colors.white),
        ),
        messageText: Text(
          e.message ?? 'An unknown error occurred. Please try again.',
          style: AppTextStyle.withColor(AppTextStyle.bodyMedium, Colors.white),
        ),
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF7F1618),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Google Sign-In Failed',
        'An unexpected error occurred. Please try again.',
        titleText: Text(
          'Google Sign-In Failed',
          style: AppTextStyle.withColor(AppTextStyle.h3, Colors.white),
        ),
        messageText: Text(
          'An unexpected error occurred. Please try again.',
          style: AppTextStyle.withColor(AppTextStyle.bodyMedium, Colors.white),
        ),
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF7F1618),
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoggingIn = false;
        });
      }
    }
  }

  void _loadRememberMe() {
    final remember = _storage.read('remember_me') ?? false;
    setState(() {
      _rememberMe = remember;
      if (_rememberMe) {
        _loginController.text = _storage.read('login_credential') ?? '';
      }
    });
  }

  void _saveRememberMe() {
    _storage.write('remember_me', _rememberMe);
    if (_rememberMe) {
      _storage.write('login_credential', _loginController.text);
    } else {
      _storage.remove('login_credential');
    }
  }
}
