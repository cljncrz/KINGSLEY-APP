import 'package:capstone/models/booking.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

class BookingController extends GetxController {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // The main reactive list that holds all bookings for the current user.
  final RxList<Booking> _bookings = <Booking>[].obs;

  // Computed lists that will automatically update when _bookings changes.
  // Flexible matching for statuses to tolerate different admin strings.
  List<Booking> get upcomingBookings => _bookings.where((b) {
    final s = b.status.toLowerCase();
    return s.contains('pend') || s.contains('up') || s.contains('approv');
  }).toList();

  List<Booking> get activeBookings => _bookings.where((b) {
    final s = b.status.toLowerCase();
    return s.contains('active');
  }).toList();

  List<Booking> get completedBookings => _bookings.where((b) {
    final s = b.status.toLowerCase();
    return s.contains('complete') || s.contains('completed');
  }).toList();

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<List<Booking>>? _bookingSubscription;

  @override
  void onInit() {
    super.onInit();
    // Listen to authentication state changes.
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      _bookingSubscription?.cancel(); // Cancel any existing booking stream
      if (user != null) {
        // If user is logged in, bind the stream of their bookings.
        _bookingSubscription = fetchUserBookings(user.uid).listen(
          (bookings) {
            _bookings.value = bookings;
          },
          onError: (error) {
            // Log the error to the debug console.
            debugPrint("Error fetching bookings: $error");
            _bookings.clear(); // Clear bookings on error
          },
        );
      } else {
        // If user is logged out, clear the bookings list.
        _bookings.clear();
      }
    });
  }

  @override
  void onClose() {
    // Cancel both subscriptions to prevent memory leaks.
    _authSubscription?.cancel();
    _bookingSubscription?.cancel();
    super.onClose();
  }

  /// Fetches a real-time stream of bookings for a specific user.
  Stream<List<Booking>> fetchUserBookings(String userId) {
    return _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('bookingDate', descending: true)
        .orderBy('bookingTime', descending: true)
        .orderBy('plateNumber', descending: true)
        .orderBy('carName', descending: true)
        .orderBy('carType', descending: true)
        .orderBy('phoneNumber', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Booking.fromSnapshot(doc)).toList(),
        )
        .handleError((error) {
          debugPrint("Firestore Error: Composite index likely missing. $error");
          Get.snackbar(
            "Error",
            "Could not load bookings. Check database configuration.",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          // Return an empty list or handle the error as appropriate
          return <Booking>[];
        });
  }

  /// Adds a new booking to the Firestore database.
  Future<void> addBooking(Booking booking) async {
    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar("Error", "You must be logged in to make a booking.");
      return;
    }

    try {
      // Generate a custom ID using timestamp (e.g. BK1234567)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final customId = 'BK${timestamp.toString().substring(5)}';

      // Create booking with custom ID
      final bookingRef = _db.collection('bookings').doc(customId);
      final bookingData = booking.copyWith(id: customId).toJson();
      bookingData['createdAt'] = FieldValue.serverTimestamp();
      bookingData['userId'] = user.uid;

      await bookingRef.set(bookingData);

      Get.snackbar(
        "Success",
        "Your booking has been confirmed.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      await _createBookingNotification(booking, customId);
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to create booking. Please try again.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      debugPrint("Error creating booking: $e");
    }
  }

  /// Creates a notification for a new booking.
  Future<void> _createBookingNotification(
    Booking booking,
    String bookingId,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _db.collection('users').doc(user.uid).collection('notifications').add({
        'title': 'Booking Successful!',
        'body':
            'Your booking for ${booking.serviceNames.join(', ')} has been successful.',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'booking_successful',
        'bookingId': bookingId,
      });
    } catch (e) {
      // Silently fail or log to console. We don't want to block the user flow.
      debugPrint("Error creating notification: $e");
    }
  }

  /// Submits a request to reschedule an existing booking.
  Future<void> rescheduleBooking({
    required String bookingId,
    required DateTime newDate,
    required String newTime,
    required String reason,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar("Error", "You must be logged in to reschedule a booking.");
      return;
    }

    try {
      // 1. Add a reschedule request to a new collection for admin review.
      final rescheduleRef = _db.collection('rescheduleRequests').doc();
      await rescheduleRef.set({
        'bookingId': bookingId,
        'userId': user.uid,
        'newDate': Timestamp.fromDate(newDate),
        'newTime': newTime,
        'reason': reason,
        'status': 'pending', // Admin will review this request.
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Update the original booking's status to show a reschedule is pending.
      await _db.collection('bookings').doc(bookingId).update({
        'status': 'Reschedule Pending',
      });

      // The success screen is handled in the UI, so no snackbar here.
    } catch (e) {
      Get.snackbar("Error", "Failed to request reschedule. Please try again.");
      debugPrint("Error rescheduling booking: $e");
    }
  }
}
