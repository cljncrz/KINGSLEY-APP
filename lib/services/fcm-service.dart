import 'package:capstone/services/local_notification_service.dart';
import 'package:capstone/view/home/account/geofence_status_screen.dart';
import 'package:capstone/screens/signin_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class MyFCMService {
  final _firebaseMessaging = FirebaseMessaging.instance;

  /// Checks if the user is currently authenticated
  bool _isUserAuthenticated() {
    return FirebaseAuth.instance.currentUser != null;
  }

  /// Handles navigation based on notification type and authentication status
  Future<void> _handleGeofenceNotification(RemoteMessage message) async {
    final isAuthenticated = _isUserAuthenticated();

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
      // Navigate to login/signup screen - delay to ensure snackbar shows
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.to(() => const SigninScreen());
      });
    }
  }

  /// Displays a local notification using the data from a Firebase RemoteMessage.
  Future<void> showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      // 1. Define the platform-specific details (must use the same channel ID)
      const AndroidNotificationDetails
      androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'high_importance_channel', // Must match the ID from Step 3
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        icon:
            'notification_icon', // Use the same icon as defined in AndroidManifest.xml for FCM
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      // 2. Show the notification with payload containing type information
      await flutterLocalNotificationsPlugin.show(
        notification.hashCode, // Unique ID for the notification
        notification.title,
        notification.body,
        platformChannelSpecifics,
        payload: message.data.containsKey('type')
            ? message.data['type']
            : message.data.toString(),
      );
    }
  }

  /// Saves the FCM token to the current user's Firestore document.
  Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null) return;

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
      print("FCM Token saved to Firestore for user ${user.uid}");
    }
  }

  /// Deletes the FCM token from the device and removes it from the
  /// user's Firestore document so this device no longer receives messages.
  Future<void> disableNotifications() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({'fcmToken': FieldValue.delete()}, SetOptions(merge: true));
        }
      }

      // Delete the token locally so FCM stops sending to this instance.
      await _firebaseMessaging.deleteToken();
      print('FCM token deleted and removed from Firestore.');
    } catch (e) {
      print('Error disabling notifications: $e');
    }
  }

  /// Convenience: toggle notifications on/off. Enables by calling
  /// `initNotifications` (which obtains & saves token) or disables by
  /// removing the token.
  Future<void> setNotificationsEnabled(bool enabled) async {
    if (enabled) {
      await initNotifications();
    } else {
      await disableNotifications();
    }
  }

  Future<void> initNotifications() async {
    // Request notification permissions (important for iOS/macOS)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print(
      'User granted notification permission: ${settings.authorizationStatus}',
    );

    // 1. Get the FCM Token
    String? token = await _firebaseMessaging.getToken();
    print("FCM Token inside initNotifications: $token");
    await _saveTokenToFirestore(token);

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToFirestore);

    // **IMPORTANT:** Send this token to your backend server to target this device!

    // 2. Handle messages when the app is in the **Foreground**
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // For Android foreground notifications, you need to use a package
        // like `flutter_local_notifications` to display the notification banner.
        showLocalNotification(
          message,
        ); // Call the function to display the local notification
      }
    });

    // 3. Handle notification click when app is in the **Background/Terminated**
    // When the user taps a notification to open the app.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A message was clicked/opened!');
      final notificationType = message.data['type'] ?? '';

      // Check if it's a geofence notification
      if (notificationType == 'geofence' ||
          notificationType == 'geofencing' ||
          message.notification?.title?.toLowerCase().contains('geofence') ==
              true) {
        _handleGeofenceNotification(message);
      }
    });

    // 4. Handle notification when the app is **Terminated**
    // If the app is opened from a terminated state by tapping a notification.
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App opened from terminated state by a message!');
        final notificationType = message.data['type'] ?? '';

        // Check if it's a geofence notification
        if (notificationType == 'geofence' ||
            notificationType == 'geofencing' ||
            message.notification?.title?.toLowerCase().contains('geofence') ==
                true) {
          _handleGeofenceNotification(message);
        }
      }
    });
  }
}
