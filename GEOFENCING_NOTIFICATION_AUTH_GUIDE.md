# Geofencing Notification Authentication Guide

## Overview
This guide explains how geofencing notifications now handle authentication states. When a user receives a geofencing notification, the app will check if they have an account. If they're logged in, they navigate to the Geofence Status Screen. If not, they're directed to login/signup.

## Implementation Summary

### 1. **Modified Files**

#### `lib/services/fcm-service.dart`
- Added `_isUserAuthenticated()` method to check if user is logged in
- Added `_handleGeofenceNotification()` method to handle geofence notification routing
- Updated `onMessageOpenedApp` listener to detect geofence notifications and route accordingly
- Updated `getInitialMessage()` handler for terminated app state
- Notifications include type information in payload

#### `lib/services/local_notification_service.dart`
- Added `_handleLocalNotificationTap()` function to handle local notification taps
- Checks authentication status when geofence notification is tapped
- Routes authenticated users to `/geofence-status` screen
- Routes unauthenticated users to `/login` screen with informational snackbar
- Updated notification initialization to use the new tap handler

### 2. **How It Works**

#### Scenario 1: User Has Account (Logged In)
```
Geofence Notification → User Taps → Authentication Check → ✓ Authenticated
                                                                  ↓
                                          Navigate to Geofence Status Screen
```

#### Scenario 2: User No Account (Not Logged In)
```
Geofence Notification → User Taps → Authentication Check → ✗ Not Authenticated
                                                                  ↓
                                    Show Snackbar + Navigate to Login/Signup
```

### 3. **Notification Payload Requirements**

When sending geofencing notifications from your backend, include the `type` field:

```json
{
  "notification": {
    "title": "You're near a Kingsley Carwash!",
    "body": "Get special offers at your nearby location"
  },
  "data": {
    "type": "geofence"
  }
}
```

Or use keyword detection in the title:
- Title contains "geofence" or "geofencing" (case-insensitive)

### 4. **Navigation Routes**

**Important**: Ensure these routes are defined in your main app navigation:
- `/geofence-status` - Geofence Status Screen (for authenticated users)
- `/login` - Login/Signup screen (for unauthenticated users)

If your routes are named differently, update them in:
- `lib/services/fcm-service.dart` - Line 24 and 33
- `lib/services/local_notification_service.dart` - Line 28 and 35

### 5. **User Experience Flow**

#### For Logged-In Users
1. User receives geofencing notification
2. User taps the notification
3. Authentication verified ✓
4. App navigates directly to Geofence Status Screen
5. User can see nearby locations and geofencing info

#### For Non-Logged-In Users
1. User receives geofencing notification
2. User taps the notification
3. Authentication check fails ✗
4. Snackbar appears: "Login Required - Please login or sign up to view geofencing information."
5. App navigates to Login/Signup screen
6. After successful login, user can tap notifications again to access geofencing features

### 6. **Testing the Implementation**

#### Test Case 1: Logged-In User
```
1. Login to the app
2. Send a test geofence notification with type: "geofence"
3. Tap the notification
4. ✓ Should navigate to Geofence Status Screen
```

#### Test Case 2: Non-Logged-In User
```
1. Logout or clear app data
2. Send a test geofence notification with type: "geofence"
3. Tap the notification
4. ✓ Should see "Login Required" snackbar
5. ✓ Should navigate to login screen
```

#### Test Case 3: App in Foreground
```
1. Keep app open in foreground
2. Receive a geofence notification
3. Tap the notification banner
4. ✓ Should handle routing based on auth status
```

#### Test Case 4: App Terminated
```
1. Force close the app (or terminate it)
2. Receive a geofence notification
3. Tap the notification from notification center
4. ✓ Should reopen app and route based on auth status
```

### 7. **Key Methods Explained**

#### `_isUserAuthenticated()` in FCM Service
```dart
bool _isUserAuthenticated() {
  return FirebaseAuth.instance.currentUser != null;
}
```
Returns true if a user is logged in, false otherwise.

#### `_handleGeofenceNotification()` in FCM Service
```dart
Future<void> _handleGeofenceNotification(RemoteMessage message) async {
  final isAuthenticated = _isUserAuthenticated();
  
  if (isAuthenticated) {
    Get.toNamed('/geofence-status');
  } else {
    Get.snackbar(...);
    Get.toNamed('/login');
  }
}
```
Routes the user based on their authentication status.

#### `_handleLocalNotificationTap()` in Local Notification Service
```dart
Future<void> _handleLocalNotificationTap(String? payload) async {
  if (payload?.toLowerCase().contains('geofence') == true) {
    // Check auth and route accordingly
  }
}
```
Handles taps on local notifications with auth check.

### 8. **Integration Checklist**

- [ ] Verify `/geofence-status` route exists and is properly configured
- [ ] Verify `/login` route exists and handles new users (signup)
- [ ] Test notification sending from backend with `type: "geofence"`
- [ ] Test logged-in user notification flow
- [ ] Test non-logged-in user notification flow
- [ ] Test app in foreground, background, and terminated states
- [ ] Verify Get routes are using GetMaterialApp
- [ ] Test on both Android and iOS devices

### 9. **Troubleshooting**

**Issue**: Notification tap does nothing
- **Solution**: Verify route names match exactly in your app's route configuration

**Issue**: User not redirected to login
- **Solution**: Ensure `/login` route is properly defined and Get.toNamed() can find it

**Issue**: Snackbar not appearing
- **Solution**: Ensure GetMaterialApp is used in main.dart and Get is initialized

**Issue**: Navigation happening but screen not displaying
- **Solution**: Check that geofence_status_screen.dart is properly imported and route is correct

### 10. **Future Enhancements**

Consider implementing:
- Deep linking for direct notification handling
- Custom message handling for different notification types
- Persistent login state recovery after notification tap
- Analytics tracking for notification interactions
- Different messaging for different geofence events (entry vs exit)

---

## Code Examples

### Sending Geofence Notification from Backend

```javascript
// Firebase Cloud Messaging example
admin.messaging().send({
  notification: {
    title: "You're near a Kingsley Carwash!",
    body: "Get special offers at your nearby location"
  },
  data: {
    type: "geofence",
    locationId: "location_123",
    distance: "500m"
  },
  token: deviceFCMToken
});
```

### Customizing the Snackbar Message

In `fcm-service.dart`, modify the snackbar text:

```dart
Get.snackbar(
  'Account Required',
  'Sign up or log in to receive geofencing alerts and special offers!',
  snackPosition: SnackPosition.TOP,
  duration: const Duration(seconds: 5),
  backgroundColor: Colors.orange,
  colorText: Colors.white,
);
```

---

## Notes

- The implementation uses Firebase Authentication to check login status
- Authentication check is performed in real-time when notification is tapped
- No network call is required - uses cached auth state
- Works with both FCM (background) and local notifications (foreground)
- Compatible with app states: foreground, background, and terminated
