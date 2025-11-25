import 'package:capstone/models/booking.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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
  Future<void> addBooking(Booking booking, {String? paymentMethod}) async {
    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar("Error", "You must be logged in to make a booking.");
      return;
    }

    try {
      // Generate a custom ID using timestamp (e.g. BK1234567)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final customId = 'UID${timestamp.toString().substring(5)}';

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

      // Create payment notification for all payment methods
      if (paymentMethod != null) {
        await _createPaymentNotification(booking, customId);
      }
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

  /// Creates a notification for payment confirmation.
  Future<void> _createPaymentNotification(
    Booking booking,
    String bookingId,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _db.collection('users').doc(user.uid).collection('notifications').add({
        'title': 'Payment Confirmed!',
        'body':
            'Your payment of ₱${booking.price.toStringAsFixed(2)} for ${booking.serviceNames.join(', ')} has been confirmed.',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'payment_confirmed',
        'bookingId': bookingId,
      });
    } catch (e) {
      // Silently fail or log to console. We don't want to block the user flow.
      debugPrint("Error creating payment notification: $e");
    }
  }

  /// Cancels an existing booking.
  Future<void> cancelBooking({
    required String bookingId,
    required String reason,
    String? comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar("Error", "You must be logged in to cancel a booking.");
      return;
    }
    final bookingRef = _db.collection('bookings').doc(bookingId);

    try {
      await _db.runTransaction((tx) async {
        final bookingSnap = await tx.get(bookingRef);

        if (!bookingSnap.exists) {
          throw FirebaseException(
            plugin: 'firestore',
            code: 'not-found',
            message: 'Booking not found.',
          );
        }

        final bookingData = bookingSnap.data();
        final ownerId = bookingData?['userId']?.toString();
        final currentStatus =
            bookingData?['status']?.toString().toLowerCase() ?? '';

        // Verify the user owns this booking
        if (ownerId != user.uid) {
          throw FirebaseException(
            plugin: 'firestore',
            code: 'permission-denied',
            message: 'You are not the owner of this booking.',
          );
        }

        // Only allow cancellation of pending bookings
        if (!currentStatus.contains('pend')) {
          throw FirebaseException(
            plugin: 'firestore',
            code: 'failed-precondition',
            message: 'Only pending bookings can be cancelled.',
          );
        }

        // Update the booking with cancellation details
        tx.update(bookingRef, {
          'status': 'Cancelled',
          'cancellationReason': reason,
          'cancellationComment': comment ?? '',
          'cancelledAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Create cancellation notification
      await _createCancellationNotification(bookingId);

      Get.snackbar(
        "Success",
        "Your booking has been cancelled.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      if (e is FirebaseException) {
        debugPrint('FirebaseException (${e.code}): ${e.message}');
        Get.snackbar(
          "Error",
          e.message ?? "Failed to cancel booking.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      Get.snackbar(
        "Error",
        "Failed to cancel booking. Please try again.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      debugPrint("Error cancelling booking: $e");
    }
  }

  /// Creates a notification for booking cancellation.
  Future<void> _createCancellationNotification(String bookingId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
            'title': 'Booking Cancelled',
            'body': 'Your booking has been successfully cancelled.',
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
            'type': 'booking_cancelled',
            'bookingId': bookingId,
          });
    } catch (e) {
      debugPrint("Error creating cancellation notification: $e");
    }
  }

  /// Reschedules an existing booking.
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
    final bookingRef = _db.collection('bookings').doc(bookingId);

    try {
      await _db.runTransaction((tx) async {
        final bookingSnap = await tx.get(bookingRef);

        if (!bookingSnap.exists) {
          throw FirebaseException(
            plugin: 'firestore',
            code: 'not-found',
            message: 'Booking not found.',
          );
        }

        final bookingData = bookingSnap.data();
        final ownerId = bookingData?['userId']?.toString();
        final currentStatus =
            bookingData?['status']?.toString().toLowerCase() ?? '';

        // These checks mirror the security rules for a better user experience.
        if (ownerId != user.uid) {
          throw FirebaseException(
            plugin: 'firestore',
            code: 'permission-denied',
            message: 'You are not the owner of this booking.',
          );
        }

        if (!currentStatus.contains('pend')) {
          throw FirebaseException(
            plugin: 'firestore',
            code: 'failed-precondition',
            message: 'Booking is not in a pending state.',
          );
        }

        // Update the booking directly with the new information and status.
        tx.update(bookingRef, {
          'bookingDate': DateFormat('yyyy-MM-dd').format(newDate),
          'bookingTime': newTime,
          'reason': reason,
          'status': 'Rescheduled',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      // Surface FirebaseException details to make debugging easier.
      if (e is FirebaseException) {
        debugPrint('FirebaseException (${e.code}): ${e.message}');
        Get.snackbar(
          "Permission denied",
          "You don't have permission to perform this action. This may be because the booking is no longer pending. Please refresh.",
        );
        return;
      }

      Get.snackbar("Error", "Failed to request reschedule. Please try again.");
      debugPrint("Error rescheduling booking: $e");
    }
  }

  /// Deletes a booking from the Firestore database.
  Future<void> deleteBooking(String bookingId) async {
    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar("Error", "You must be logged in to perform this action.");
      return;
    }

    try {
      await _db.collection('bookings').doc(bookingId).delete();

      Get.snackbar(
        "Success",
        "Booking history has been deleted.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to delete booking. Please try again.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      debugPrint("Error deleting booking: $e");
    }
  }
}
