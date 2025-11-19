import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone/models/chat_message.dart';
import 'package:capstone/models/chat_room.dart';

class ChatController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<ChatRoom> chatRooms = <ChatRoom>[].obs;
  final RxBool isLoading = false.obs;

  StreamSubscription? _chatRoomsSubscription;

  @override
  void onInit() {
    super.onInit();
    _listenToChatRooms();
  }

  @override
  void onClose() {
    _chatRoomsSubscription?.cancel();
    super.onClose();
  }

  /// Listen to chat rooms for the current user in real-time
  void _listenToChatRooms() {
    final user = _auth.currentUser;
    if (user == null) {
      chatRooms.clear();
      return;
    }

    isLoading.value = true;

    // Listen to chat rooms where the user is a participant
    _chatRoomsSubscription = _db
        .collection('chat_rooms')
        .where('userId', isEqualTo: user.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            chatRooms.value = snapshot.docs
                .map((doc) => ChatRoom.fromFirestore(doc))
                .toList();
            isLoading.value = false;
          },
          onError: (error) {
            debugPrint('Error listening to chat rooms: $error');
            isLoading.value = false;
          },
        );
  }

  /// Get or create a chat room for the current user
  Future<String?> getOrCreateChatRoom() async {
    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar(
        'Error',
        'You must be logged in to chat',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }

    try {
      // Check if chat room already exists
      final existingRooms = await _db
          .collection('chat_rooms')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (existingRooms.docs.isNotEmpty) {
        return existingRooms.docs.first.id;
      }

      // Get user data from Firestore
      final userDoc = await _db.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // Create new chat room
      final chatRoomRef = await _db.collection('chat_rooms').add({
        'userId': user.uid,
        'userName': userData['fullName'] ?? 'Unknown User',
        'userEmail': userData['email'] ?? user.email ?? '',
        'lastMessage': 'Chat started',
        'lastMessageSenderId': user.uid,
        'lastMessageSenderRole': 'user',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return chatRoomRef.id;
    } catch (e) {
      debugPrint('Error creating chat room: $e');
      Get.snackbar(
        'Error',
        'Failed to create chat room',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  /// Send a message in a chat room
  Future<bool> sendMessage({
    required String chatRoomId,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    if (text.trim().isEmpty) return false;

    try {
      // Get user data
      final userDoc = await _db.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      final userName = userData['fullName'] ?? 'Unknown User';

      // Create the message
      final messageData = ChatMessage(
        id: '', // Firestore will generate this
        chatRoomId: chatRoomId,
        senderId: user.uid,
        senderName: userName,
        senderRole: 'user',
        text: text.trim(),
        createdAt: DateTime.now(),
        isRead: false,
      ).toFirestore();

      // Add message to subcollection
      await _db
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(messageData);

      // Update chat room's last message
      await _db.collection('chat_rooms').doc(chatRoomId).update({
        'lastMessage': text.trim(),
        'lastMessageSenderId': user.uid,
        'lastMessageSenderRole': 'user',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      Get.snackbar(
        'Error',
        'Failed to send message',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  /// Get messages stream for a specific chat room
  Stream<List<ChatMessage>> getMessagesStream(String chatRoomId) {
    return _db
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList(),
        );
  }

  /// Mark messages as read when user opens the chat
  Future<void> markMessagesAsRead(String chatRoomId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Get all unread messages from admin
      final unreadMessages = await _db
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .where('senderRole', isEqualTo: 'admin')
          .get();

      // Mark each message as read
      final batch = _db.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      // Reset unread count in chat room
      await _db.collection('chat_rooms').doc(chatRoomId).update({
        'unreadCount': 0,
      });
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  /// Check if user has any unread messages
  bool get hasUnreadMessages {
    return chatRooms.any((room) => room.hasUnreadMessages);
  }

  /// Get total unread message count
  int get totalUnreadCount {
    return chatRooms.fold(0, (sum, room) => sum + room.unreadCount);
  }
}
