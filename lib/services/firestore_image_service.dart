import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Service for storing and retrieving base64 encoded images in Firestore
///
/// Advantages:
/// - No need for separate Firebase Storage service
/// - Images stored directly with user data
/// - Simpler security rules
/// - Good for small to medium images (< 1MB)
///
/// Disadvantages:
/// - Firestore 1MB document limit
/// - Slower for large images
/// - More bandwidth per read
class FirestoreImageService {
  static final FirestoreImageService _instance =
      FirestoreImageService._internal();

  factory FirestoreImageService() {
    return _instance;
  }

  FirestoreImageService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload profile image as base64 to Firestore
  ///
  /// Example:
  /// ```dart
  /// final service = FirestoreImageService();
  /// final success = await service.uploadProfileImageBase64(imageFile);
  /// if (success) {
  ///   print('Image uploaded successfully!');
  /// }
  /// ```
  Future<bool> uploadProfileImageBase64(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('Error: No user is currently logged in');
        return false;
      }

      debugPrint('Starting base64 profile image upload...');

      // Read file as bytes
      final bytes = await imageFile.readAsBytes();

      // Convert bytes to base64 string
      final base64String = base64Encode(bytes);

      debugPrint('Image size: ${(bytes.length / 1024).toStringAsFixed(2)} KB');
      debugPrint('Base64 string length: ${base64String.length} characters');

