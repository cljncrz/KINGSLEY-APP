import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:capstone/controllers/notification_controller.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

class DamageReportController extends GetxController {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;
  final isLoading = false.obs;

  // Track which reports have been notified to avoid duplicate notifications
  final Set<String> _notifiedReports = {};

  // Flag to track if we've loaded existing reports on app startup
  bool _initialLoadComplete = false;

  @override
  void onInit() {
    super.onInit();
    _listenForAdminReplies();
  }

  // Listen for admin replies in real-time
  void _listenForAdminReplies() {
    final user = _auth.currentUser;
    if (user == null) return;

    _db
        .collection('damage_reports')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
          // On first load, just mark all existing reports as "seen" to avoid duplicate notifications
          if (!_initialLoadComplete) {
            for (final doc in snapshot.docs) {
              _notifiedReports.add(doc.id);
            }
            _initialLoadComplete = true;
            debugPrint(
              '✅ Initial damage reports loaded: ${_notifiedReports.length} reports marked as seen',
            );
            return;
          }

          // After initial load, only notify on new admin responses
          for (final doc in snapshot.docs) {
            final reportId = doc.id;
            final data = doc.data();

            // Check if admin response exists and we haven't already notified
            final adminResponse = data['adminResponse'] as String?;
            if (adminResponse != null &&
                adminResponse.isNotEmpty &&
                adminResponse != 'Pending review' &&
                !_notifiedReports.contains(reportId)) {
              // Mark as notified
              _notifiedReports.add(reportId);

              // Send notification
              _notifyAdminReply(
                reportId: reportId,
                adminResponse: adminResponse,
              );
            }
          }
        });
  }

  // Notify user about admin reply
  Future<void> _notifyAdminReply({
    required String reportId,
    required String adminResponse,
  }) async {
    try {
      final notificationController = Get.find<NotificationController>();

      // Create in-app notification
      await notificationController.createNotification(
        title: 'Damage Report Update',
        body: adminResponse.length > 100
            ? '${adminResponse.substring(0, 100)}...'
            : adminResponse,
        type: 'damage_report_reply',
        bookingId: reportId,
      );

      debugPrint('✅ Notified user about admin reply for report: $reportId');
    } catch (e) {
      debugPrint('Error creating admin reply notification: $e');
    }
  }

  Future<bool> submitReport({
    required String date,
    required String location,
    required String contact,
    required String description,
    required List<XFile> images,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar("Error", "You must be logged in to submit a report.");
      return false;
    }

    // Verify user session is valid
    try {
      await user.reload();
      debugPrint('User session verified for damage report');
    } catch (e) {
      debugPrint('Error verifying session: $e');
      Get.snackbar(
        "Session Error",
        "Your session has expired. Please log out and log in again.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    isLoading.value = true;

    try {
      final imageUrls = await _uploadImages(images, user.uid);
      if (imageUrls.isEmpty) {
        Get.snackbar("Error", "Image upload failed. Please try again.");
        return false;
      }

      // Force-refresh App Check token before writing to Firestore
      try {
        final appCheckToken = await FirebaseAppCheck.instance.getToken(true);
        debugPrint('✅ App Check token obtained successfully');
      } catch (appCheckError) {
        debugPrint(
          '⚠️ Warning: App Check token error (non-fatal): $appCheckError',
        );
        // Continue anyway - not all Firebase rules require App Check
      }

      final reportData = {
        'userId': user.uid,
        'date': date,
        'location': location,
        'contact': contact,
        'description': description,
        'imageUrls': imageUrls,
        'status': 'Submitted',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // This is the critical part. We wrap it in a try-catch.
      await _db.collection('damage_reports').add(reportData);

      // Create a notification for the user
      await Get.find<NotificationController>().createNotification(
        title: 'Damage Report Submitted',
        body: 'We have received your damage report and will review it shortly.',
      );

      return true;
    } on FirebaseException catch (e) {
      // This will now catch the permission error from Firestore if App Check fails.
      debugPrint('Firestore Error: ${e.code} - ${e.message}');
      Get.snackbar(
        "Submission Failed",
        "Could not save the report. Please ensure your app is up-to-date and try again. (${e.code})",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Stream<QuerySnapshot> getUserReports() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in');
    }
    // Note: This query requires a composite index on userId and createdAt
    // Create the index at: Firebase Console > Firestore > Indexes
    // Or click the link in the error message to auto-create it
    return _db
        .collection('damage_reports')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<List<String>> _uploadImages(List<XFile> images, String userId) async {
    final List<String> imageUrls = [];

    for (int i = 0; i < images.length; i++) {
      try {
        final image = images[i];
        debugPrint('Uploading image ${i + 1}/${images.length}: ${image.name}');

        // Refresh auth token BEFORE each upload
        final user = _auth.currentUser;
        if (user != null) {
          try {
            await user.reload();
            await user.getIdToken(true);
            debugPrint('✅ Auth token refreshed before image ${i + 1} upload.');
          } catch (e) {
            debugPrint('❌ Token refresh failed for image ${i + 1}: $e');
            Get.snackbar(
              "Authentication Error",
              "Session expired. Please log out and log in again.",
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
            continue;
          }
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filename =
            'damage_reports/$userId/${timestamp}_${i}_${image.name}';
        final ref = _storage.ref(filename);

        debugPrint('Uploading to: ${ref.fullPath}');

        final file = File(image.path);
        if (!await file.exists()) {
          debugPrint('❌ File does not exist: ${image.path}');
          continue;
        }

        // Upload with metadata
        final uploadTask = await ref.putFile(
          file,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'uploadedBy': userId,
              'originalName': image.name,
              'timestamp': timestamp.toString(),
            },
          ),
        );

        final downloadUrl = await uploadTask.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
        debugPrint('Image ${i + 1} uploaded: $downloadUrl');
      } on FirebaseException catch (e) {
        debugPrint('Error uploading image ${i + 1}: $e');
        if (e.code == 'unauthenticated' ||
            e.message?.contains('App Check token is invalid') == true) {
          Get.snackbar(
            "Upload Failed",
            "Authentication or App Check token invalid. Please log out and log in again.",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
        // Continue with other images instead of failing completely
      }
    }

    return imageUrls;
  }
}
