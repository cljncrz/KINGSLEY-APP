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
  final Map<String, StreamSubscription> _messageSubscriptions = {};

  @override
  void onInit() {
    super.onInit();
    _listenToChatRooms();
  }

  @override
  void onClose() {
    _chatRoomsSubscription?.cancel();
    // Cancel all message subscriptions
    for (var subscription in _messageSubscriptions.values) {
      subscription.cancel();
    }
    _messageSubscriptions.clear();
    super.onClose();
  }

  /// Listen to chat rooms for the current user in real-time
  void _listenToChatRooms() {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ No user logged in - cannot listen to chat rooms');
      chatRooms.clear();
      return;
    }

    debugPrint('👤 Current user: ${user.uid}');
    debugPrint('📧 Email: ${user.email}');
    debugPrint('✅ Email verified: ${user.emailVerified}');

    isLoading.value = true;

    // Listen to chat rooms where the user is a participant
    try {
      _chatRoomsSubscription = _db
          .collection('chat_rooms')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen(
            (snapshot) {
              debugPrint('✅ Chat rooms loaded: ${snapshot.docs.length}');

              // Sort by lastMessageTime locally if needed
              final rooms = snapshot.docs
                  .map((doc) => ChatRoom.fromFirestore(doc))
                  .toList();

              // Sort by lastMessageTime descending
              rooms.sort(
                (a, b) => b.lastMessageTime.compareTo(a.lastMessageTime),
              );

              chatRooms.value = rooms;
              isLoading.value = false;

              debugPrint('📋 Chat rooms after sorting: ${chatRooms.length}');
              for (var room in chatRooms) {
                debugPrint('   - ${room.userName}');
                debugPrint('     Last Message: "${room.lastMessage}"');
                debugPrint('     Sender Role: ${room.lastMessageSenderRole}');
                debugPrint('     Last Message Time: ${room.lastMessageTime}');
              }

              // Set up listeners for admin messages in each chat room
              for (var doc in snapshot.docs) {
                _listenToAdminMessagesInChatRoom(doc.id);
              }
            },
            onError: (error) {
              debugPrint('❌ Error listening to chat rooms: $error');
              debugPrint('❌ Error type: ${error.runtimeType}');
              debugPrint('❌ Stack trace: ${StackTrace.current}');
              isLoading.value = false;
            },
          );
    } catch (e) {
      debugPrint('❌ Exception in _listenToChatRooms: $e');
      isLoading.value = false;
    }
  }

  /// Listen for new admin messages in a chat room and update chat_rooms collection
  void _listenToAdminMessagesInChatRoom(String chatRoomId) {
    // Only set up listener once per chat room
    if (_messageSubscriptions.containsKey(chatRoomId)) {
      return;
    }

    _messageSubscriptions[chatRoomId] = _db
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('senderRole', isEqualTo: 'admin')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.docs.isNotEmpty) {
              final adminMessage = ChatMessage.fromFirestore(
                snapshot.docs.first,
              );
              debugPrint(
                '🔔 New admin message detected in chat room: $chatRoomId',
              );
              debugPrint('📝 Message: ${adminMessage.text}');

              // Update the chat room document to reflect the admin message
              _updateChatRoomWithAdminMessage(chatRoomId, adminMessage);
            }
          },
          onError: (error) {
            debugPrint(
              '❌ Error listening to admin messages in $chatRoomId: $error',
            );
          },
        );
  }

  /// Update chat room document with latest admin message
  Future<void> _updateChatRoomWithAdminMessage(
    String chatRoomId,
    ChatMessage adminMessage,
  ) async {
    try {
      // Get current chat room to check if this message is newer
      final chatRoomDoc = await _db
          .collection('chat_rooms')
          .doc(chatRoomId)
          .get();

      if (chatRoomDoc.exists) {
        final currentLastMessageTime =
            (chatRoomDoc.data()?['lastMessageTime'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);

        // Only update if this admin message is newer than the current last message
        if (adminMessage.createdAt.isAfter(currentLastMessageTime)) {
          await _db.collection('chat_rooms').doc(chatRoomId).update({
            'lastMessage': adminMessage.text,
            'lastMessageSenderId': adminMessage.senderId,
            'lastMessageSenderRole': 'admin',
            'lastMessageTime': Timestamp.fromDate(adminMessage.createdAt),
            'unreadCount': (chatRoomDoc.data()?['unreadCount'] ?? 0) + 1,
          });

          debugPrint(
            '✅ Updated chat room $chatRoomId with admin message: ${adminMessage.text}',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error updating chat room with admin message: $e');
    }
  }

  /// Get or create a chat room for the current user
  Future<String?> getOrCreateChatRoom() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ No user logged in - cannot create chat room');
      Get.snackbar(
        'Error',
        'You must be logged in to chat',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }

    debugPrint('🔨 Creating/getting chat room for user: ${user.uid}');
    debugPrint('📧 User email: ${user.email}');

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
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ Firestore Error creating chat room: ${e.code} - ${e.message}',
      );
      Get.snackbar(
        'Error',
        'Failed to create chat room. Please check your connection and try again. (${e.code})',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    } catch (e) {
      debugPrint('❌ Unexpected error creating chat room: $e');
      Get.snackbar('Error', 'An unexpected error occurred.');
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

      debugPrint('✅ Message sent and lastMessage updated: "${text.trim()}"');

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
        .map((snapshot) {
          debugPrint('📨 Messages snapshot: ${snapshot.docs.length} messages');
          final messages = <ChatMessage>[];

          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();
              debugPrint('📄 Raw doc data: $data');

              // Check if document has data
              if (data.isEmpty) {
                debugPrint('❌ Document ${doc.id} has no data');
                continue;
              }

              final message = ChatMessage.fromFirestore(doc);
              messages.add(message);
              debugPrint(
                '✅ Message: ${message.senderRole} - "${message.text}" at ${message.createdAt}',
              );
            } catch (e) {
              debugPrint('❌ Error parsing message ${doc.id}: $e');
              try {
                debugPrint('📝 Raw data: ${doc.data()}');
              } catch (e2) {
                debugPrint('📝 Could not retrieve raw data: $e2');
              }
            }
          }

          debugPrint('📊 Total messages loaded: ${messages.length}');
          return messages;
        });
  }

  /// Add a method to properly create admin messages (can be called from backend/cloud function)
  Future<bool> createAdminMessage({
    required String chatRoomId,
    required String text,
    String adminId = 'admin',
    String adminName = 'Kingsley Carwash Admin',
  }) async {
    if (text.trim().isEmpty) return false;

    try {
      // Create the admin message
      final messageData = ChatMessage(
        id: '', // Firestore will generate this
        chatRoomId: chatRoomId,
        senderId: adminId,
        senderName: adminName,
        senderRole: 'admin',
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

      debugPrint('✅ Admin message created: "$text"');

      // Update chat room's last message
      await _db.collection('chat_rooms').doc(chatRoomId).update({
        'lastMessage': text.trim(),
        'lastMessageSenderId': adminId,
        'lastMessageSenderRole': 'admin',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('❌ Error creating admin message: $e');
      return false;
    }
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

      if (unreadMessages.docs.isNotEmpty) {
        // Mark each message as read
        final batch = _db.batch();
        for (var doc in unreadMessages.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();

        debugPrint(
          '📖 Marked ${unreadMessages.docs.length} messages as read in chat room $chatRoomId',
        );
      }

      // Reset unread count in chat room
      await _db.collection('chat_rooms').doc(chatRoomId).update({
        'unreadCount': 0,
      });

      debugPrint('✅ Reset unread count for chat room $chatRoomId');
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  /// Repair messages missing createdAt timestamp (called when messages aren't displaying)
  Future<void> repairMessagesInChatRoom(String chatRoomId) async {
    try {
      debugPrint('🔧 Repairing messages in chat room: $chatRoomId');

      final messagesSnapshot = await _db
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .get();

      debugPrint('🔍 Found ${messagesSnapshot.docs.length} messages to check');

      final batch = _db.batch();
      int fixedCount = 0;

      for (var doc in messagesSnapshot.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'];

        // If createdAt is missing or null, add it
        if (createdAt == null) {
          debugPrint('⚠️  Message ${doc.id} missing createdAt, setting to now');
          batch.update(doc.reference, {
            'createdAt': FieldValue.serverTimestamp(),
          });
          fixedCount++;
        }

        // Ensure all required fields exist
        final updateData = <String, dynamic>{};

        if (!data.containsKey('senderId') || data['senderId'] == null) {
          updateData['senderId'] = data['senderRole'] == 'admin'
              ? 'admin'
              : 'unknown-user';
        }

        if (!data.containsKey('senderName') || data['senderName'] == null) {
          updateData['senderName'] = data['senderRole'] == 'admin'
              ? 'Admin'
              : 'User';
        }

        if (!data.containsKey('senderRole') || data['senderRole'] == null) {
          updateData['senderRole'] = 'user';
        }

        if (!data.containsKey('text') || data['text'] == null) {
          updateData['text'] = '';
        }

        if (updateData.isNotEmpty) {
          batch.update(doc.reference, updateData);
          debugPrint('✏️  Updated message ${doc.id} with missing fields');
        }
      }

      if (fixedCount > 0 ||
          messagesSnapshot.docs.any(
            (doc) => !doc.data().containsKey('createdAt'),
          )) {
        await batch.commit();
        debugPrint('✅ Repaired $fixedCount messages in $chatRoomId');
      }
    } catch (e) {
      debugPrint('❌ Error repairing messages: $e');
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

  /// Populate missing lastMessage fields from actual messages
  Future<void> populateMissingLastMessages() async {
    try {
      debugPrint('🔄 Checking for chat rooms with missing lastMessages...');

      for (var chatRoom in chatRooms) {
        // If lastMessage is empty, try to get it from the actual messages
        if (chatRoom.lastMessage.isEmpty) {
          debugPrint(
            '📝 Chat room ${chatRoom.id} has empty lastMessage, fetching...',
          );

          // Get the most recent message
          final messagesSnapshot = await _db
              .collection('chat_rooms')
              .doc(chatRoom.id)
              .collection('messages')
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get();

          if (messagesSnapshot.docs.isNotEmpty) {
            final lastMsg = messagesSnapshot.docs.first;
            final msgData = lastMsg.data();
            final messageText = msgData['text'] ?? '';
            final senderRole = msgData['senderRole'] ?? 'user';

            if (messageText.isNotEmpty) {
              // Update the chat room document with this message
              await _db.collection('chat_rooms').doc(chatRoom.id).update({
                'lastMessage': messageText,
                'lastMessageSenderId': msgData['senderId'] ?? '',
                'lastMessageSenderRole': senderRole,
                'lastMessageTime':
                    msgData['createdAt'] ?? FieldValue.serverTimestamp(),
              });

              debugPrint(
                '✅ Updated chat room ${chatRoom.id} lastMessage: "$messageText"',
              );
            }
          } else {
            // No messages yet, set default
            await _db.collection('chat_rooms').doc(chatRoom.id).update({
              'lastMessage': 'Chat started',
            });
            debugPrint('ℹ️ Chat room ${chatRoom.id} has no messages yet');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error populating missing lastMessages: $e');
    }
  }

  /// Refresh chat rooms - useful for manual refresh
  void refreshChatRooms() {
    debugPrint('🔄 Manual refresh requested');
    _listenToChatRooms();
  }
}
