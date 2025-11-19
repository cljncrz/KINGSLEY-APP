import 'package:capstone/utils/app_textstyles.dart';
import 'package:capstone/screens/signup/enable_notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class EnableLocationScreen extends StatelessWidget {
  const EnableLocationScreen({super.key});

  void _goToNextScreen() {
    Get.off(() => const EnableNotificationScreen());
  }

  Future<void> _requestLocationPermission() async {
    // First request when in use permission
    final status = await Permission.locationWhenInUse.request();

    if (status.isGranted) {
      // Then request background location (always allow)
      final backgroundStatus = await Permission.locationAlways.request();

      if (backgroundStatus.isGranted) {
        Get.snackbar(
          'Success',
          'Location access granted for background geofencing.',
          snackPosition: SnackPosition.TOP,
        );
      } else {
        Get.snackbar(
          'Partial Access',
          'Location granted but background access limited. Geofencing will work when app is open.',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
        );
      }
    } else if (status.isDenied) {
      Get.snackbar(
        'Info',
        'Location access denied. You can enable it later in app settings.',
        snackPosition: SnackPosition.TOP,
      );
    } else if (status.isPermanentlyDenied) {
      Get.snackbar(
        'Action Required',
        'Location access permanently denied. Please enable it from app settings.',
        snackPosition: SnackPosition.TOP,
        mainButton: TextButton(
          onPressed: openAppSettings,
          child: const Text('Open Settings'),
        ),
      );
    }
    _goToNextScreen();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/location_on.png', // Make sure you have this image
                height: 180,
              ),
              const SizedBox(height: 40),
              Text(
                'Enable Location Services',
                textAlign: TextAlign.center,
                style: AppTextStyle.withColor(
                  AppTextStyle.h2,
                  Theme.of(context).textTheme.bodyLarge!.color!,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'We need your location to find nearby car wash branches and automatically notify our team when you arrive through geofencing.',
                textAlign: TextAlign.center,
                style: AppTextStyle.withColor(
                  AppTextStyle.bodySmall,
                  isDark ? Colors.grey[400]! : Colors.grey[600]!,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'For best experience, please select "Allow all the time" when prompted for location access.',
                textAlign: TextAlign.center,
                style: AppTextStyle.withColor(
                  AppTextStyle.bodySmall.copyWith(fontStyle: FontStyle.italic),
                  isDark ? Colors.amber[300]! : Colors.orange[700]!,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _requestLocationPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Enable Location',
                    style: AppTextStyle.withColor(
                      AppTextStyle.buttonMedium,
                      Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _goToNextScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF7F1618)
                        : const Color(0xFF7F1618),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Skip for Now',
                    style: AppTextStyle.buttonMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
