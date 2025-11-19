import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

// 1. Create a global instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

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
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel', // Must match the channel ID created above
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
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
