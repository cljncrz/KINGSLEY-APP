import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:capstone/services/local_notification_service.dart';
import 'package:url_launcher/url_launcher.dart';

class GeofencingService extends GetxService {
  static GeofencingService get instance => Get.find<GeofencingService>();

  // Geofence configuration - support for multiple locations
  final RxDouble geofenceRadius = 500.0.obs;

  // Multiple locations support
  final RxList<Map<String, dynamic>> geofenceLocations =
      <Map<String, dynamic>>[].obs;
  final Rx<Map<String, dynamic>?> closestLocation = Rx<Map<String, dynamic>?>(
    null,
  );
  final RxDouble distanceToClosest = 0.0.obs;

  // Observables
  final RxBool isInsideGeofence = false.obs;
  final RxBool isMonitoring = false.obs;
  final RxBool isLocationDataLoaded = false.obs;
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

  /// Fetch all geofencing locations from Firestore
  Future<void> _fetchGeofencingLocations() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('geofencing_locations')
          .get(); // Get ALL locations

      if (snapshot.docs.isNotEmpty) {
        geofenceLocations.clear();

        for (var doc in snapshot.docs) {
          final data = doc.data();
          geofenceLocations.add({
            'id': doc.id,
            'latitude': (data['latitude'] as num).toDouble(),
            'longitude': (data['longitude'] as num).toDouble(),
            'radius': (data['radius'] as num?)?.toDouble() ?? 500.0,
            'name': data['name'] as String? ?? 'Carwash Location',
          });
        }

        print('Loaded ${geofenceLocations.length} geofence locations');
        for (var loc in geofenceLocations) {
          print('📍 ${loc['name']}: ${loc['latitude']}, ${loc['longitude']}');
        }

        isLocationDataLoaded.value = true;
      } else {
        print('No geofencing locations found in Firestore');
      }
    } catch (e) {
      print('Error fetching geofencing locations: $e');
    }
  }

  /// Find the closest location to current position
  Future<Map<String, dynamic>?> findClosestLocation(Position position) async {
    if (geofenceLocations.isEmpty) return null;

    Map<String, dynamic>? closest;
    double minDistance = double.infinity;

    for (var location in geofenceLocations) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        location['latitude'],
        location['longitude'],
      );

      if (distance < minDistance) {
        minDistance = distance;
        closest = location;
      }
    }

    if (closest != null) {
      closestLocation.value = closest;
      distanceToClosest.value = minDistance;
    }

    return closest;
  }

  /// Initialize geofencing service
  Future<void> _initializeGeofencing() async {
    // First fetch all locations from Firestore
    await _fetchGeofencingLocations();

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

  /// Check if current position is inside any geofence
  void _checkGeofence(Position position) {
    bool wasInside = isInsideGeofence.value;
    bool isNowInside = false;

    // Check if user is inside any of the geofence locations
    for (var location in geofenceLocations) {
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        location['latitude'],
        location['longitude'],
      );

      if (distance <= location['radius']) {
        isNowInside = true;
        closestLocation.value = location;
        distanceToClosest.value = distance;
        break;
      }
    }

    if (isNowInside != wasInside) {
      isInsideGeofence.value = isNowInside;

      if (isNowInside && closestLocation.value != null) {
        _onGeofenceEnter(closestLocation.value!, distanceToClosest.value);
      } else {
        _onGeofenceExit();
      }
    }
  }

  /// Handle geofence entry
  void _onGeofenceEnter(Map<String, dynamic> location, double distance) {
    final locName = location['name'] ?? 'Carwash Location';
    print(
      'Entered geofence: $locName! Distance: ${distance.toStringAsFixed(0)}m',
    );

    // Show notification
    LocalNotificationService.instance.showNotification(
      title: 'Welcome to $locName! 🚗',
      body: 'Our promos are waiting!\nCheck the app for exclusive offers.',
      payload: 'geofence_enter',
    );
  }

  /// Handle geofence exit
  void _onGeofenceExit() {
    print('Exited all geofences!');

    // Show notification
    LocalNotificationService.instance.showNotification(
      title: 'Thanks for visiting! 👋',
      body: 'We hope to see you again soon!',
      payload: 'geofence_exit',
    );
  }

  /// Get distance to closest carwash
  Future<double?> getDistanceToCarwash() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final closest = await findClosestLocation(position);
      if (closest == null) return null;

      return Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        closest['latitude'],
        closest['longitude'],
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
    return distance <= geofenceRadius.value;
  }

  /// Open Google Maps with directions to closest carwash
  Future<void> openDirections() async {
    try {
      final currentPos = currentPosition.value;

      if (currentPos == null) {
        Get.snackbar(
          'Location Error',
          'Unable to get your current location. Please ensure location services are enabled.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Find closest location
      final closest = await findClosestLocation(currentPos);
      if (closest == null) {
        Get.snackbar(
          'Error',
          'No carwash locations found.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Create Google Maps URL with direction parameters to closest location
      final String googleMapsUrl =
          'https://www.google.com/maps/dir/?api=1'
          '&origin=${currentPos.latitude},${currentPos.longitude}'
          '&destination=${closest['latitude']},${closest['longitude']}'
          '&travelmode=driving';

      // Try to launch the URL
      final Uri uri = Uri.parse(googleMapsUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          'Error',
          'Could not launch Google Maps. Please ensure it is installed.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error opening directions: $e');
      Get.snackbar(
        'Error',
        'Failed to open Google Maps: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
