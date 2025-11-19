import 'package:capstone/utils/app_textstyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone/controllers/chat_controller.dart';
import 'package:capstone/models/chat_message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatRoomId;

  const ChatDetailScreen({super.key, required this.chatRoomId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatController _chatController = Get.find<ChatController>();
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Mark messages as read when user opens the chat
    _chatController.markMessagesAsRead(widget.chatRoomId);

    // Auto-scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSend() async {
    if (_textController.text.trim().isEmpty) return;

    final text = _textController.text.trim();
    _textController.clear();

    final success = await _chatController.sendMessage(
      chatRoomId: widget.chatRoomId,
      text: text,
    );

    if (success) {
      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              radius: 18,
              child: const Icon(
                Icons.support_agent,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Kingsley Carwash',
              style: AppTextStyle.withColor(
                AppTextStyle.h3,
                isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatController.getMessagesStream(widget.chatRoomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading messages',
                      style: AppTextStyle.bodyMedium,
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start the conversation',
                          style: AppTextStyle.withColor(
                            AppTextStyle.bodyMedium,
                            isDark ? Colors.grey[500]! : Colors.grey[600]!,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Auto-scroll when messages update
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _auth.currentUser?.uid;
                    final showTimestamp =
                        index == 0 ||
                        messages[index - 1].createdAt
                                .difference(message.createdAt)
                                .inMinutes
                                .abs() >
                            5;

                    return Column(
                      children: [
                        if (showTimestamp) _buildTimestamp(message.createdAt),
                        _buildMessageBubble(message, isMe, context),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageComposer(context),
        ],
      ),
    );
  }

  Widget _buildTimestamp(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    String dateStr;
    if (messageDate == today) {
      dateStr = 'Today ${DateFormat('h:mm a').format(time)}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      dateStr = 'Yesterday ${DateFormat('h:mm a').format(time)}';
    } else if (now.difference(messageDate).inDays < 7) {
      dateStr = DateFormat('EEEE h:mm a').format(time);
    } else {
      dateStr = DateFormat('MMM dd, yyyy h:mm a').format(time);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        dateStr,
        style: AppTextStyle.bodySmall.copyWith(
          color: Colors.grey,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    bool isMe,
    BuildContext context,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              radius: 16,
              child: const Icon(
                Icons.support_agent,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).primaryColor
                    : (isDark ? Colors.grey[800] : Colors.grey[200]),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.senderName,
                        style: AppTextStyle.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  Text(
                    message.text,
                    style: AppTextStyle.withColor(
                      AppTextStyle.bodyMedium,
                      isMe
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            Icon(
              message.isRead ? Icons.done_all : Icons.done,
              size: 16,
              color: message.isRead
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageComposer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
            onPressed: _handleSend,
          ),
        ],
      ),
    );
  }
}
