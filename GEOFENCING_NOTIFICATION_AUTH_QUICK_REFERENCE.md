# Geofencing Notification Auth - Quick Reference

## What Changed?

Geofencing notifications now check if the user is logged in:
- **Logged In** → Opens Geofence Status Screen
- **Not Logged In** → Shows login prompt & navigates to login screen

## Files Modified

1. **`lib/services/fcm-service.dart`**
   - Added authentication check in `_handleGeofenceNotification()`
   - Detects geofence notifications and routes accordingly

2. **`lib/services/local_notification_service.dart`**
   - Added `_handleLocalNotificationTap()` function
   - Checks auth when notification is tapped

## Key Features

✅ Detects geofence notifications by:
- `data.type == "geofence"` or `"geofencing"`
- Title containing "geofence" (case-insensitive)

✅ Handles all app states:
- Foreground (user sees notification banner)
- Background (user taps notification)
- Terminated (app relaunches on notification tap)

✅ User-friendly:
- Clear message: "Login Required - Please login or sign up..."
- Automatic navigation to login screen
- Snackbar notification appears for 4 seconds

## Testing Steps

### Logged-In User
1. Login to app
2. Send test notification with `type: "geofence"`
3. Tap notification
4. ✓ Opens Geofence Status Screen

### Not Logged-In User
1. Logout/clear data
2. Send test notification with `type: "geofence"`
3. Tap notification
4. ✓ See "Login Required" snackbar
5. ✓ Navigate to login screen

## Backend Setup

Send notifications with this payload:

```json
{
  "notification": {
    "title": "You're near a Kingsley Carwash!",
    "body": "Check out special offers"
  },
  "data": {
    "type": "geofence"
  }
}
```

## Route Configuration

Make sure these routes exist in your app:
- `/geofence-status` → Geofence Status Screen
- `/login` → Login/Signup Screen

Update route names in service files if different.

## Detection Methods

The app detects geofence notifications using:

```dart
// Method 1: Check data type
message.data['type'] == 'geofence'

// Method 2: Check title
message.notification?.title?.toLowerCase().contains('geofence')

// Both work together with OR logic
```

## Common Issues

| Issue | Solution |
|-------|----------|
| Notification doesn't navigate | Check `/geofence-status` and `/login` routes exist |
| Snackbar not showing | Ensure GetMaterialApp is used in main.dart |
| Wrong screen opens | Verify route names match exactly |
| Auth check fails | Ensure Firebase is initialized before notification |

## Flow Diagram

```
┌─────────────────────────┐
│ Geofence Notification   │
│ Sent to Device          │
└────────────┬────────────┘
             │
             ↓
    ┌────────────────┐
    │ User Taps      │
    │ Notification   │
    └────────┬───────┘
             │
             ↓
    ┌────────────────────┐
    │ Check Auth Status  │
    └────────┬───────────┘
             │
      ┌──────┴──────┐
      │             │
      ↓             ↓
   Logged       Not Logged
     In           In
      │             │
      ↓             ↓
  Geofence    Show "Login
  Status      Required"
  Screen      Snackbar +
              Go to Login
```

## Code Snippets

### Check Authentication
```dart
bool isLoggedIn = FirebaseAuth.instance.currentUser != null;
```

### Navigate to Geofence
```dart
Get.toNamed('/geofence-status');
```

### Navigate to Login
```dart
Get.toNamed('/login');
```

### Show Info Snackbar
```dart
Get.snackbar(
  'Login Required',
  'Please login or sign up to view geofencing information.',
  snackPosition: SnackPosition.TOP,
);
```

## Implementation Locations

| Feature | File | Method/Line |
|---------|------|------------|
| Auth Check | `fcm-service.dart` | `_isUserAuthenticated()` |
| Geofence Handling | `fcm-service.dart` | `_handleGeofenceNotification()` |
| Notification Tap | `local_notification_service.dart` | `_handleLocalNotificationTap()` |
| Background Handler | `fcm-service.dart` | `onMessageOpenedApp.listen()` |
| Terminated Handler | `fcm-service.dart` | `getInitialMessage()` |

## What Happens Next?

After user logs in:
- User is redirected to login screen
- After successful login, auth state updates
- User can tap future geofence notifications to access Geofence Status Screen
- Previous behavior continues normally

---

For detailed information, see `GEOFENCING_NOTIFICATION_AUTH_GUIDE.md`
