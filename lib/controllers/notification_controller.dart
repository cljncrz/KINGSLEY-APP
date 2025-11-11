import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'dart:async';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final Timestamp createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
  });

  factory AppNotification.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      isRead: data['isRead'] ?? false,
    );
  }
}

class NotificationController extends GetxController {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final RxList<AppNotification> notifications = <AppNotification>[].obs;

  // Computed property to check if there are any unread notifications.
  bool get hasUnreadNotifications => notifications.any((n) => !n.isRead);

  // Computed property for the count of unread notifications.
  int get unreadNotificationCount =>
      notifications.where((n) => !n.isRead).length;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<List<AppNotification>>? _notificationSubscription;

  @override
  void onInit() {
    super.onInit();
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      _notificationSubscription?.cancel(); // Cancel previous stream
      if (user != null) {
        _notificationSubscription = fetchUserNotifications(user.uid).listen((
          newNotifications,
        ) {
          notifications.value = newNotifications;
        });
      } else {
        // If user logs out, clear the list. The stream is already cancelled.
        notifications.clear();
      }
    });
  }

  @override
  void onClose() {
    // Cancel both subscriptions to prevent memory leaks.
    _authSubscription?.cancel();
    _notificationSubscription?.cancel();
    super.onClose();
  }

  Stream<List<AppNotification>> fetchUserNotifications(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppNotification.fromSnapshot(doc))
              .toList(),
        );
  }

  /// Marks all unread notifications as read for the current user.
  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final batch = _db.batch();
      final notificationsToUpdate = notifications
          .where((n) => !n.isRead)
          .toList();

      if (notificationsToUpdate.isEmpty) {
        // Optionally inform the user that there's nothing to mark as read.
        return;
      }

      for (final notification in notificationsToUpdate) {
        final docRef = _db
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(notification.id);
        batch.update(docRef, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      Get.snackbar('Error', 'Could not mark notifications as read.');
    }
  }

  /// Deletes a specific notification for the current user.
  Future<void> deleteNotification(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();
      Get.snackbar(
        'Notification Removed',
        'The notification has been deleted.',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar('Error', 'Could not delete the notification.');
    }
  }
}
