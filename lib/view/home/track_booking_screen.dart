import 'package:capstone/controllers/navigation_controller.dart';
import 'package:capstone/utils/app_textstyles.dart';
import 'package:capstone/controllers/booking_controller.dart';
import 'package:capstone/controllers/notification_controller.dart';
import 'package:capstone/models/booking.dart';
import 'package:capstone/screens/signup/signup_screen.dart';
import 'package:capstone/view/widgets/booking_view_details_screen.dart';
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

class _TrackBookingScreenState extends State<TrackBookingScreen> {
  late final BookingController bookingController;
  late final NavigationController navigationController;
  StreamSubscription<List<Booking>>? _bookingListener;
  final Map<String, String> _previousStatuses = {};

  @override
  void initState() {
    super.initState();
    bookingController = Get.find<BookingController>();
    navigationController = Get.find<NavigationController>();

    // If user is logged in, listen to the bookings stream to detect status changes
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _bookingListener = bookingController
          .fetchUserBookings(user.uid)
          .listen(
            (bookings) {
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

  void _showStatusNotification(Booking booking) {
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
            final allBookings = docs
                .map((d) => Booking.fromSnapshot(d))
                .toList();

            // Partition bookings into tabs
            final upcoming = allBookings
                .where(
                  (b) =>
                      !_isActiveStatus(b.status) &&
                      !_isCompletedStatus(b.status),
                )
                .toList();
            final active = allBookings
                .where((b) => _isActiveStatus(b.status))
                .toList();
            final completed = allBookings
                .where((b) => _isCompletedStatus(b.status))
                .toList();

            return TabBarView(
              children: [
                _buildBookingList(context, upcoming, isDark),
                _buildBookingList(context, active, isDark),
                _buildBookingList(context, completed, isDark),
              ],
            );
          },
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

            // If booking is approved (Upcoming / Approved), show a highlighted container
            if (_isApprovedStatus(booking.status))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.green[900] : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.green[700]! : Colors.green.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Booking Approved',
                          style: AppTextStyle.withColor(
                            AppTextStyle.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            isDark ? Colors.white : Colors.green.shade800,
                          ),
                        ),
                        Text(
                          'Price: ₱${booking.price.toStringAsFixed(2)}',
                          style: AppTextStyle.withColor(
                            AppTextStyle.bodySmall,
                            isDark ? Colors.white70 : Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: isDark
                              ? Colors.white70
                              : Colors.green.shade800,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Technician: ${booking.technician ?? 'TBD'}',
                            style: AppTextStyle.withColor(
                              AppTextStyle.bodySmall,
                              isDark ? Colors.white70 : Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: isDark
                              ? Colors.white70
                              : Colors.green.shade800,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          booking.bookingDate,
                          style: AppTextStyle.withColor(
                            AppTextStyle.bodySmall,
                            isDark ? Colors.white70 : Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: isDark
                              ? Colors.white70
                              : Colors.green.shade800,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          booking.bookingTime,
                          style: AppTextStyle.withColor(
                            AppTextStyle.bodySmall,
                            isDark ? Colors.white70 : Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.build_circle,
                          size: 14,
                          color: isDark
                              ? Colors.white70
                              : Colors.green.shade800,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            booking.serviceNames.join(', '),
                            style: AppTextStyle.withColor(
                              AppTextStyle.bodySmall,
                              isDark ? Colors.white70 : Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Action button inside approved container
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.white10
                                : Colors.green.shade800,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () =>
                              Get.to(() => ViewDetailsScreen(booking: booking)),
                          child: Text(
                            'View Details',
                            style: AppTextStyle.withColor(
                              AppTextStyle.bodySmall,
                              isDark ? Colors.white : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
            if (booking.status == 'Pending' ||
                _isApprovedStatus(booking.status))
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
                    child: (_isActiveStatus(booking.status))
                        ? (booking.id == null
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildProgressSummary(
                                      booking.progress,
                                      isDark,
                                    ),
                                    const SizedBox(height: 8),
                                    ProgressTracker(
                                      currentProgress: booking.progress,
                                    ),
                                  ],
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
                                      return const SizedBox(
                                        height: 48,
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }

                                    final doc = snapshot.data!;
                                    final updated = Booking.fromSnapshot(doc);

                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildProgressSummary(
                                          updated.progress,
                                          isDark,
                                        ),
                                        const SizedBox(height: 8),
                                        ProgressTracker(
                                          currentProgress: updated.progress,
                                        ),
                                      ],
                                    );
                                  },
                                ))
                        : (_isCompletedStatus(booking.status))
                        ? _buildBookingActionButton(
                            context: context,
                            text: 'Feedback',
                            onPressed: () =>
                                _showFeedbackDialog(context, booking),
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

  Widget _buildProgressSummary(BookingProgress progress, bool isDark) {
    final steps = ['Started', 'In Progress', 'Service Complete'];
    final maxIndex = steps.length - 1;
    final idx = progress.index.clamp(0, maxIndex);
    final percent = maxIndex > 0 ? ((idx / maxIndex) * 100).round() : 0;
    final frac = maxIndex > 0 ? (idx / maxIndex) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              steps[idx],
              style: AppTextStyle.withColor(
                AppTextStyle.bodySmall,
                isDark ? Colors.white : Colors.black,
              ),
            ),
            Text(
              '$percent% ',
              style: AppTextStyle.withColor(
                AppTextStyle.bodySmall,
                isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Animate the progress bar when progress updates for a subtle visual cue
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: frac),
          duration: const Duration(milliseconds: 600),
          builder: (context, animatedValue, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: animatedValue,
                minHeight: 6,
                backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation(Color(0xFF7F1618)),
              ),
            );
          },
        ),
      ],
    );
  }

  // Show a feedback dialog for completed bookings and persist feedback to Firestore
  void _showFeedbackDialog(BuildContext context, Booking booking) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar('Not signed in', 'Please sign in to submit feedback');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        int rating = 5;
        final commentCtrl = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Leave Feedback',
                style: AppTextStyle.withColor(
                  AppTextStyle.h3,
                  Theme.of(context).textTheme.bodyLarge!.color!,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'How was the service?',
                      style: AppTextStyle.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final idx = i + 1;
                        return IconButton(
                          onPressed: () => setState(() => rating = idx),
                          icon: Icon(
                            idx <= rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: commentCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Additional comments (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    commentCtrl.dispose();
                    Get.back();
                  },
                  child: Text('Cancel', style: AppTextStyle.bodySmall),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  onPressed: () async {
                    // Show loading
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) =>
                          const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      final feedbackDoc = {
                        'bookingId': booking.id,
                        'userId': user.uid,
                        'rating': rating,
                        'comment': commentCtrl.text.trim(),
                        'createdAt': FieldValue.serverTimestamp(),
                      };

                      await FirebaseFirestore.instance
                          .collection('feedbacks')
                          .add(feedbackDoc);

                      // Optionally mark booking as having feedback
                      if (booking.id != null) {
                        await FirebaseFirestore.instance
                            .collection('bookings')
                            .doc(booking.id)
                            .update({'feedbackGiven': true});
                      }

                      commentCtrl.dispose();
                      Navigator.of(context).pop(); // close loading
                      Get.back(); // close dialog
                      Get.snackbar(
                        'Thank you',
                        'Feedback submitted successfully',
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Colors.black87,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 3),
                      );
                    } catch (e) {
                      Navigator.of(context).pop(); // close loading
                      Get.snackbar(
                        'Error',
                        'Failed to submit feedback: $e',
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    }
                  },
                  child: Text(
                    'Submit',
                    style: AppTextStyle.bodySmall.copyWith(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
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
                        return const Center(child: CircularProgressIndicator());
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
    // Define the steps shown in the image
    final List<ServiceStep> steps = [
      ServiceStep(icon: Icons.flash_on, title: 'Started'),
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
