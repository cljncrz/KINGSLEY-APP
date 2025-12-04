import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:capstone/controllers/notification_controller.dart';

class DamageReportController extends GetxController {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;
  final isLoading = false.obs;

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

        // Refresh the token BEFORE each upload
        final user = _auth.currentUser;
        if (user != null) {
          try {
            await user.reload();
            await user.getIdToken(true); // Force refresh the token
            debugPrint(
              '✅ Auth token force-refreshed successfully before image upload.',
            );
          } catch (e) {
            debugPrint(
              '❌ Critical Error: Failed to refresh auth token before image upload: $e',
            );
            Get.snackbar(
              "Authentication Error",
              "Your session is invalid. Please log out and sign in again.",
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
            continue; // Skip this image if token refresh fails
          }
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filename =
            'damage_reports/$userId/${timestamp}_${i}_${image.name}';
        final ref = _storage.ref(filename);

        debugPrint('Uploading to: ${ref.fullPath}');

        final file = File(image.path);
        if (!await file.exists()) {
          debugPrint('File does not exist: ${image.path}');
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
