import 'package:capstone/controllers/navigation_controller.dart';
import 'package:capstone/utils/app_textstyles.dart';
import 'package:capstone/controllers/booking_controller.dart';
import 'package:capstone/models/booking.dart';
import 'package:capstone/screens/signup/signup_screen.dart';
import 'package:capstone/view/widgets/booking_view_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Data model for a service step
class ServiceStep {
  final IconData icon;
  final String title;
  final bool isComplete;
  final bool isInProgress;

  ServiceStep({
    required this.icon,
    required this.title,
    this.isComplete = false,
    this.isInProgress = false,
  });
}

class TrackBookingScreen extends StatelessWidget {
  const TrackBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BookingController bookingController = Get.find<BookingController>();
    final NavigationController navigationController =
        Get.find<NavigationController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _buildGuestView(context);
    }

    bookingController.fetchUserBookings(user.uid);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => navigationController.changeIndex(0),
            icon: Icon(
              Icons.arrow_back_ios,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          title: Text(
            'Track Bookings',
            style: AppTextStyle.withColor(
              AppTextStyle.h3,
              isDark ? Colors.white : Colors.black,
            ),
          ),
          bottom: TabBar(
            indicatorColor: Theme.of(context).primaryColor,
            labelStyle: AppTextStyle.withColor(
              AppTextStyle.bodySmall.copyWith(fontWeight: FontWeight.bold),
              isDark ? Colors.white : Theme.of(context).primaryColor,
            ),
            unselectedLabelStyle: AppTextStyle.withColor(
              AppTextStyle.bodySmall,
              isDark ? Colors.white70 : Colors.black,
            ),
            labelColor: isDark ? Colors.white : Theme.of(context).primaryColor,
            unselectedLabelColor: isDark ? Colors.white70 : Colors.black,
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Obx(
              () => _buildBookingList(
                context,
                bookingController.upcomingBookings,
                isDark,
              ),
            ),
            Obx(
              () => _buildBookingList(
                context,
                bookingController.activeBookings,
                isDark,
              ),
            ),
            Obx(
              () => _buildBookingList(
                context,
                bookingController.completedBookings,
                isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingList(
    BuildContext context,
    List<Booking> bookings,
    bool isDark,
  ) {
    if (bookings.isEmpty) {
      return Center(
        child: Text(
          'No bookings here.',
          style: AppTextStyle.withColor(
            AppTextStyle.bodyMedium,
            isDark ? Colors.grey[400]! : Colors.grey[600]!,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) =>
          _buildBookingCard(context, bookings[index], isDark),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: isDark
          ? Colors.black.withOpacity(0.5)
          : Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.serviceNames.join(', '),
                  style: AppTextStyle.withColor(
                    AppTextStyle.h3,
                    Theme.of(context).textTheme.bodyLarge!.color!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Price
            Text(
              'Price: ${booking.price.toStringAsFixed(2)}',
              style: AppTextStyle.withColor(
                AppTextStyle.bodySmall,
                isDark ? Colors.white : Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            // Status
            if (booking.status == 'Pending')
              Text(
                'Status: Pending',
                style: AppTextStyle.bodySmall.copyWith(color: Colors.orange),
              )
            else if (booking.status == 'Upcoming')
              Text(
                'Status: Booking Approved',
                style: AppTextStyle.bodySmall.copyWith(color: Colors.green),
              )
            else
              Text(
                'Status: ${booking.status}',
                style: AppTextStyle.bodySmall.copyWith(
                  color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
                ),
              ),
            const SizedBox(height: 4),
            // Date and Time in a Row
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Theme.of(context).textTheme.bodySmall!.color!,
                ),
                const SizedBox(width: 8),
                Text(
                  booking.bookingDate,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Theme.of(context).textTheme.bodySmall!.color!,
                ),
                const SizedBox(width: 8),
                Text(
                  booking.bookingTime,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Technician: ${booking.technician}',
              style: AppTextStyle.withColor(
                AppTextStyle.bodySmall,
                isDark ? Colors.grey[400]! : Colors.grey[600]!,
              ),
            ),
            const Divider(height: 24),
            if (booking.status == 'Pending' || booking.status == 'Upcoming')
              Column(
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: _buildBookingActionButton(
                      context: context,
                      text: 'View Details',
                      onPressed: () =>
                          Get.to(() => ViewDetailsScreen(booking: booking)),
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: (booking.status == 'Active')
                        ? _buildBookingActionButton(
                            context: context,
                            text: 'Track Progress',
                            onPressed: () =>
                                _showTrackingDialog(context, booking),
                          )
                        : (booking.status == 'Completed')
                        ? _buildBookingActionButton(
                            context: context,
                            text: 'Feedback',
                            onPressed: () {}, // TODO: Implement feedback
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.track_changes_outlined,
              size: 80,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'You are in Guest Mode',
              style: AppTextStyle.withColor(
                AppTextStyle.h2,
                Theme.of(context).textTheme.bodyLarge!.color!,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sign up or log in to track your bookings.',
              style: AppTextStyle.withColor(
                AppTextStyle.bodyMedium,
                isDark ? Colors.grey[500]! : Colors.grey[600]!,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.to(() => const SignupScreen()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Sign Up',
                style: AppTextStyle.buttonMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingActionButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 150, // Set a fixed width for the button
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: AppTextStyle.withColor(AppTextStyle.small, Colors.white),
        ),
      ),
    );
  }

  void _showTrackingDialog(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.serviceNames.join(', '),
                style: AppTextStyle.withColor(
                  AppTextStyle.h3,
                  Theme.of(context).textTheme.bodyLarge!.color!,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // --- ESTIMATED TIME Section ---
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Align text to the left
                    children: <Widget>[
                      Text(
                        'ESTIMATED TIME 45 MINS. - 1HR',
                        style: AppTextStyle.withColor(
                          AppTextStyle.small,
                          isDark
                              ? Colors.grey[400]!
                              : Theme.of(context).textTheme.bodyLarge!.color!,
                        ),
                      ),
                    ],
                  ),

                  // Add some space between the two columns
                  const SizedBox(width: 35),
                ],
              ),
              const Divider(height: 24),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite, // Ensures the dialog is a reasonable width
            child: ProgressTracker(currentProgress: booking.progress),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: isDark ? Colors.white70 : Colors.black,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Back',
                      style: AppTextStyle.withColor(
                        AppTextStyle.bodySmall,
                        Theme.of(context).textTheme.bodySmall!.color!,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7F1618), // Dark Red
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: AppTextStyle.withColor(
                        AppTextStyle.bodySmall,
                        Colors.white,
                      ),
                    ),
                    onPressed: () => Get.back(),
                  ),
                ),
              ],
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
        );
      },
    );
  }
}

// The main widget to build the progress timeline
class ProgressTracker extends StatelessWidget {
  final BookingProgress currentProgress;
  const ProgressTracker({super.key, required this.currentProgress});

  @override
  Widget build(BuildContext context) {
    // Define the steps shown in the image
    final List<ServiceStep> steps = [
      ServiceStep(icon: Icons.flash_on, title: 'Queued'),
      ServiceStep(icon: Icons.cleaning_services_outlined, title: 'In Progress'),
      ServiceStep(icon: Icons.directions_car_filled, title: 'Service Complete'),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (index) {
        return ProgressStepItem(
          step: steps[index],
          isLast: index == steps.length - 1,
          isCurrent: index == currentProgress.index,
          isComplete: index < currentProgress.index,
        );
      }),
    );
  }
}

// Widget for a single step in the timeline
class ProgressStepItem extends StatelessWidget {
  final ServiceStep step;
  final bool isLast;
  final bool isCurrent;
  final bool isComplete;

  const ProgressStepItem({
    super.key,
    required this.step,
    this.isLast = false,
    this.isCurrent = false,
    this.isComplete = false,
  });

  // The dark red color used in the imag
  @override
  Widget build(BuildContext context) {
    final color = (isCurrent || isComplete)
        ? const Color(0xFF7F1618)
        : Colors.grey;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Timeline Dots and Line ---
          SizedBox(
            width: 20, // Width for the timeline visuals
            child: Column(
              children: [
                // The Timeline Dot
                Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),

                // The Connecting Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2, // Thickness of the line
                      color: isComplete ? const Color(0xFF7F1618) : Colors.grey,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 15), // Spacing between timeline and content
          // --- Icon and Text Content ---
          Padding(
            padding: EdgeInsets.only(
              bottom: isLast ? 0 : 30.0,
            ), // Padding to separate items
            child: Row(
              children: [
                // Icon
                Icon(step.icon, color: color, size: 40),

                const SizedBox(width: 15), // Spacing between icon and text
                // Text Title
                Text(
                  step.title,
                  style: AppTextStyle.withColor(
                    AppTextStyle.bodyMedium,
                    // Assuming isDark is available in the context or passed down
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
