# Background Geofencing Setup Guide

## Overview
This app now supports **background geofencing** that works even when the app is closed or in the background. The geofencing service automatically detects when users enter or exit the car wash location area and sends notifications.

## How It Works

### Key Features
- ✅ Works when app is **closed**
- ✅ Works when app is in **recent tabs/background**
- ✅ Automatic notifications on entry/exit
- ✅ Battery optimized monitoring
- ✅ 500m radius geofence around car wash
- ✅ Persistent after device reboot (requires re-permission)

### Technical Implementation
The geofencing uses:
- **Geolocator package**: For continuous location monitoring
- **Background location permission**: Required for Android 10+
- **Location stream**: Monitors position every 50 meters
- **Periodic checks**: Every 5 minutes for reliability
- **Local notifications**: Triggered on geofence events

## Configuration

### 1. Set Your Car Wash Location

Edit `lib/services/geofencing_service.dart` and update these coordinates:

```dart
// Car wash location (replace with your actual coordinates)
static const double carwashLatitude = 14.5995;  // Your latitude
static const double carwashLongitude = 120.9842; // Your longitude
```

**How to get coordinates:**
- Open Google Maps
- Right-click on your car wash location
- Click the coordinates (they'll be copied)
- Paste into the code above

### 2. Adjust Geofence Radius (Optional)

Default is 500 meters. To change:

```dart
static const double geofenceRadius = 500.0; // Change to your preferred radius in meters
```

### 3. Customize Monitoring Settings (Optional)

In `geofencing_service.dart`, adjust:

```dart
const LocationSettings locationSettings = LocationSettings(
  accuracy: LocationAccuracy.medium,  // high, medium, low
  distanceFilter: 50,                 // Update every X meters
  timeLimit: Duration(minutes: 5),    // Timeout period
);
```

## Android Permissions

### Required Permissions (Already Added)
The following permissions are now in your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

### User Permission Flow
1. **First request**: "While using the app" permission
2. **Second request**: "Allow all the time" permission (for background)
3. User **must select "Allow all the time"** for geofencing to work when app is closed

## Testing

### Test Geofencing
1. Run the app and grant location permissions
2. Navigate to **Geofence Status Screen** (you'll need to add this to your navigation)
3. Tap "Start Monitoring"
4. **Simulate location** in Android Studio:
   - Open Android Studio
   - Go to **Extended Controls** (... button)
   - Select **Location**
   - Enter coordinates near/far from car wash
   - Watch notifications appear

### Test Commands
```bash
# Grant background location permission manually
adb shell pm grant com.yourpackage android.permission.ACCESS_BACKGROUND_LOCATION

# Check current location permissions
adb shell dumpsys package com.yourpackage | grep permission
```

## Usage in Your App

### Access Geofencing Service
```dart
import 'package:capstone/services/geofencing_service.dart';

// Get instance
final geofencing = GeofencingService.instance;

// Check if user is near car wash
bool isNear = await geofencing.isUserNearCarwash();

// Get distance to car wash
double? distance = await geofencing.getDistanceToCarwash();

// Check monitoring status
bool isMonitoring = geofencing.isMonitoring.value;

// Check if inside geofence
bool isInside = geofencing.isInsideGeofence.value;
```

### Add Geofence Status to Navigation
Add this to your navigation menu:

```dart
ListTile(
  leading: Icon(Icons.location_searching),
  title: Text('Geofence Status'),
  onTap: () => Get.to(() => GeofenceStatusScreen()),
),
```

## Customization

### Modify Entry/Exit Actions

In `geofencing_service.dart`, customize these methods:

```dart
void _onGeofenceEnter(double distance) {
  // Your custom actions when user arrives
  // Examples:
  // - Update Firestore user status
  // - Notify staff via Firebase
  // - Start preparation timer
  // - Send push notification to admin
}

void _onGeofenceExit(double distance) {
  // Your custom actions when user leaves
  // Examples:
  // - Update user status
  // - Trigger feedback request
  // - Log visit duration
}
```

### Integrate with Firebase

Example: Update user status in Firestore:

```dart
void _onGeofenceEnter(double distance) {
  // Show notification
  LocalNotificationService.instance.showNotification(...);
  
  // Update Firestore
  FirebaseFirestore.instance
    .collection('users')
    .doc(currentUserId)
    .update({
      'isAtCarwash': true,
      'arrivalTime': FieldValue.serverTimestamp(),
      'distance': distance,
    });
  
  // Notify staff
  FirebaseMessaging.instance.sendMessage(
    to: '/topics/staff',
    data: {'userArrived': currentUserId},
  );
}
```

## Battery Optimization

### User Settings
For reliable background operation, users should:
1. **Disable battery optimization** for your app:
   - Settings → Apps → Your App → Battery → Unrestricted
2. **Grant "Allow all the time"** location permission
3. **Disable "Battery Saver"** mode (optional)

### Code Optimization
Already implemented:
- ✅ `distanceFilter: 50m` - Updates only when moved 50+ meters
- ✅ `LocationAccuracy.medium` - Balance accuracy vs battery
- ✅ 5-minute periodic checks instead of continuous
- ✅ Automatic cleanup when not needed

## Important Notes

### Android 10+ Requirements
- **Must request** `ACCESS_BACKGROUND_LOCATION` separately
- **Must explain** why you need background location (already added in UI)
- User **must select** "Allow all the time" option

### Android 12+ Restrictions
- More aggressive background limits
- May require **foreground service** with notification for guaranteed operation
- Consider implementing foreground service if issues occur

### Limitations
- Maximum **100 geofences** per app (you're using 1)
- Geofences **cleared on reboot** (need to re-register)
- **Battery saver mode** may limit functionality
- **Play Services required** (handled by Geolocator)

## Troubleshooting

### Geofencing Not Working
1. ✅ Check location services enabled
2. ✅ Verify "Allow all the time" permission granted
3. ✅ Disable battery optimization for app
4. ✅ Ensure coordinates are correct
5. ✅ Test with location simulation first

### No Notifications When App Closed
1. Check background location permission
2. Disable battery optimization
3. Check notification permissions
4. Test with app in background first, then closed

### High Battery Drain
1. Increase `distanceFilter` value (e.g., 100m)
2. Reduce check frequency (e.g., 10 minutes)
3. Use `LocationAccuracy.low` instead of medium
4. Consider larger geofence radius

## Testing Checklist

- [ ] Grant "While using" location permission
- [ ] Grant "Allow all the time" location permission
- [ ] Update car wash coordinates in code
- [ ] Test with location simulation
- [ ] Test with app in foreground
- [ ] Test with app in background
- [ ] Test with app completely closed
- [ ] Test entry notification
- [ ] Test exit notification
- [ ] Verify battery usage is acceptable

## Next Steps

1. **Configure coordinates** for your car wash location
2. **Test thoroughly** with location simulation
3. **Add UI integration** to show geofence status
4. **Customize actions** for entry/exit events
5. **Integrate with Firebase** for staff notifications
6. **Test on real devices** with various Android versions

## Support

For issues or questions about geofencing implementation, check:
- [Geolocator Documentation](https://pub.dev/packages/geolocator)
- [Android Background Location Guide](https://developer.android.com/training/location/permissions)
- Your `geofencing_service.dart` file for implementation details
