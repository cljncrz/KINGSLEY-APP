import 'package:capstone/controllers/auth_controller.dart';
import 'package:capstone/controllers/navigation_controller.dart';
import 'package:capstone/view/home/account/about_kingsley_carwash_screen.dart';
import 'package:capstone/controllers/user_controller.dart'; // Import UserController
import 'package:capstone/utils/app_textstyles.dart';
import 'package:capstone/view/home/account/damage_reports.dart';
import 'package:capstone/view/home/account/privacy_policy_screen.dart';
import 'package:capstone/view/home/account/terms_and_conditions_screen.dart';
import 'package:capstone/view/home/account/edit_profile_screen.dart';
import 'package:capstone/view/home/account/faqs_screen.dart';
import 'package:capstone/view/home/account/setting_screen.dart';
import 'package:capstone/view/home/account/my_reviews_screen.dart';
import 'package:capstone/view/home/account/geofence_status_screen.dart';
import 'package:capstone/screens/signin_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  // The build method for the AccountScreen widget.
  // It determines whether to show a guest view or a logged-in view based on the user's authentication status.
  Widget build(BuildContext context) {
    final NavigationController navigationController =
        Get.find<NavigationController>();
    final AuthController authController = Get.find<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => navigationController.changeIndex(0),
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        title: Text(
          'Account',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Get.to(() => const SettingScreen()),
            icon: Icon(
              Icons.settings,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
      body: !authController.isLoggedIn
          ? _buildGuestView(context) // Show guest view if no user is logged in
          : _buildLoggedInView(
              context,
            ), // Show logged-in view if a user is logged in
    );
  }

  // Builds the view for a logged-in user.
  // It uses Obx to reactively update the UI based on changes in UserController.
  Widget _buildLoggedInView(BuildContext context) {
    final UserController userController = Get.find<UserController>();

    return Obx(() {
      // Show a loading indicator if user data is being fetched
      if (userController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      // Get the current Firebase Auth user and Firestore user data
      final User? firebaseUser = userController.firebaseUser.value;
      final Map<String, dynamic>? firestoreData =
          userController.firestoreUserData.value;

      // Determine name, email, and profile image URL
      String? name = firestoreData?['fullName'] ?? firebaseUser?.displayName;
      String? email = firestoreData?['email'] ?? firebaseUser?.email;
      String? profileImageUrl =
          firestoreData?['profileImageUrl'] ?? firebaseUser?.photoURL;

      // Fallback for name if still null
      name ??= 'User';

      // If no Firebase user is found (e.g., logged out while on this screen), show guest view
      if (firebaseUser == null) {
        return _buildGuestView(context);
      }

      return SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileDetails(
              context,
              name: name,
              email: email,
              imageUrl: profileImageUrl,
            ),
            const SizedBox(height: 24),
            _buildMenuSection(context),
          ],
        ),
      );
    });
  }
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
            Icons.person_off_outlined, // A suitable icon for guest mode
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
            'Sign up or log in to manage your account and view details.',
            style: AppTextStyle.withColor(
              AppTextStyle.bodyMedium,
              isDark ? Colors.grey[500]! : Colors.grey[600]!,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Get.to(() => const SigninScreen()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Sign In',
              style: AppTextStyle.buttonMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildProfileDetails(
  BuildContext context, {
  String? name,
  String? imageUrl,
  String? email,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF141414) : Colors.grey[100],
      borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
    ),
    child: Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: imageUrl != null && imageUrl.isNotEmpty
              ? NetworkImage(imageUrl)
              : const AssetImage('assets/images/logo.png') as ImageProvider,
        ), // Use NetworkImage for URL, fallback to AssetImage
        const SizedBox(height: 16),
        Text(
          name ?? 'User',
          style: AppTextStyle.withColor(
            AppTextStyle.h2,
            Theme.of(context).textTheme.bodyLarge!.color!,
          ),
        ),
        const SizedBox(height: 4),
        if (email != null)
          Text(
            email,
            style: AppTextStyle.withColor(
              AppTextStyle.bodySmall,
              isDark ? Colors.grey[500]! : Colors.grey[400]!,
            ),
          ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => Get.to(() => const EditProfileScreen()),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            side: BorderSide(color: isDark ? Colors.white70 : Colors.black12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusGeometry.circular(12),
            ),
          ),
          child: Text(
            'Edit Profile',
            style: AppTextStyle.withColor(
              AppTextStyle.buttonMedium,
              Theme.of(context).textTheme.bodyMedium!.color!,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildMenuSection(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final menuItems = [
    {'icon': Icons.info_outline, 'title': 'About Kingsley Carwash'},
    {'icon': Icons.my_location, 'title': 'Geofence Status'},
    {'icon': Icons.rate_review_outlined, 'title': 'My Reviews'},
    {'icon': Icons.report_problem_outlined, 'title': 'Damage Reports'},
    {'icon': Icons.message_sharp, 'title': '(FAQs)'},
    {'icon': Icons.policy_outlined, 'title': 'Privacy Policy'},
    {'icon': Icons.gavel_outlined, 'title': 'Terms & Conditions'},
    {'icon': Icons.logout_outlined, 'title': 'Log Out'},
  ];

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      children: menuItems.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141414) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: Icon(
              item['icon'] as IconData,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(
              item['title'] as String,
              style: AppTextStyle.withColor(
                AppTextStyle.bodySmall,
                Theme.of(context).textTheme.bodySmall!.color!,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[500] : Colors.grey,
            ),
            onTap: () {
              if (item['title'] == 'Log Out') {
                _showLogOutDialog(context);
              } else if (item['title'] == 'About Kingsley Carwash') {
                Get.to(() => const AboutKingsleyCarwashScreen());
              } else if (item['title'] == 'Geofence Status') {
                Get.to(() => const GeofenceStatusScreen());
              } else if (item['title'] == 'My Reviews') {
                Get.to(() => const MyReviewsScreen());
              } else if (item['title'] == 'Damage Reports') {
                Get.to(() => const DamageReports());
              } else if (item['title'] == '(FAQs)') {
                Get.to(() => const FaqsScreen());
              } else if (item['title'] == 'Privacy Policy') {
                Get.to(() => const PrivacyPolicyScreen());
              } else if (item['title'] == 'Terms & Conditions') {
                Get.to(() => const TermsAndConditionsScreen());
              }
            },
          ),
        );
      }).toList(),
    ),
  );
}

void _showLogOutDialog(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  Get.dialog(
    AlertDialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.logout_rounded,
              color: Theme.of(context).primaryColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Log Out',
            style: AppTextStyle.withColor(
              AppTextStyle.h3,
              Theme.of(context).textTheme.bodyLarge!.color!,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Are you sure you want to log out?',
            textAlign: TextAlign.center,
            style: AppTextStyle.withColor(
              AppTextStyle.bodyMedium,
              isDark ? Colors.grey[400]! : Colors.grey[600]!,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: AppTextStyle.withColor(
                      AppTextStyle.buttonMedium,
                      Theme.of(context).textTheme.bodyMedium!.color!,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final navigationController =
                        Get.find<NavigationController>();
                    navigationController.changeIndex(0); // Reset to home tab
                    // Signing out from Firebase will trigger the stream in AuthController
                    // which will update the UI automatically.
                    FirebaseAuth.instance.signOut();
                    Get.offAll(() => const SigninScreen());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Logout',
                    style: AppTextStyle.withColor(
                      AppTextStyle.buttonMedium,
                      Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
