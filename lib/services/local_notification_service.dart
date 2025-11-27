import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:capstone/view/home/account/geofence_status_screen.dart';
import 'package:capstone/screens/signin_screen.dart';

// 1. Create a global instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Handles navigation when a local notification is tapped
Future<void> _handleLocalNotificationTap(String? payload) async {
  if (payload == null || payload.isEmpty) return;

  debugPrint('Local notification tapped with payload: $payload');

  // Check if it's a geofence notification
  if (payload == 'geofence' ||
      payload == 'geofencing' ||
      payload.toLowerCase().contains('geofence')) {
    final isAuthenticated = FirebaseAuth.instance.currentUser != null;

    if (isAuthenticated) {
      // User is logged in - navigate to Geofence Status Screen
      Get.to(() => const GeofenceStatusScreen());
    } else {
      // User is not logged in - show snackbar and navigate to login
      Get.snackbar(
        'Login Required',
        'Please login or sign up to view geofencing information.',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
      );
      // Delay navigation to ensure snackbar shows first
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.to(() => const SigninScreen());
      });
    }
  }
}

/// Initializes the local notifications plugin with platform-specific settings.
Future<void> initializeLocalNotifications() async {
  // 2. Android Initialization Settings
  // 'notification_icon' must refer to a drawable resource (e.g., in android/app/src/main/res/drawable)
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('notification_icon');

  // 3. iOS/macOS Initialization Settings
  // Request permissions for iOS/macOS
  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

  // 4. Combined Initialization Object
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
    macOS: initializationSettingsDarwin, // macOS uses similar settings to iOS
  );

  // 5. Initialize the plugin
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    // Define how to handle when a notification is tapped
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      // Handle navigation or action when the notification is tapped
      if (response.payload != null) {
        debugPrint('Notification payload tapped: ${response.payload}');
        await _handleLocalNotificationTap(response.payload);
      }
    },
  );
}

/// Creates a notification channel for Android 8.0 (API level 26) and higher.
/// This must be called to ensure notifications are displayed on newer Android versions.
Future<void> createNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // ID: Must match the channel ID used when showing the notification
    'High Importance Notifications', // Name for users
    description:
        'This channel is used for important notifications.', // Description for users
    importance: Importance.max, // Set to max for higher visibility
    enableVibration: true,
    enableLights: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);
}

/// LocalNotificationService class for managing local notifications
class LocalNotificationService {
  static LocalNotificationService? _instance;

  static LocalNotificationService get instance {
    _instance ??= LocalNotificationService._();
    return _instance!;
  }

  LocalNotificationService._();

  /// Show a local notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel', // Must match the channel ID created above
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          // Ensure notification shows on lock screen
          visibility: NotificationVisibility.public,
          // Make notification persistent until user interacts with it
          autoCancel: false,
          // Enable vibration on lock screen
          enableVibration: true,
          // Enable sound
          playSound: true,
          // Set notification color
          color: Color.fromARGB(255, 33, 150, 243),
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000, // Unique ID
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }
}
