import 'package:capstone/controllers/auth_controller.dart';
import 'package:capstone/services/local_notification_service.dart';
import 'package:capstone/controllers/chat_controller.dart';
import 'package:capstone/services/fcm-service.dart';
import 'package:capstone/services/geofencing_service.dart';
import 'package:capstone/controllers/navigation_controller.dart';
import 'package:capstone/controllers/product_controller.dart';
import 'package:capstone/controllers/cart_controller.dart';
import 'package:capstone/controllers/booking_controller.dart';
import 'package:capstone/controllers/feedback_controller.dart';
import 'package:capstone/controllers/notification_controller.dart';
import 'package:capstone/controllers/user_controller.dart';
import 'package:capstone/controllers/damage_report_controller.dart';
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
import 'package:firebase_messaging/firebase_messaging.dart';

// Handler for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
  // You can process the message here, e.g., save to local storage,
  // or trigger a local notification.
}

Future<void> main() async {
  try {
    print("--- Initializing App Services ---");

    /// Widgets Binding
    WidgetsFlutterBinding.ensureInitialized();

    /// -- GetX Local Storage
    await GetStorage.init();

    // Initialize all critical services.
    /// -- Firebase Initialization --
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    /// -- Load environment variables
    await dotenv.load(fileName: "assets/.env");

    // Get the reCAPTCHA site key from environment variables.
    final recaptchaSiteKey = dotenv.env['RECAPTCHA_SITE_KEY'];
    if (recaptchaSiteKey == null || recaptchaSiteKey.isEmpty) {
      debugPrint(
        'WARNING: RECAPTCHA_SITE_KEY not found in .env file. Firebase App Check for web will fail.',
      );
    }

    // Activate Firebase App Check. This MUST be done before other Firebase services are used.
    try {
      await FirebaseAppCheck.instance.activate(
        // For Android: Use PlayIntegrity in production, debug in development
        androidProvider: kDebugMode
            ? AndroidProvider.debug
            : AndroidProvider.playIntegrity,
        // For iOS: Use AppAttest in production, debug in development
        appleProvider: kDebugMode
            ? AppleProvider.debug
            : AppleProvider.appAttest,
      );
      debugPrint('✅ Firebase App Check activated successfully.');
      debugPrint(
        '${kDebugMode ? '🔧 DEBUG MODE' : '🔒 PRODUCTION MODE'} - App Check active',
      );
    } catch (e) {
      debugPrint('❌ Error activating Firebase App Check: $e');
      // Continue even if App Check fails - don't block app startup
    }

    // Set the background messaging handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize local and push notifications AFTER Firebase is ready.
    await initializeLocalNotifications();
    await createNotificationChannel();
    await MyFCMService().initNotifications();
  } catch (e) {
    debugPrint('Failed to initialize app services: $e');
    // Consider showing an error screen to the user here if initialization fails.
  }

  // Add this block to print the App Check debug token in debug mode.
  if (kDebugMode) {
    FirebaseAppCheck.instance.onTokenChange.listen((token) {
      debugPrint('App Check debug token: $token');
    });
  }

  // Initialize controllers using GetX dependency injection.
  Get.put(ThemeController());
  Get.put(AuthController());
  Get.put(CartController());
  Get.put(NavigationController());
  Get.put(BookingController());
  Get.put(ProductController());
  Get.put(FeedbackController());
  Get.put(NotificationController());
  Get.put(UserController());
  Get.put(DamageReportController());
  Get.put(ChatController());

  // Initialize Geofencing Service for background location monitoring
  Get.put(GeofencingService());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.light,
      darkTheme: AppThemes.dark,
      themeMode: themeController.theme,
      defaultTransition: Transition.fade,
      home: SplashScreen(),
    );
  }
}
