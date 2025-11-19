import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a chat room between a user and admin.
class ChatRoom {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String lastMessage;
  final String lastMessageSenderId;
  final String lastMessageSenderRole;
  final DateTime lastMessageTime;
  final int unreadCount; // Unread messages count for the user
  final DateTime createdAt;

  ChatRoom({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.lastMessageSenderRole,
    required this.lastMessageTime,
    this.unreadCount = 0,
    required this.createdAt,
  });

  /// Create ChatRoom from Firestore document
  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown User',
      userEmail: data['userEmail'] ?? '',
      lastMessage: data['lastMessage'] ?? 'No messages yet',
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      lastMessageSenderRole: data['lastMessageSenderRole'] ?? 'user',
      lastMessageTime:
          (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: data['unreadCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert ChatRoom to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageSenderRole': lastMessageSenderRole,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCount': unreadCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Check if the last message is from admin
  bool get isLastMessageFromAdmin => lastMessageSenderRole == 'admin';

  /// Check if there are unread messages
  bool get hasUnreadMessages => unreadCount > 0;

  /// Create a copy with modified fields
  ChatRoom copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? lastMessage,
    String? lastMessageSenderId,
    String? lastMessageSenderRole,
    DateTime? lastMessageTime,
    int? unreadCount,
    DateTime? createdAt,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageSenderRole:
          lastMessageSenderRole ?? this.lastMessageSenderRole,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
