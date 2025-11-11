import 'package:capstone/controllers/auth_controller.dart';
import 'package:capstone/controllers/navigation_controller.dart';
import 'package:capstone/controllers/product_controller.dart';
import 'package:capstone/controllers/cart_controller.dart';
import 'package:capstone/controllers/booking_controller.dart';
import 'package:capstone/controllers/notification_controller.dart';
import 'package:capstone/controllers/user_controller.dart';
import 'package:capstone/screens/splash_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone/controllers/theme_controller.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:capstone/utils/app_themes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  /// Widgets Binding
  WidgetsFlutterBinding.ensureInitialized();

  /// -- GetX Local Storage
  await GetStorage.init();

  /// -- Load environment variables
  await dotenv.load(fileName: "assets/.env");

  /// -- Firebase Initialization --
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Get the reCAPTCHA site key from environment variables.
  final recaptchaSiteKey = dotenv.env['RECAPTCHA_SITE_KEY'];
  if (recaptchaSiteKey == null || recaptchaSiteKey.isEmpty) {
    debugPrint(
      'WARNING: RECAPTCHA_SITE_KEY not found in .env file. Firebase App Check for web will fail.',
    );
  }

  // Initialize Firebase App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
    webProvider: ReCaptchaV3Provider(
      recaptchaSiteKey ?? '',
    ), // Use an empty string if null to avoid using a bad placeholder
  );

  Get.put(AuthController());
  Get.put(ThemeController());
  Get.put(CartController());
  Get.put(NavigationController());
  Get.put(BookingController());
  Get.put(ProductController());
  Get.put(NotificationController());
  Get.put(UserController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kingsley Carwash',
      theme: AppThemes.light,
      darkTheme: AppThemes.dark,
      themeMode: themeController.theme,
      defaultTransition: Transition.fade,
      home: SplashScreen(),
    );
  }
}
