import 'package:capstone/services/geofencing_service.dart';
import 'package:capstone/utils/app_textstyles.dart';
import 'package:capstone/controllers/custom_bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Screen to display geofencing status and controls
class GeofenceStatusScreen extends StatelessWidget {
  const GeofenceStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final geofencingService = GeofencingService.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Locations'), elevation: 0),
      body: Obx(() {
        final isMonitoring = geofencingService.isMonitoring.value;
        final isInside = geofencingService.isInsideGeofence.value;
        final closestLoc = geofencingService.closestLocation.value;
        final closestName = closestLoc?['name'] ?? 'Nearest Location';
        final distance = geofencingService.distanceToClosest.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        isInside ? Icons.location_on : Icons.location_off,
                        size: 64,
                        color: isInside ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isInside
                            ? 'You\'re Near $closestName!\n(${geofencingService.formatDistance(distance)})'
                            : 'Not at Any Carwash Location',
                        style: AppTextStyle.withColor(
                          AppTextStyle.h2,
                          Theme.of(context).textTheme.bodyLarge!.color!,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isMonitoring
                            ? 'Geofencing is active'
                            : 'Geofencing is inactive',
                        style: AppTextStyle.withColor(
                          AppTextStyle.bodySmall,
                          isDark ? Colors.grey[400]! : Colors.grey[600]!,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Location Info
              if (geofencingService.currentPosition.value != null) ...[
                Text(
                  'Current Location',
                  style: AppTextStyle.withColor(
                    AppTextStyle.h3,
                    Theme.of(context).textTheme.bodyLarge!.color!,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Latitude',
                  geofencingService.currentPosition.value!.latitude
                      .toStringAsFixed(6),
                  isDark,
                ),
                _buildInfoRow(
                  'Longitude',
                  geofencingService.currentPosition.value!.longitude
                      .toStringAsFixed(6),
                  isDark,
                ),
                _buildInfoRow(
                  'Accuracy',
                  '${geofencingService.currentPosition.value!.accuracy.toStringAsFixed(0)}m',
                  isDark,
                ),
                const SizedBox(height: 24),
              ],

              // Distance Info
              FutureBuilder<double?>(
                future: geofencingService.getDistanceToCarwash(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    final distance = snapshot.data!;
                    return Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.straighten,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Distance to Carwash',
                                  style: AppTextStyle.withColor(
                                    AppTextStyle.bodySmall,
                                    isDark
                                        ? Colors.grey[400]!
                                        : Colors.grey[600]!,
                                  ),
                                ),
                                Text(
                                  geofencingService.formatDistance(distance),
                                  style: AppTextStyle.withColor(
                                    AppTextStyle.h3,
                                    Theme.of(
                                      context,
                                    ).textTheme.bodyLarge!.color!,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 24),

              // Controls
              Text(
                'Controls',
                style: AppTextStyle.withColor(
                  AppTextStyle.h3,
                  Theme.of(context).textTheme.bodyLarge!.color!,
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isMonitoring
                      ? () => geofencingService.stopMonitoring()
                      : () async {
                          final hasPermission = await geofencingService
                              .checkLocationPermissions();
                          if (hasPermission) {
                            await geofencingService.startMonitoring();
                          }
                        },
                  icon: Icon(
                    isMonitoring ? Icons.stop : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  label: Text(
                    isMonitoring ? 'Stop Monitoring' : 'Start Monitoring',
                    style: AppTextStyle.withColor(
                      AppTextStyle.buttonMedium,
                      Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isMonitoring
                        ? Colors.red
                        : Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Get Directions button - only show when inside geofence
              if (isInside)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => geofencingService.openDirections(),
                    icon: const Icon(Icons.directions, color: Colors.white),
                    label: Text(
                      'Get Directions',
                      style: AppTextStyle.withColor(
                        AppTextStyle.buttonMedium,
                        Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.directions),
                    label: Text(
                      'Get Directions (Not in Range)',
                      style: AppTextStyle.withColor(
                        AppTextStyle.buttonMedium,
                        Colors.grey,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final hasPermission = await geofencingService
                        .checkLocationPermissions();
                    if (hasPermission) {
                      Get.snackbar(
                        'Permissions OK',
                        'All location permissions are granted.',
                        snackPosition: SnackPosition.TOP,
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    'Check Permissions',
                    style: AppTextStyle.buttonMedium,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Info section
              Card(
                color: isDark ? Colors.blue[900] : Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: isDark ? Colors.blue[300] : Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'About Geofencing',
                            style: AppTextStyle.withColor(
                              AppTextStyle.h3,
                              isDark ? Colors.blue[300]! : Colors.blue[700]!,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• Geofencing works even when the app is closed\n'
                        '• Requires "Allow all the time" location permission\n'
                        '• Monitored area: 500m radius around carwash\n'
                        '• You\'ll receive notifications on entry/exit\n'
                        '• Battery optimized for minimal power usage',
                        style: AppTextStyle.withColor(
                          AppTextStyle.bodySmall,
                          isDark ? Colors.blue[200]! : Colors.blue[800]!,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
      bottomNavigationBar: const CustomBottomNavbar(),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyle.withColor(
              AppTextStyle.bodyMedium,
              isDark ? Colors.grey[400]! : Colors.grey[600]!,
            ),
          ),
          Text(
            value,
            style: AppTextStyle.withColor(
              AppTextStyle.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
