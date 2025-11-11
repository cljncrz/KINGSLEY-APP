import 'package:capstone/controllers/navigation_controller.dart';
import 'package:capstone/models/booking.dart';
import 'package:capstone/utils/app_textstyles.dart';
import 'package:capstone/view/home/main_screen.dart';
import 'package:capstone/controllers/custom_bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CancelSuccessScreen extends StatelessWidget {
  final Booking booking;

  const CancelSuccessScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () {
            Get.back();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_none,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () {
              // TODO: Handle notification icon press
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // 1. Success Checkmark Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cancel_outlined,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),

              // 2. Heading Text
              Text(
                'Booking Cancelled!',
                style: AppTextStyle.h2.copyWith(
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // 3. Detail Text
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTextStyle.bodyMedium.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                    height: 1.5,
                  ),
                  children: <TextSpan>[
                    const TextSpan(
                      text: 'You have successfully cancelled your booking of ',
                    ),
                    TextSpan(
                      text: booking.serviceNames.join(', '),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(
                      text:
                          '. We have sent a confirmation to your registered email.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // 4. Service Card
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1C1C1C)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Image thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: Image.asset(
                        'assets/wash_services/motorcycle_wash_armor_all.png', // Placeholder
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Service Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            booking.serviceNames.join(', '),
                            style: AppTextStyle.h3,
                          ),
                          const SizedBox(height: 4),
                          Text('• 45 minutes', style: AppTextStyle.bodySmall),
                          Text(
                            '• for all car types',
                            style: AppTextStyle.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // 4. Fixed Bottom Button
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Get.find<NavigationController>().changeIndex(1);
                  Get.offAll(() => const MainScreen());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Go to Bookings',
                  style: AppTextStyle.buttonMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const CustomBottomNavbar(),
        ],
      ),
    );
  }
}
