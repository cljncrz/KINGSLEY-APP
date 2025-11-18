import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:capstone/models/service_feedback.dart';
import 'package:capstone/models/technician_feedback.dart';
import 'package:capstone/controllers/notification_controller.dart';

class FeedbackController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription? _authSubscription;
  StreamSubscription? _serviceFeedbackSubscription;
  StreamSubscription? _techFeedbackSubscription;

  final RxMap<String, ServiceFeedback> serviceFeedbacks =
      <String, ServiceFeedback>{}.obs;
  final RxMap<String, TechnicianFeedback> technicianFeedbacks =
      <String, TechnicianFeedback>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _authSubscription = _auth.authStateChanges().listen((user) {
      _serviceFeedbackSubscription?.cancel();
      _techFeedbackSubscription?.cancel();
      if (user != null) {
        _serviceFeedbackSubscription = _db
            .collection('feedbacks')
            .where('userId', isEqualTo: user.uid)
            .snapshots()
            .listen((snapshot) {
              for (var doc in snapshot.docs) {
                final feedback = ServiceFeedback.fromSnapshot(doc);
                serviceFeedbacks[feedback.bookingId] = feedback;
              }
            });
        _techFeedbackSubscription = _db
            .collection('technician_feedbacks')
            .where('userId', isEqualTo: user.uid)
            .snapshots()
            .listen((snapshot) {
              for (var doc in snapshot.docs) {
                final feedback = TechnicianFeedback.fromSnapshot(doc);
                technicianFeedbacks[feedback.bookingId] = feedback;
              }
            });
      } else {
        serviceFeedbacks.clear();
        technicianFeedbacks.clear();
      }
    });
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    _serviceFeedbackSubscription?.cancel();
    _techFeedbackSubscription?.cancel();
    super.onClose();
  }

  Future<bool> submitFeedback({
    required String bookingId,
    required double rating,
    required String comment,
  }) async {
    if (bookingId.isEmpty) {
      Get.snackbar('Error', 'Booking ID is missing.');
      return false;
    }

    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar("Error", "You must be logged in to give feedback.");
      return false;
    }

    try {
      // Create a new document in the 'feedbacks' collection.
      await _db.collection('feedbacks').add({
        'userId': user.uid,
        'bookingId': bookingId,
        'rating': rating,
        'comment': comment,
        'feedbackCreatedAt': FieldValue.serverTimestamp(),
      });

      // Create a notification for the user
      await Get.find<NotificationController>().createNotification(
        title: 'Feedback Received!',
        body: 'Thank you for sharing your feedback with us.',
        bookingId: bookingId,
      );

      // Note: If you need to update the booking document to mark that feedback
      // has been submitted, it's best to do this via a Cloud Function triggered
      // by the creation of a new feedback document. This is more secure than
      // This update should be handled by a server-side trigger (e.g., Cloud Function)
      // to avoid giving clients broad write permissions on the 'bookings' collection.

      Get.snackbar(
        'Thank You!',
        'Your feedback has been submitted.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    } on FirebaseException catch (e) {
      debugPrint('Error submitting feedback: $e');
      Get.snackbar('Error', 'Failed to submit feedback: ${e.message}');
      return false;
    }
  }

  /// Submits feedback for a specific technician related to a booking.
  Future<void> submitTechnicianFeedback({
    required String bookingId,
    required String technicianName,
    required double rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar("Error", "You must be logged in to give feedback.");
      return;
    }

    try {
      // Create a new technician feedback document
      final feedback = TechnicianFeedback(
        id: '', // Firestore will generate this
        bookingId: bookingId,
        userId: user.uid,
        technicianName: technicianName,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      );

      // Add to the 'technician_feedbacks' collection
      await _db.collection('technician_feedbacks').add(feedback.toJson());

      // Create a notification for the user
      await Get.find<NotificationController>().createNotification(
        title: 'Technician Feedback Received!',
        body: 'Thank you for rating $technicianName.',
        bookingId: bookingId,
      );

      Get.snackbar(
        "Success",
        "Thank you for rating the technician!",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to submit technician feedback. Please try again.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      debugPrint("Error submitting technician feedback: $e");
    }
  }
}
