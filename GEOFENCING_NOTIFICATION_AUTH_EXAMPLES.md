# Geofencing Notification Auth - Implementation Examples

## Complete User Flows

### User Flow 1: Logged-In User Receives Geofence Notification

```
Timeline:
---------
1. [14:30] User is logged in to app
   ├─ Auth state: FirebaseAuth.instance.currentUser = User object
   └─ App state: Any state (foreground/background/terminated)

2. [14:35] Geofence detected by backend
   ├─ Server sends FCM notification
   └─ Payload includes: type: "geofence"

3. [14:35] Device receives notification
   ├─ Local notification displayed
   └─ Notification banner/alert shown

4. [14:36] User taps notification
   ├─ FCM onMessageOpenedApp triggered
   ├─ Local notification tap handler triggered
   └─ Both check: _isUserAuthenticated()

5. [14:36] Authentication check PASSES ✓
   ├─ currentUser != null
   ├─ _handleGeofenceNotification() executes
   └─ Get.toNamed('/geofence-status')

6. [14:36] Geofence Status Screen opens
   └─ User sees: Nearby locations, distance info, monitoring status

Result: ✅ User successfully navigates to geofencing features
```

### User Flow 2: Non-Logged-In User Receives Geofence Notification

```
Timeline:
---------
1. [15:00] User has installed app but NOT logged in
   ├─ Auth state: FirebaseAuth.instance.currentUser = null
   └─ App state: Terminated or background

2. [15:05] Geofence detected by backend
   ├─ Server sends FCM notification to all devices with app
   └─ Payload includes: type: "geofence"

3. [15:05] Device receives notification
   ├─ Local notification system shows alert
   ├─ Notification center displays notification
   └─ No navigation happens until tap

4. [15:07] User taps notification from notification center
   ├─ App relaunches (if terminated)
   ├─ FCM getInitialMessage() called
   ├─ Local notification tap handler called
   └─ Both check: _isUserAuthenticated()

5. [15:07] Authentication check FAILS ✗
   ├─ currentUser == null
   ├─ _handleGeofenceNotification() executes
   └─ Get.snackbar() displays message

6. [15:07] Snackbar shown: "Login Required"
   ├─ Message: "Please login or sign up to view geofencing information."
   ├─ Duration: 4 seconds
   └─ Position: Top of screen

7. [15:07] Get.toNamed('/login') executed
   ├─ App navigates to login/signup screen
   ├─ User sees login form
   └─ User can signup or login

8. [15:15] User successfully logs in
   ├─ Auth state updates: currentUser = User object
   ├─ User completes login flow
   └─ User returns to app

9. [15:20] User receives another geofence notification
   ├─ User taps notification
   ├─ Auth check PASSES ✓
   └─ User navigates to Geofence Status Screen

Result: ✅ User prompted to login, then can access geofencing after authentication
```

### User Flow 3: User Logs Out While App Running

```
Timeline:
---------
1. [16:00] User is logged in and app is in foreground
   ├─ Auth state: currentUser = User object
   └─ User taps logout button

2. [16:01] Logout process completes
   ├─ Firebase clears auth token
   ├─ Auth state: currentUser = null
   └─ App returns to splash/login screen

3. [16:02] Geofence notification arrives
   ├─ Device shows notification
   ├─ User still in login/splash screen
   └─ Notification sits in notification center

4. [16:03] User taps notification
   ├─ FCM listener triggered
   ├─ _isUserAuthenticated() checks
   ├─ currentUser == null (user logged out)
   └─ _handleGeofenceNotification() routes to login

5. [16:03] Snackbar + Navigation
   ├─ Snackbar: "Login Required..."
   ├─ Navigation: Go to '/login'
   └─ User already on login screen

Result: ✅ Appropriate handling - user prompted to login again
```

## Code Implementation Details

### Detection Logic

The implementation detects geofence notifications in THREE ways:

```dart
// In fcm-service.dart - onMessageOpenedApp listener
final notificationType = message.data['type'] ?? '';

if (notificationType == 'geofence' || 
    notificationType == 'geofencing' ||
    message.notification?.title?.toLowerCase().contains('geofence') == true) {
  _handleGeofenceNotification(message);
}
```

**Detection Methods:**
1. **Explicit Type (Recommended)**
   ```json
   { "data": { "type": "geofence" } }
   ```

2. **Alternative Type**
   ```json
   { "data": { "type": "geofencing" } }
   ```

3. **Keyword in Title (Fallback)**
   ```json
   { 
     "notification": { 
       "title": "Near Geofence - Special Offer!" 
     }
   }
   ```

### Authentication Check Implementation

```dart
/// Simple but effective authentication check
bool _isUserAuthenticated() {
  return FirebaseAuth.instance.currentUser != null;
}

// Usage
if (_isUserAuthenticated()) {
  // User is logged in
  Get.toNamed('/geofence-status');
} else {
  // User is not logged in
  Get.snackbar(...);
  Get.toNamed('/login');
}
```

**Why this works:**
- `FirebaseAuth.instance.currentUser` is updated immediately on login/logout
- No network calls needed (uses cached state)
- Works in all app states (foreground, background, terminated)
- No async delays

### Navigation Implementation

