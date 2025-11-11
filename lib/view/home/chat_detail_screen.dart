import 'package:capstone/view/home/chatbot_screen.dart';
import 'package:capstone/utils/app_textstyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatDetailScreen extends StatefulWidget {
  final Message message;

  const ChatDetailScreen({super.key, required this.message});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    // Add the initial message from the inbox and some mock conversation
    _messages.addAll([
      {"sender": widget.message.sender, "text": widget.message.text},
      {"sender": "You", "text": "Okay, thank you!"},
    ]);
  }

  void _handleSend() {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({"sender": "You", "text": _textController.text.trim()});
      _textController.clear();
    });
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
        title: Text(
          widget.message.sender,
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['sender'] == 'You';
                return _buildMessageBubble(msg['text'], isMe, context);
              },
            ),
          ),
          _buildMessageComposer(context),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isMe
                ? Theme.of(context).primaryColor
                : (isDark ? Colors.grey[800] : Colors.grey[200]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            style: AppTextStyle.withColor(
              AppTextStyle.bodyMedium,
              isMe ? Colors.white : (isDark ? Colors.white : Colors.black),
            ),
          ),
        ),
      ],
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
