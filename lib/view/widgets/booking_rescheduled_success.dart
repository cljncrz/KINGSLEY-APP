import 'package:capstone/models/booking.dart';
import 'package:capstone/controllers/navigation_controller.dart';
import 'package:capstone/utils/app_textstyles.dart';
import 'package:capstone/view/home/cart_screen.dart';
import 'package:capstone/view/home/main_screen.dart';
import 'package:capstone/controllers/custom_bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class BookingRescheduledSuccess extends StatelessWidget {
  final Booking booking;
  final DateTime newDate;
  final TimeSlot newTimeSlot;
  final String rescheduleReason;

  const BookingRescheduledSuccess({
    super.key,
    required this.booking,
    required this.newDate,
    required this.newTimeSlot,
    required this.rescheduleReason,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedTime = newTimeSlot.format(context);
    final formattedDate = DateFormat.yMMMMd().format(newDate);

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
              Image.asset('assets/images/resched.png', width: 80, height: 80),
              const SizedBox(height: 24),

              // 2. Heading Text
              Text(
                'Booking Rescheduled!',
                style: AppTextStyle.h2.copyWith(
                  color: isDark ? Colors.yellow : Colors.yellow[800]!,
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
                      text:
                          'You have successfully re-scheduled your booking of ',
                    ),
                    TextSpan(
                      text: booking.serviceNames.join(', '),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: ' for the new date '),
                    TextSpan(
                      text: '$formattedDate at $formattedTime.',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(
                      text: ' Our service provider will contact you soon.',
                    ),
                  ],
                ),
              ),
              if (rescheduleReason.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Reason provided: "$rescheduleReason"',
                  textAlign: TextAlign.center,
                  style: AppTextStyle.bodySmall.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
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
      // 5. Fixed Bottom Button
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
                }, // Removed the extra positional argument
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
