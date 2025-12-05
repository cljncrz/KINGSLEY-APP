import 'package:capstone/controllers/navigation_controller.dart';
import 'package:capstone/utils/app_textstyles.dart';
import 'package:capstone/controllers/feedback_controller.dart';
import 'package:capstone/controllers/booking_controller.dart';
import 'package:capstone/controllers/notification_controller.dart';
import 'package:capstone/models/booking.dart';
import 'package:capstone/screens/signup/signup_screen.dart';
import 'package:capstone/view/widgets/booking_view_details_screen.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

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

class TrackBookingScreen extends StatefulWidget {
  const TrackBookingScreen({super.key});

  @override
  State<TrackBookingScreen> createState() => _TrackBookingScreenState();
}

class _TrackBookingScreenState extends State<TrackBookingScreen>
    with SingleTickerProviderStateMixin {
  late final BookingController bookingController;
  late final NavigationController navigationController;
  StreamSubscription<List<Booking>>? _bookingListener;
  final Map<String, String> _previousStatuses = {};
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    bookingController = Get.find<BookingController>();
    navigationController = Get.find<NavigationController>();
    tabController = TabController(length: 3, vsync: this);

    // If user is logged in, listen to the bookings stream to detect status changes
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _bookingListener = bookingController
          .fetchUserBookings(user.uid)
          .listen(
            (bookings) {
              if (!mounted) return; // Prevent updates if the widget is disposed
              for (final b in bookings) {
                final id = b.id ?? '';
                final prev = _previousStatuses[id];
                if (prev == null && id.isNotEmpty) {
                  // first time seeing this booking, store status
                  _previousStatuses[id] = b.status;
                } else if (prev != null && prev != b.status) {
                  // status changed
                  _previousStatuses[id] = b.status;
                  _showStatusNotification(b);
                }
              }
            },
            onError: (err) {
              debugPrint('Booking listener error: $err');
            },
          );
    }
  }

  @override
  void dispose() {
    _bookingListener?.cancel();
    tabController.dispose();
    super.dispose();
  }

  bool _isApprovedStatus(String? status) {
    if (status == null) return false;
    final s = status.toLowerCase();
    return s.contains('up') || s.contains('approv') || s.contains('approved');
  }

  bool _isActiveStatus(String? status) {
    if (status == null) return false;
    final s = status.toLowerCase();
    return s.contains('active') ||
        s.contains('in progress') ||
        s.contains('inprogress') ||
        s.contains('ongoing');
  }

  bool _isCompletedStatus(String? status) {
    if (status == null) return false;
    final s = status.toLowerCase();
    return s.contains('complete') ||
        s.contains('completed') ||
        s.contains('done');
  }

  bool _isCancelledStatus(String? status) {
    if (status == null) return false;
    final s = status.toLowerCase();
    return s.contains('cancel') || s.contains('cancelled');
  }

  void _showStatusNotification(Booking booking) {
    if (!mounted) return;
    final s = booking.status.toLowerCase();

    String title;
    String body;

    if (s.contains('approv') || s.contains('up') || s.contains('upcoming')) {
      title = 'Booking Approved';
      body =
          'Your booking for ${booking.serviceNames.join(', ')} has been approved.';
    } else if (s.contains('cancel')) {
      title = 'Booking Cancelled';
      body =
          'Your booking for ${booking.serviceNames.join(', ')} has been cancelled by the admin.';
    } else if (s.contains('resched') ||
        s.contains('reschedul') ||
        s.contains('reschedule')) {
      title = 'Booking Rescheduled';
      body =
          'Your booking for ${booking.serviceNames.join(', ')} has been rescheduled. Please check the new date/time.';
    } else if (s.contains('active') || s.contains('in progress')) {
      title = 'Booking In Progress';
      body = 'Your booking is now in progress.';
    } else if (s.contains('complete')) {
      title = 'Booking Completed';
      body = 'Your booking is complete. Please provide feedback.';
    } else {
      title = 'Booking Update';
      body = 'Status changed to: ${booking.status}';
    }

    // Show a quick snackbar for immediate feedback
    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );

    // Persist the notification to Firestore via NotificationController so it appears in the Notifications screen
    try {
      final notificationController = Get.find<NotificationController>();
      notificationController.createNotification(
        title: title,
        body: body,
        type: 'booking_status',
        bookingId: booking.id,
      );
    } catch (e) {
      // If controller not found or write fails, just ignore to avoid crashing the UI
      print('Could not create persistent notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _buildGuestView(context);
    }

    // Ensure controller has started fetching/binding bookings (controller also binds in onInit)
    bookingController.fetchUserBookings(user.uid);

    return Scaffold(
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
          controller: tabController,
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // Listen to user's bookings collection so UI updates in real-time
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading bookings'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Map documents to Booking model
          final docs = snapshot.data!.docs;
          final allBookings = docs.map((d) => Booking.fromSnapshot(d)).toList();

          // Partition bookings into tabs
          final upcoming = allBookings
              .where(
                (b) =>
                    !_isActiveStatus(b.status) &&
                    !_isCompletedStatus(b.status) &&
                    !_isCancelledStatus(b.status),
              )
              .toList();
          final active = allBookings
              .where(
                (b) =>
                    _isActiveStatus(b.status) && !_isCancelledStatus(b.status),
              )
              .toList();
          final completed = allBookings
              .where(
                (b) =>
                    _isCompletedStatus(b.status) ||
                    _isCancelledStatus(b.status),
              )
              .toList();

          return TabBarView(
            controller: tabController,
            children: [
              _buildBookingList(context, upcoming, isDark, 'Upcoming'),
              _buildBookingList(context, active, isDark, 'Active'),
              _buildBookingList(context, completed, isDark, 'Completed'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingList(
    BuildContext context,
    List<Booking> bookings,
    bool isDark, [
    String tabName = '',
  ]) {
    if (bookings.isEmpty) {
      return Center(
        child: Text(
          tabName == 'Active' ? 'No Bookings Here' : 'No bookings here.',
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
          _buildBookingCard(context, bookings[index], isDark, tabName),
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    Booking booking,
    bool isDark, [
    String tabName = '',
  ]) {
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: booking.serviceNames
                        .map(
                          (serviceName) => Text(
                            serviceName,
                            style: AppTextStyle.withColor(
                              AppTextStyle.h3,
                              Theme.of(context).textTheme.bodyLarge!.color!,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                if (tabName == 'Completed')
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      if (booking.id != null) {
                        _showDeleteConfirmationDialog(context, booking.id!);
                      }
                    },
                    tooltip: 'Delete Booking History',
                    splashRadius: 20,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.only(left: 16, top: 4),
                  ),
              ],
            ),
            // Price (only show when not already displayed in the Approved container)
            if (!_isApprovedStatus(booking.status))
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
            else if (_isApprovedStatus(booking.status))
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
                Expanded(
                  child: Text(
                    booking.bookingDate,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Theme.of(context).textTheme.bodySmall!.color!,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.bookingTime,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
            if (booking.status == 'Pending')
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
            else if (_isApprovedStatus(booking.status))
              Column(
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              Get.to(() => ViewDetailsScreen(booking: booking)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Details',
                            style: AppTextStyle.withColor(
                              AppTextStyle.buttonMedium,
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showPaymentDialog(context, booking),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Pay Now',
                            style: AppTextStyle.withColor(
                              AppTextStyle.buttonMedium,
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else if (_isCompletedStatus(booking.status))
              Obx(() {
                final feedbackController = Get.find<FeedbackController>();
                final hasServiceFeedback = feedbackController.serviceFeedbacks
                    .containsKey(booking.id);

                return hasServiceFeedback
                    ? _buildFeedbackDisplay(context, booking, isDark)
                    : _buildFeedbackButton(context, booking);
              })
            else
              Column(
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: (_isActiveStatus(booking.status))
                        ? (booking.id == null
                              ? ProgressTracker(
                                  currentProgress: booking.progress,
                                )
                              : StreamBuilder<
                                  DocumentSnapshot<Map<String, dynamic>>
                                >(
                                  stream: FirebaseFirestore.instance
                                      .collection('bookings')
                                      .doc(booking.id)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) {
                                      return Text('Error loading progress');
                                    }
                                    if (!snapshot.hasData ||
                                        !snapshot.data!.exists) {
                                      return ProgressTracker(
                                        currentProgress: booking.progress,
                                      );
                                    }

                                    final doc = snapshot.data!;
                                    var updated = Booking.fromSnapshot(doc);

                                    // Auto-sync progress with status if needed
                                    if (updated.status.toLowerCase().contains(
                                          'in progress',
                                        ) &&
                                        updated.progress.index < 1) {
                                      updated = updated.copyWith(
                                        progress: BookingProgress.inProgress,
                                      );
                                    } else if (updated.status
                                            .toLowerCase()
                                            .contains('complete') &&
                                        updated.progress.index < 2) {
                                      updated = updated.copyWith(
                                        progress: BookingProgress.completed,
                                      );
                                    }

                                    return ProgressTracker(
                                      currentProgress: updated.progress,
                                    );
                                  },
                                ))
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackButton(BuildContext context, Booking booking) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Center(
          child: _buildBookingActionButton(
            context: context,
            text: 'Feedback',
            onPressed: () {
              if (booking.id != null) {
                _showFeedbackDialog(context, booking);
              } else {
                Get.snackbar('Error', 'Cannot give feedback for this booking.');
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackDisplay(
    BuildContext context,
    Booking booking,
    bool isDark,
  ) {
    final feedbackController = Get.find<FeedbackController>();
    final serviceFeedback = feedbackController.serviceFeedbacks[booking.id];
    final techFeedback = feedbackController.technicianFeedbacks[booking.id];

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (serviceFeedback != null) ...[
            Text(
              'Service Feedback',
              style: AppTextStyle.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                RatingBarIndicator(
                  rating: serviceFeedback.rating,
                  itemBuilder: (context, index) =>
                      const Icon(Icons.star, color: Colors.amber),
                  itemCount: 5,
                  itemSize: 18.0,
                ),
                const SizedBox(width: 8),
                Text(
                  '(${serviceFeedback.rating})',
                  style: AppTextStyle.bodySmall,
                ),
              ],
            ),
            if (serviceFeedback.comment.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '"${serviceFeedback.comment}"',
                style: AppTextStyle.bodySmall.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
          if (techFeedback != null) ...[
            Text(
              'Feedback for ${techFeedback.technicianName}',
              style: AppTextStyle.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                RatingBarIndicator(
                  rating: techFeedback.rating,
                  itemBuilder: (context, index) =>
                      const Icon(Icons.star, color: Colors.amber),
                  itemCount: 5,
                  itemSize: 18.0,
                ),
                const SizedBox(width: 8),
                Text('(${techFeedback.rating})', style: AppTextStyle.bodySmall),
              ],
            ),
            if (techFeedback.comment != null &&
                techFeedback.comment!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '"${techFeedback.comment}"',
                style: AppTextStyle.bodySmall.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ] else if (booking.technician != null &&
              booking.technician!.isNotEmpty) ...[
            Text(
              'Technician Feedback (${booking.technician})',
              style: AppTextStyle.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You chose to skip providing feedback for the technician.',
              style: AppTextStyle.bodySmall.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, Booking booking) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bookingController = Get.find<BookingController>();

    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(
                Icons.payment_outlined,
                color: Colors.green[400],
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Process Payment',
              textAlign: TextAlign.center,
              style: AppTextStyle.withColor(
                AppTextStyle.h3,
                Theme.of(context).textTheme.bodyLarge!.color!,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Services:',
                        style: AppTextStyle.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        booking.serviceNames.join(', '),
                        style: AppTextStyle.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amount:',
                        style: AppTextStyle.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₱${booking.price.toStringAsFixed(2)}',
                        style: AppTextStyle.bodySmall.copyWith(
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Payment Method:',
                        style: AppTextStyle.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        booking.paymentMethod ?? 'Not specified',
                        style: AppTextStyle.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Click "Confirm Payment" to complete the transaction.',
              textAlign: TextAlign.center,
              style: AppTextStyle.withColor(
                AppTextStyle.bodySmall,
                isDark ? Colors.grey[400]! : Colors.grey[600]!,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel',
              style: AppTextStyle.buttonMedium.copyWith(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (booking.id != null) {
                await bookingController.processApprovedBookingPayment(
                  bookingId: booking.id!,
                  booking: booking,
                );
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Confirm Payment',
              style: AppTextStyle.buttonMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
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

  void _showFeedbackDialog(BuildContext context, Booking booking) {
    final feedbackController = Get.find<FeedbackController>();
    final commentTextController = TextEditingController();
    final rating = 5.0.obs; // Default to 5 stars

    Get.dialog(
      AlertDialog(
        title: Text('Rate Your Service', style: AppTextStyle.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How was your experience?', style: AppTextStyle.bodyMedium),
            const SizedBox(height: 16),
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      rating.value = (index + 1).toDouble();
                    },
                    icon: Icon(
                      index < rating.value ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 35,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentTextController,
              decoration: InputDecoration(
                hintText: 'Add a comment (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: AppTextStyle.buttonMedium.copyWith(color: Colors.white),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final success = await feedbackController.submitFeedback(
                bookingId: booking.id!,
                rating: rating.value,
                comment: commentTextController.text,
              );
              if (success && mounted) {
                Get.back(); // Close the service feedback dialog
                _showTechnicianFeedbackDialog(context, booking);
              }
            },
            child: Text(
              'Submit',
              style: AppTextStyle.buttonMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String bookingId) {
    Get.dialog(
      AlertDialog(
        title: Text('Delete Booking History', style: AppTextStyle.h3),
        content: Text(
          'Are you sure you want to permanently delete this booking history? This action cannot be undone.',
          style: AppTextStyle.bodyMedium,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Get.back(); // Close dialog
              await Get.find<BookingController>().deleteBooking(bookingId);
            },
            child: Text(
              'Delete',
              style: AppTextStyle.buttonMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showTechnicianFeedbackDialog(BuildContext context, Booking booking) {
    if (booking.technician == null || booking.technician!.isEmpty) {
      return; // Don't show if no technician is assigned
    }

    final feedbackController = Get.find<FeedbackController>();
    final commentTextController = TextEditingController();
    final rating = 5.0.obs;

    Get.dialog(
      AlertDialog(
        title: Text(
          'Rate Technician: ${booking.technician}',
          style: AppTextStyle.h3,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'How was your experience with the technician?',
              style: AppTextStyle.bodyMedium,
            ),
            const SizedBox(height: 16),
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      rating.value = (index + 1).toDouble();
                    },
                    icon: Icon(
                      index < rating.value ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 35,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentTextController,
              decoration: InputDecoration(
                hintText: 'Add a comment (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Skip')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              feedbackController.submitTechnicianFeedback(
                bookingId: booking.id!,
                technicianName: booking.technician!,
                rating: rating.value,
                comment: commentTextController.text,
              );
              Get.back(); // Close the dialog
            },
            child: Text(
              'Submit',
              style: AppTextStyle.buttonMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
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
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'ESTIMATED TIME 45 MINS. - 1HR',
                          style: AppTextStyle.withColor(
                            AppTextStyle.small,
                            isDark
                                ? Colors.grey[400]!
                                : Theme.of(context).textTheme.bodyLarge!.color!,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite, // Ensures the dialog is a reasonable width
            child: booking.id == null
                ? ProgressTracker(currentProgress: booking.progress)
                : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .doc(booking.id)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error loading progress'));
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return ProgressTracker(
                          currentProgress: booking.progress,
                        );
                      }

                      final doc = snapshot.data!;
                      final updated = Booking.fromSnapshot(doc);

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Show current status text
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Text(
                              'Status: ${updated.status}',
                              style: AppTextStyle.withColor(
                                AppTextStyle.bodyMedium,
                                Theme.of(context).textTheme.bodySmall!.color!,
                              ),
                            ),
                          ),
                          ProgressTracker(currentProgress: updated.progress),
                        ],
                      );
                    },
                  ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Define the steps shown in the image
    final List<ServiceStep> steps = [
      ServiceStep(icon: Icons.check_circle_outline, title: 'Approved'),
      ServiceStep(icon: Icons.cleaning_services_outlined, title: 'In Progress'),
      ServiceStep(icon: Icons.directions_car_filled, title: 'Service Complete'),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ESTIMATED TIME 45 MINS. - 1HR',
          style: AppTextStyle.withColor(
            AppTextStyle.small,
            isDark
                ? Colors.grey[400]!
                : Theme.of(context).textTheme.bodyLarge!.color!,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(steps.length, (index) {
          return ProgressStepItem(
            step: steps[index],
            isLast: index == steps.length - 1,
            isCurrent: index == currentProgress.index,
            isComplete: index < currentProgress.index,
          );
        }),
      ],
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
