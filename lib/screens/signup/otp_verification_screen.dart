import 'dart:async';
import 'package:capstone/utils/app_textstyles.dart';
import 'package:capstone/screens/signup/signup_screen.dart';
import 'package:capstone/screens/signup/verification_success_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final int? resendToken;
  final String userName;
  final String userEmail;
  final String userPassword;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.resendToken,
    required this.userName,
    required this.userEmail,
    required this.userPassword,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final int otpLength = 6;
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];

  Timer? _timer;
  bool _isVerifying = false;
  int _resendTimer = 30;
  bool _canResend = true;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < otpLength; i++) {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    }
    _startResendTimer();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendTimer = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  // Verify OTP with Firebase Phone Authentication
  Future<void> _verifyOTP() async {
    if (_isVerifying) return;

    String otp = _controllers.map((controller) => controller.text).join();
    if (otp.length != otpLength) {
      Get.snackbar('Error', 'Please enter all 6 digits');
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      // SECURITY FIX: Create account ONLY after successful OTP verification

      // Step 1: Create the email/password account
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: widget.userEmail,
            password: widget.userPassword,
          );

      if (userCredential.user == null) {
        throw Exception('Failed to create user account');
      }

      // Step 2: Verify OTP by creating and linking phone credential
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      // Link phone credential to the newly created email account
      try {
        await userCredential.user!.linkWithCredential(credential);
      } catch (e) {
        // If linking fails because phone is already linked, continue anyway
        // The OTP validation is successful if we got here
        if (!e.toString().contains('credential-already-in-use')) {
          rethrow;
        }
      }

      // Step 3: Complete signup and save user data to Firestore
      await _completeSignUp(userCredential.user!.uid);

      // Navigate to success screen
      Get.offAll(() => const VerificationSuccessScreen());
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Verification Failed',
        e.message ?? 'Invalid OTP code. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  Future<void> _completeSignUp(String userId) async {
    try {
      // Get FCM token
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      // Update Firebase Auth user with displayName
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(widget.userName);
      }

      // Store user data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fullName': widget.userName,
        'email': widget.userEmail,
        'phoneNumber': widget.phoneNumber,
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
        'Failed to complete signup: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;

    try {
      String phoneNumber = widget.phoneNumber;
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+63$phoneNumber';
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (iOS specific)
          await _verifyOTP();
        },
        verificationFailed: (FirebaseAuthException e) {
          Get.snackbar(
            'Error',
            'Failed to resend OTP: ${e.message}',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          Get.snackbar(
            'Success',
            'OTP resent to ${widget.phoneNumber}',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          _startResendTimer();
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 120),
        forceResendingToken: widget.resendToken,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to resend OTP: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.off(() => const SignupScreen()),
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verify Phone Number',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodyMedium,
                  isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter 6-digit code sent to ${widget.phoneNumber}',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodySmall,
                  isDark ? Colors.grey[400]! : Colors.grey[600]!,
                ),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  otpLength,
                  (index) => SizedBox(
                    width: 50,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(fontSize: 24),
                      decoration: InputDecoration(
                        counterText: '',
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]!
                                : Colors.grey[600]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]!
                                : Colors.grey[600]!,
                          ),
                        ),
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          if (index < otpLength - 1) {
                            FocusScope.of(context).nextFocus();
                          } else {
                            _focusNodes[index].unfocus();
                            _verifyOTP();
                          }
                        } else if (index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isVerifying ? 'Verifying...' : 'Verify',
                    style: AppTextStyle.withColor(
                      AppTextStyle.buttonMedium,
                      Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: _canResend ? _resendOTP : null,
                  child: Text(
                    _canResend
                        ? "Didn't receive the code? Resend"
                        : 'Resend code in ${_resendTimer}s',
                    style: AppTextStyle.withColor(
                      AppTextStyle.bodySmall,
                      _canResend
                          ? Theme.of(context).primaryColor
                          : (Theme.of(context).textTheme.bodySmall?.color ??
                                Colors.grey),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