      // Upload to Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'profileImageBase64': base64String,
        'profileImageUpdatedAt': FieldValue.serverTimestamp(),
        'profileImageSize': bytes.length, // Store size for reference
      });

      debugPrint('Profile image uploaded to Firestore successfully');
      return true;
    } on FirebaseException catch (e) {
      debugPrint(
        'Firebase Error uploading profile image: ${e.code} - ${e.message}',
      );
      return false;
    } catch (e) {
      debugPrint('Unexpected error uploading profile image: $e');
      return false;
    }
  }

  /// Upload damage report images as base64 to Firestore
  ///
  /// Example:
  /// ```dart
  /// final service = FirestoreImageService();
  /// final imageIds = await service.uploadDamageReportImagesBase64(
  ///   imageFiles: [file1, file2],
  ///   reportId: 'report123',
  /// );
  /// print('Uploaded images: $imageIds');
  /// ```
  Future<List<String>> uploadDamageReportImagesBase64({
    required List<File> imageFiles,
    required String reportId,
  }) async {
    final uploadedImageIds = <String>[];

    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('Error: No user is currently logged in');
        return [];
      }

      debugPrint('Starting base64 damage report image upload for $reportId...');

      for (int i = 0; i < imageFiles.length; i++) {
        try {
          final imageFile = imageFiles[i];

          // Read file as bytes
          final bytes = await imageFile.readAsBytes();

          // Convert bytes to base64 string
          final base64String = base64Encode(bytes);

          debugPrint(
            'Image ${i + 1} size: ${(bytes.length / 1024).toStringAsFixed(2)} KB',
          );

          // Generate unique ID for this image
          final imageId =
              '${DateTime.now().millisecondsSinceEpoch}_${i}_${DateTime.now().microsecond}';

          // Create image document in subcollection
          await _firestore
              .collection('damage_reports')
              .doc(reportId)
              .collection('images')
              .doc(imageId)
              .set({
                'imageBase64': base64String,
                'imageIndex': i,
                'uploadedAt': FieldValue.serverTimestamp(),
                'imageSize': bytes.length,
                'imageName': imageFile.path.split('/').last,
              });

          uploadedImageIds.add(imageId);
          debugPrint('Image ${i + 1} uploaded successfully with ID: $imageId');
        } catch (e) {
          debugPrint('Error uploading image ${i + 1}: $e');
          // Continue with next image instead of failing completely
        }
      }

      // Update report with image count
      if (uploadedImageIds.isNotEmpty) {
        await _firestore.collection('damage_reports').doc(reportId).update({
          'imageCount': uploadedImageIds.length,
          'imagesUpdatedAt': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('Uploaded ${uploadedImageIds.length} images total');
      return uploadedImageIds;
    } on FirebaseException catch (e) {
      debugPrint(
        'Firebase Error uploading damage report images: ${e.code} - ${e.message}',
      );
      return uploadedImageIds;
    } catch (e) {
      debugPrint('Unexpected error uploading damage report images: $e');
      return uploadedImageIds;
    }
  }

  /// Retrieve profile image as base64 from Firestore
  ///
  /// Example:
  /// ```dart
  /// final service = FirestoreImageService();
  /// final base64String = await service.getProfileImageBase64(userId);
  /// if (base64String != null) {
  ///   // Convert back to image
  ///   final bytes = base64Decode(base64String);
  /// }
  /// ```
  Future<String?> getProfileImageBase64(String userId) async {
    try {
      debugPrint('Fetching profile image for user: $userId');

      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists && doc.data()!.containsKey('profileImageBase64')) {
        final base64String = doc.data()!['profileImageBase64'] as String;
        debugPrint(
          'Profile image retrieved successfully (${(base64String.length / 1024).toStringAsFixed(2)} KB)',
        );
        return base64String;
      } else {
        debugPrint('No profile image found for user: $userId');
        return null;
      }
    } on FirebaseException catch (e) {
      debugPrint(
        'Firebase Error retrieving profile image: ${e.code} - ${e.message}',
      );
      return null;
    } catch (e) {
      debugPrint('Unexpected error retrieving profile image: $e');
      return null;
    }
  }

  /// Retrieve all damage report images as base64 from Firestore
  ///
  /// Example:
  /// ```dart
  /// final service = FirestoreImageService();
  /// final images = await service.getDamageReportImagesBase64('report123');
  /// for (var image in images) {
  ///   final bytes = base64Decode(image['imageBase64']);
  ///   // Convert to Image widget
  /// }
  /// ```
  Future<List<Map<String, dynamic>>> getDamageReportImagesBase64(
    String reportId,
  ) async {
    try {
      debugPrint('Fetching images for damage report: $reportId');

      final snapshot = await _firestore
          .collection('damage_reports')
          .doc(reportId)
          .collection('images')
          .orderBy('imageIndex')
          .get();

      final images = snapshot.docs.map((doc) => doc.data()).toList();

      debugPrint('Retrieved ${images.length} images for report: $reportId');
      return images;
    } on FirebaseException catch (e) {
      debugPrint(
        'Firebase Error retrieving damage report images: ${e.code} - ${e.message}',
      );
      return [];
    } catch (e) {
      debugPrint('Unexpected error retrieving damage report images: $e');
      return [];
    }
  }

  /// Delete profile image from Firestore
  Future<bool> deleteProfileImage() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore.collection('users').doc(user.uid).update({
        'profileImageBase64': FieldValue.delete(),
        'profileImageUpdatedAt': FieldValue.delete(),
        'profileImageSize': FieldValue.delete(),
      });

      debugPrint('Profile image deleted successfully');
      return true;
    } catch (e) {
      debugPrint('Error deleting profile image: $e');
      return false;
    }
  }

  /// Delete all images for a damage report
  Future<bool> deleteDamageReportImages(String reportId) async {
    try {
      final snapshot = await _firestore
          .collection('damage_reports')
          .doc(reportId)
          .collection('images')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      // Update report
      await _firestore.collection('damage_reports').doc(reportId).update({
        'imageCount': 0,
        'imagesUpdatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('All images deleted for report: $reportId');
      return true;
    } catch (e) {
      debugPrint('Error deleting damage report images: $e');
      return false;
    }
  }

  /// Convert base64 string to Image widget
  ///
  /// Example:
  /// ```dart
  /// final base64String = '...';
  /// final imageWidget = FirestoreImageService.base64ToImage(base64String);
  /// ```
  static Image base64ToImage(String base64String) {
    final bytes = base64Decode(base64String);
    return Image.memory(bytes);
  }

  /// Convert base64 string to Image provider
  static ImageProvider<Object> base64ToImageProvider(String base64String) {
    final bytes = base64Decode(base64String);
    return MemoryImage(bytes);
  }

  /// Get estimated size of base64 string in MB
  static double getBase64SizeMB(String base64String) {
    return base64String.length / (1024 * 1024);
  }

  /// Check if base64 string is within size limit
  static bool isWithinSizeLimit(String base64String, {double maxSizeMB = 1.0}) {
    return getBase64SizeMB(base64String) <= maxSizeMB;
  }
}
