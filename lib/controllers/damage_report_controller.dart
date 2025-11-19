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
    for (var image in images) {
      try {
        final ref = _storage.ref(
          'damage_reports/$userId/${DateTime.now().millisecondsSinceEpoch}_${image.name}',
        );
        final uploadTask = await ref.putFile(File(image.path));
        final url = await uploadTask.ref.getDownloadURL();
        imageUrls.add(url);
      } on FirebaseException catch (e) {
        debugPrint(
          'Storage Error during image upload: ${e.code} - ${e.message}',
        );
        Get.snackbar(
          "Image Upload Failed",
          "Could not upload an image. Please check your connection and try again. (${e.code})",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        // If one image fails, we stop and return what we have, which will be empty
        // or partially filled, causing the submitReport to fail gracefully.
        return [];
      }
    }
    return imageUrls;
  }
}
