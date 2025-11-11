import 'package:capstone/controllers/notification_controller.dart';
import 'package:capstone/utils/app_textstyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:capstone/screens/signup/signup_screen.dart';
import 'package:capstone/controllers/custom_bottom_navbar.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationController notificationController = Get.find();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

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
          'Notifications',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          if (user != null)
            TextButton(
              onPressed: () => notificationController.markAllAsRead(),
              child: Text(
                'Mark all as read',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodySmall,
                  isDark ? Colors.white : Theme.of(context).primaryColor,
                ),
              ),
            ),
        ],
      ),
      body: user == null
          ? _buildGuestView(context, isDark)
          : Obx(() {
              if (notificationController.notifications.isEmpty) {
                return _buildNoNotificationsView();
              } else {
                return _buildNotificationsList(
                  notificationController.notifications,
                  notificationController,
                  isDark,
                );
              }
            }),
      bottomNavigationBar: const CustomBottomNavbar(),
    );
  }

  Widget _buildNotificationsList(
    List<AppNotification> notifications,
    NotificationController controller,
    bool isDark,
  ) {
    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        final formattedDate = DateFormat.yMMMMd().add_jm().format(
          notification.createdAt.toDate(),
        );

        return Dismissible(
          key: Key(notification.id),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            controller.deleteNotification(
              notification.id,
            ); // This now handles the snackbar
          },
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          child: ListTile(
            tileColor: !notification.isRead
                ? Theme.of(context).primaryColor.withOpacity(0.09)
                : Colors.transparent,
            leading: CircleAvatar(
              backgroundColor: notification.isRead
                  ? (isDark ? Colors.grey[800] : Colors.grey[300])
                  : Theme.of(context).primaryColor.withOpacity(0.3),
              child: Icon(
                Icons.notifications,
                color: notification.isRead
                    ? (isDark ? Colors.grey[600] : Colors.grey[500])
                    : Theme.of(context).primaryColor,
              ),
            ),
            title: Text(notification.title, style: AppTextStyle.bodyMedium),
            subtitle: Text(
              '${notification.body}\n$formattedDate',
              style: AppTextStyle.bodySmall,
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: isDark ? Colors.red[300] : Colors.red[700],
              ),
              onPressed: () {
                controller.deleteNotification(notification.id);
              },
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildNoNotificationsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text('No Notifications Yet', style: AppTextStyle.h3),
          const SizedBox(height: 8),
          Text(
            'You have no notifications right now.\nCome back later.',
            textAlign: TextAlign.center,
            style: AppTextStyle.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildGuestView(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_paused_outlined,
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
              'Sign up or log in to receive notifications.',
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
