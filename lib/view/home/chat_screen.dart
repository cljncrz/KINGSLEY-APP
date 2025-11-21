import 'package:capstone/utils/app_textstyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:capstone/view/home/chat_detail_screen.dart';
import 'package:capstone/screens/signup/signup_screen.dart';
import 'package:capstone/controllers/custom_bottom_navbar.dart';
import 'package:capstone/controllers/chat_controller.dart';
import 'package:intl/intl.dart';

class AiChatbotScreen extends StatefulWidget {
  const AiChatbotScreen({super.key});

  @override
  State<AiChatbotScreen> createState() => _AiChatbotScreenState();
}

class _AiChatbotScreenState extends State<AiChatbotScreen> {
  final ChatController _chatController = Get.put(ChatController());

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        title: Text(
          'Chat Inbox',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          Obx(() {
            final unreadCount = _chatController.totalUnreadCount;
            if (unreadCount > 0) {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            return _buildInboxView(context);
          } else {
            return _buildGuestView(context);
          }
        },
      ),
      floatingActionButton: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return FloatingActionButton.extended(
              onPressed: () async {
                final chatRoomId = await _chatController.getOrCreateChatRoom();
                if (chatRoomId != null) {
                  Get.to(() => ChatDetailScreen(chatRoomId: chatRoomId));
                }
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Start Chat'),
              backgroundColor: Theme.of(context).primaryColor,
            );
          }
          return const SizedBox.shrink();
        },
      ),
      bottomNavigationBar: const CustomBottomNavbar(),
    );
  }

  Widget _buildInboxView(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Obx(() {
      if (_chatController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final chatRooms = _chatController.chatRooms;

      if (chatRooms.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
                const SizedBox(height: 24),
                Text(
                  'No Conversations Yet',
                  style: AppTextStyle.withColor(
                    AppTextStyle.h2,
                    Theme.of(context).textTheme.bodyLarge!.color!,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a chat with Kingsley Carwash support team.',
                  style: AppTextStyle.withColor(
                    AppTextStyle.bodyMedium,
                    isDark ? Colors.grey[500]! : Colors.grey[600]!,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        itemCount: chatRooms.length,
        itemBuilder: (context, index) {
          final chatRoom = chatRooms[index];
          final hasUnread = chatRoom.hasUnreadMessages;
          final isFromAdmin = chatRoom.isLastMessageFromAdmin;

          // Format time
          final now = DateTime.now();
          final messageDate = chatRoom.lastMessageTime;
          String timeStr;

          if (now.difference(messageDate).inDays == 0) {
            timeStr = DateFormat('h:mm a').format(messageDate);
          } else if (now.difference(messageDate).inDays == 1) {
            timeStr = 'Yesterday';
          } else if (now.difference(messageDate).inDays < 7) {
            timeStr = DateFormat('EEEE').format(messageDate);
          } else {
            timeStr = DateFormat('MMM dd').format(messageDate);
          }

          return ListTile(
            tileColor: hasUnread
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : null,
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(
                isFromAdmin ? Icons.support_agent : Icons.person,
                color: Colors.white,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    isFromAdmin ? 'Kingsley Carwash' : 'You',
                    style:
                        AppTextStyle.withColor(
                          AppTextStyle.h3,
                          Theme.of(context).textTheme.bodyLarge!.color!,
                        ).copyWith(
                          fontWeight: hasUnread
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                  ),
                ),
                if (hasUnread)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${chatRoom.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              chatRoom.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  AppTextStyle.withColor(
                    AppTextStyle.bodySmall,
                    isDark ? Colors.grey[400]! : Colors.grey[600]!,
                  ).copyWith(
                    fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
            trailing: Text(
              timeStr,
              style: AppTextStyle.bodySmall.copyWith(
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                color: hasUnread
                    ? Theme.of(context).primaryColor
                    : (isDark ? Colors.grey[500] : Colors.grey[600]),
              ),
            ),
            onTap: () {
              Get.to(() => ChatDetailScreen(chatRoomId: chatRoom.id));
            },
          );
        },
      );
    });
  }

  Widget _buildGuestView(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mark_email_unread_outlined,
              size: 80,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'You are in Guest Mode',
              style: AppTextStyle.withColor(
                AppTextStyle.h2,
                Theme.of(context).textTheme.bodyLarge!.color!,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sign up or log in to receive messages and notifications.',
              style: AppTextStyle.withColor(
                AppTextStyle.bodyMedium,
                isDark ? Colors.grey[500]! : Colors.grey[600]!,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.to(() => const SignupScreen()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Sign Up',
                style: AppTextStyle.buttonMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
