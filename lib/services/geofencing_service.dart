import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:capstone/services/local_notification_service.dart';

class GeofencingService extends GetxService {
  static GeofencingService get instance => Get.find<GeofencingService>();

  // Geofence configuration
  static const double geofenceRadius = 500.0; // 500 meters

  // Car wash location (replace with your actual coordinates)
  static const double carwashLatitude = 14.5995; // Example: Manila coordinates
  static const double carwashLongitude = 120.9842;

  // Observables
  final RxBool isInsideGeofence = false.obs;
  final RxBool isMonitoring = false.obs;
  final Rx<Position?> currentPosition = Rx<Position?>(null);

  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _backgroundTimer;

  @override
  void onInit() {
    super.onInit();
    _initializeGeofencing();
  }

  @override
  void onClose() {
    stopMonitoring();
    _backgroundTimer?.cancel();
    super.onClose();
  }

  /// Initialize geofencing service
  Future<void> _initializeGeofencing() async {
    final hasPermission = await checkLocationPermissions();
    if (hasPermission) {
      await startMonitoring();
    }
  }

  /// Check and request location permissions including background
  Future<bool> checkLocationPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        'Location Services Disabled',
        'Please enable location services to use geofencing features.',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar(
          'Location Permission Denied',
          'Location permissions are required for geofencing.',
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar(
        'Location Permission Required',
        'Please enable location permission in app settings.',
        snackPosition: SnackPosition.TOP,
        mainButton: TextButton(
          onPressed: () => Geolocator.openAppSettings(),
          child: const Text('Open Settings'),
        ),
      );
      return false;
    }

    // Request background location permission (Android 10+)
    if (permission == LocationPermission.whileInUse) {
      final backgroundStatus = await Permission.locationAlways.request();
      if (!backgroundStatus.isGranted) {
        Get.snackbar(
          'Background Location Needed',
          'For geofencing to work when the app is closed, please enable "Allow all the time" in location settings.',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 5),
        );
      }
    }

    return true;
  }

  /// Start monitoring geofence
  Future<void> startMonitoring() async {
    if (isMonitoring.value) return;

    try {
      isMonitoring.value = true;

      // Get initial position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      currentPosition.value = position;
      _checkGeofence(position);

      // Start continuous monitoring with optimized settings
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.medium, // Balance accuracy and battery
        distanceFilter: 50, // Update every 50 meters
        timeLimit: Duration(minutes: 5), // Timeout after 5 minutes
      );

      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (Position position) {
              currentPosition.value = position;
              _checkGeofence(position);
            },
            onError: (error) {
              print('Error monitoring location: $error');
              isMonitoring.value = false;
            },
          );

      // Set up periodic background check (every 5 minutes)
      _backgroundTimer = Timer.periodic(const Duration(minutes: 5), (
        timer,
      ) async {
        if (!isMonitoring.value) {
          timer.cancel();
          return;
        }
        try {
          Position pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
          );
          _checkGeofence(pos);
        } catch (e) {
          print('Background check error: $e');
        }
      });

      print('Geofencing monitoring started');
    } catch (e) {
      print('Error starting geofence monitoring: $e');
      isMonitoring.value = false;
    }
  }

  /// Stop monitoring geofence
  void stopMonitoring() {
    _positionStreamSubscription?.cancel();
    _backgroundTimer?.cancel();
    isMonitoring.value = false;
    print('Geofencing monitoring stopped');
  }

  /// Check if current position is inside geofence
  void _checkGeofence(Position position) {
    double distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      carwashLatitude,
      carwashLongitude,
    );

    bool wasInside = isInsideGeofence.value;
    bool isNowInside = distance <= geofenceRadius;

    if (isNowInside != wasInside) {
      isInsideGeofence.value = isNowInside;

      if (isNowInside) {
        _onGeofenceEnter(distance);
      } else {
        _onGeofenceExit(distance);
      }
    }
  }

  /// Handle geofence entry
  void _onGeofenceEnter(double distance) {
    print('Entered geofence! Distance: ${distance.toStringAsFixed(0)}m');

    // Show notification
    LocalNotificationService.instance.showNotification(
      title: 'Welcome to Kingsley Carwash! 🚗',
      body:
          'You\'re nearby! Our team is ready to serve you. Distance: ${distance.toStringAsFixed(0)}m',
      payload: 'geofence_enter',
    );

    // You can trigger additional actions here:
    // - Update user status in Firestore
    // - Notify staff through Firebase
    // - Start preparation workflow
  }

  /// Handle geofence exit
  void _onGeofenceExit(double distance) {
    print('Exited geofence! Distance: ${distance.toStringAsFixed(0)}m');

    // Show notification
    LocalNotificationService.instance.showNotification(
      title: 'Thanks for visiting Kingsley Carwash! 👋',
      body: 'We hope to see you again soon!',
      payload: 'geofence_exit',
    );

    // Additional exit actions:
    // - Update user status
    // - Request feedback
    // - Show thank you message
  }

  /// Get distance to carwash
  Future<double?> getDistanceToCarwash() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        carwashLatitude,
        carwashLongitude,
      );
    } catch (e) {
      print('Error getting distance: $e');
      return null;
    }
  }

  /// Format distance for display
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Check if user is currently inside geofence
  Future<bool> isUserNearCarwash() async {
    final distance = await getDistanceToCarwash();
    if (distance == null) return false;
    return distance <= geofenceRadius;
  }
}