```dart
// For authenticated users
Get.toNamed('/geofence-status');

// For unauthenticated users
Get.snackbar(
  'Login Required',
  'Please login or sign up to view geofencing information.',
  snackPosition: SnackPosition.TOP,
  duration: const Duration(seconds: 4),
);
Get.toNamed('/login');
```

**Important:** Both `/geofence-status` and `/login` routes must be defined in your app.

## Backend Integration Examples

### Firebase Cloud Functions Example

```javascript
// Send geofence notification to specific user
exports.notifyGeofenceEntry = functions.firestore
  .document('locations/{locationId}/geofences/{userId}')
  .onCreate(async (snap, context) => {
    const userId = context.params.userId;
    const locationId = context.params.locationId;
    
    // Get user's FCM token from Firestore
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();
    
    const fcmToken = userDoc.data().fcmToken;
    
    if (!fcmToken) return;
    
    // Send notification with geofence type
    await admin.messaging().send({
      notification: {
        title: "You're near a Kingsley Carwash!",
        body: "Check out our special offers"
      },
      data: {
        type: "geofence",
        locationId: locationId,
        action: "open_geofence_status"
      },
      token: fcmToken
    });
  });
```

### REST API Example

```bash
# Send geofence notification via HTTP
curl -X POST https://fcm.googleapis.com/v1/projects/YOUR_PROJECT/messages:send \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "notification": {
        "title": "You are near a Kingsley Carwash!",
        "body": "Tap to view special offers and services"
      },
      "data": {
        "type": "geofence",
        "locationId": "loc_123",
        "distance": "450m"
      },
      "token": "USER_FCM_TOKEN"
    }
  }'
```

### Python Example

```python
from firebase_admin import messaging

# Send geofence notification
message = messaging.Message(
    notification=messaging.Notification(
        title="You're near a Kingsley Carwash!",
        body="Special offers available now"
    ),
    data={
        "type": "geofence",
        "locationId": "loc_123",
        "offerCode": "NEARBY15"
    },
    token="user_fcm_token"
)

response = messaging.send(message)
print(f"Notification sent: {response}")
```

## Testing Checklist

### Unit Test Example

```dart
// test/services/fcm_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:capstone/services/fcm_service.dart';

void main() {
  group('FCM Geofence Notification Tests', () {
    test('_isUserAuthenticated returns true when user is logged in', () {
      // Mock Firebase to return a user
      // Assert _isUserAuthenticated() returns true
    });

    test('_isUserAuthenticated returns false when user is not logged in', () {
      // Mock Firebase to return null
      // Assert _isUserAuthenticated() returns false
    });

    test('Geofence notification routes logged-in user correctly', () {
      // Mock authenticated user
      // Mock Get.toNamed
      // Call _handleGeofenceNotification
      // Assert Get.toNamed('/geofence-status') was called
    });

    test('Geofence notification shows snackbar for unauthenticated user', () {
      // Mock null user
      // Mock Get.snackbar and Get.toNamed
      // Call _handleGeofenceNotification
      // Assert Get.snackbar was called
      // Assert Get.toNamed('/login') was called
    });
  });
}
```

### Integration Test Example

```dart
// test/integration_test/geofence_notification_integration_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:capstone/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Geofence Notification Integration Tests', () {
    testWidgets('Logged-in user navigates to geofence status', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login user
      // Simulate notification tap
      // Verify navigation to geofence status screen
    });

    testWidgets('Non-logged-in user sees login prompt', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Simulate notification tap without login
      // Verify snackbar appears
      // Verify navigation to login screen
    });
  });
}
```

## Troubleshooting Guide

### Problem: Notification tapped but nothing happens

**Diagnosis:**
```dart
// Add debug logging to fcm-service.dart
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  print('📱 Notification tapped!');
  print('Data: ${message.data}');
  print('Type: ${message.data['type']}');
  print('Title: ${message.notification?.title}');
  // ... rest of handler
});
```

**Solutions:**
1. Check if route names are correct
2. Verify Get.toNamed() is being called
3. Ensure GetMaterialApp is used in main.dart

### Problem: Auth check not working

**Diagnosis:**
```dart
// Test auth check directly
bool isAuth = _isUserAuthenticated();
print('Is authenticated: $isAuth');
print('Current user: ${FirebaseAuth.instance.currentUser}');
```

**Solutions:**
1. Verify Firebase is initialized before notification handling
2. Check if user is actually logged in
3. Ensure FirebaseAuth is imported correctly

### Problem: Wrong route opens

**Diagnosis:**
```dart
// Log which branch is being taken
if (isAuthenticated) {
  print('✅ User authenticated - routing to geofence');
  Get.toNamed('/geofence-status');
} else {
  print('❌ User not authenticated - routing to login');
  Get.toNamed('/login');
}
```

**Solutions:**
1. Verify route names match exactly in your app's GetPage definitions
2. Check route configuration in main.dart
3. Use `Get.log()` to debug GetX routing

## Summary

The implementation provides:
- ✅ Automatic detection of geofence notifications
- ✅ Real-time authentication checking
- ✅ Proper routing based on login status
- ✅ User-friendly messaging
- ✅ Handling of all app states
- ✅ Fallback detection methods

All integration points are in place and ready for testing.
