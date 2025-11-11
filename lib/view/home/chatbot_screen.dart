import 'package:capstone/utils/app_textstyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:capstone/view/home/chat_detail_screen.dart';
import 'package:capstone/screens/signup/signup_screen.dart';
import 'package:capstone/controllers/custom_bottom_navbar.dart';

class Message {
  final String sender;
  final String text;
  final String time;
  final bool isUnread;

  Message({
    required this.sender,
    required this.text,
    required this.time,
    this.isUnread = false,
  });
}

// ignore: must_be_immutable
class AiChatbotScreen extends StatefulWidget {
  const AiChatbotScreen({super.key});

  @override
  State<AiChatbotScreen> createState() => _AiChatbotScreenState();
}

class _AiChatbotScreenState extends State<AiChatbotScreen> {
  final List<Message> sampleMessages = [
    Message(
      sender: 'Kingsley Carwash',
      text: 'Your car is ready for pickup!',
      time: '10:30 AM',
      isUnread: true,
    ),
    Message(
      sender: 'Special Offer',
      text: 'Get 20% off on your next wash. Use code: KINGSLEY20',
      time: 'Yesterday',
    ),
    Message(
      sender: 'Booking Confirmation',
      text: 'Your booking for tomorrow at 2:00 PM is confirmed.',
      time: 'Yesterday',
    ),
    Message(
      sender: 'Welcome!',
      text: 'Thanks for signing up with Kingsley Carwash!',
      time: '2 days ago',
    ),
  ];

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
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            return _buildInboxView(context, sampleMessages);
          } else {
            return _buildGuestView(context);
          }
        },
      ),
      bottomNavigationBar: const CustomBottomNavbar(),
    );
  }

  Widget _buildInboxView(BuildContext context, List<Message> messages) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return ListTile(
          tileColor: message.isUnread
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : null,
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              message.sender[0],
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(
            message.sender,
            style:
                AppTextStyle.withColor(
                  AppTextStyle.h3,
                  Theme.of(context).textTheme.bodyLarge!.color!,
                ).copyWith(
                  fontWeight: message.isUnread
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
          ),
          subtitle: Text(
            message.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.withColor(
              AppTextStyle.bodySmall,
              isDark ? Colors.grey[400]! : Colors.grey[600]!,
            ),
          ),
          trailing: Text(message.time, style: AppTextStyle.bodySmall),
          onTap: () {
            setState(() {
              final index = messages.indexOf(message);
              messages[index] = Message(
                sender: message.sender,
                text: message.text,
                time: message.time,
              );
            });
            Get.to(() => ChatDetailScreen(message: message));
          },
        );
      },
    );
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
