import 'package:capstone/utils/app_textstyles.dart';
import 'package:capstone/utils/custom_textfield.dart';
import 'package:capstone/controllers/custom_bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'dart:io'; // Required for File
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:capstone/controllers/user_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadInitialDataFromController();
  }

  // Load user data from the central UserController
  void _loadInitialDataFromController() async {
    final userController = Get.find<UserController>();
    final firebaseUser = userController.firebaseUser.value;

    if (firebaseUser != null) {
      // Refresh Firestore data to ensure we have the latest
      await userController.refreshUserData();

      // Now load the refreshed data
      final firestoreData = userController.firestoreUserData.value;

      if (mounted) {
        setState(() {
          _emailController.text =
              firestoreData?['email'] ?? firebaseUser.email ?? '';
          _nameController.text =
              firestoreData?['fullName'] ?? firebaseUser.displayName ?? '';
          _phoneController.text = firestoreData?['phoneNumber'] ?? '';
          _profileImageUrl =
              firestoreData?['profileImageUrl'] ?? firebaseUser.photoURL;
        });
      }
    } else {
      // Handle case where user is somehow null, maybe navigate back or show error
      Get.snackbar('Error', 'Could not load user data.');
      Get.back();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Request photo/gallery permission
    final photoStatus = await Permission.photos.request();

    if (!photoStatus.isGranted) {
      Get.snackbar(
        'Permission Denied',
        'Gallery access is required to pick a profile photo.',
        titleText: Text(
          'Permission Denied',
          style: AppTextStyle.withColor(
            AppTextStyle.bodySmall,
            isDark ? const Color(0xFF7F1618) : Colors.white,
          ),
        ),
        messageText: Text(
          'Gallery access is required to pick a profile photo.',
          style: AppTextStyle.withColor(
            AppTextStyle.bodySmall,
            isDark ? const Color(0xFF7F1618) : Colors.white,
          ),
        ),
        snackPosition: SnackPosition.TOP,
        backgroundColor: isDark ? Colors.white : const Color(0xFF7F1618),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      } else {
        // User canceled the picker
        Get.snackbar(
          'No Image Selected',
          'You did not select an image.',
          titleText: Text(
            'No Image Selected',
            style: AppTextStyle.withColor(
              AppTextStyle.bodySmall,
              isDark ? const Color(0xFF7F1618) : Colors.white,
            ),
          ),
          messageText: Text(
            'You did not select an image.',
            style: AppTextStyle.withColor(
              AppTextStyle.bodySmall,
              isDark ? const Color(0xFF7F1618) : Colors.white,
            ),
          ),
          snackPosition: SnackPosition.TOP,
          backgroundColor: isDark ? Colors.white : const Color(0xFF7F1618),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      Get.snackbar('Error', 'Failed to pick image: $e');
    }
  }

  Future<void> _saveChanges() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'No user is currently logged in.');
      setState(() => _isLoading = false);
      return;
    }

    // Refresh user data to ensure session is valid
    try {
      await user.reload();
      debugPrint('User session verified');
    } catch (e) {
      debugPrint('Error verifying session: $e');
      Get.snackbar(
        'Session Error',
        'Your session may have expired. Please log out and log in again.',
      );
      setState(() => _isLoading = false);
      return;
    }

    String? newImageUrl = _profileImageUrl;

    // 1. Upload new image to Firebase Storage if one was selected
    if (_selectedImage != null) {
      try {
        debugPrint('Starting profile image upload for user: ${user.uid}');

        // Force-refresh the token to ensure it's valid before the upload.
        // If this fails, we should not proceed with the upload.
        try {
          await user.reload();
          await user.getIdToken(true);
          debugPrint('Auth token force-refreshed before upload.');
        } catch (tokenError) {
          debugPrint(
            'Critical Error: Failed to refresh auth token: $tokenError',
          );
          Get.snackbar(
            'Authentication Error',
            'Your session is invalid. Please log out and sign in again.',
          );
          setState(() => _isLoading = false);
          return; // Stop the process if token refresh fails
        }

        // Force-refresh the App Check token to ensure it's valid before upload.
        final appCheckToken = await FirebaseAppCheck.instance.getToken(true);
        debugPrint(
          'App Check token refreshed. Ready for upload: ${appCheckToken != null}',
        );

        final ref = firebase_storage.FirebaseStorage.instance.ref(
          'users/${user.uid}/profile.jpg',
        );
        debugPrint('Upload path: ${ref.fullPath}');

        await ref.putFile(_selectedImage!);
        newImageUrl = await ref.getDownloadURL();
        debugPrint('Profile image uploaded successfully: $newImageUrl');
      } on firebase_storage.FirebaseException catch (e) {
        debugPrint('Storage Error: Code=${e.code}, Message=${e.message}');
        debugPrint('Full exception: $e');

        Get.snackbar(
          'Upload Failed',
          'Could not upload profile picture. Please try again. (${e.code})',
        );
        setState(() => _isLoading = false);
        return; // Stop if image upload fails
      } catch (e) {
        debugPrint('Unexpected error during profile upload: $e');
        Get.snackbar(
          'Upload Failed',
          'An unexpected error occurred. Please try again.',
        );
        setState(() => _isLoading = false);
        return;
      }
    }

    try {
      // 2. Update Firebase Auth & Firestore
      if (user.displayName != _nameController.text.trim() ||
          user.photoURL != newImageUrl) {
        await user.updateDisplayName(_nameController.text.trim());
        await user.updatePhotoURL(newImageUrl);
      }

      final Map<String, dynamic> dataToUpdate = {
        'fullName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'profileImageUrl': newImageUrl,
      };

      // Update Firestore and email (if changed)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(dataToUpdate);

      if (user.email != _emailController.text.trim()) {
        await user.verifyBeforeUpdateEmail(_emailController.text.trim());
      }

      // Fetch latest data and navigate back
      await Get.find<UserController>().fetchFirestoreUserData(user.uid);
      Get.back();

      Get.rawSnackbar(
        titleText: Text(
          'Success',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? const Color(0xFF7F1618) : Colors.white,
          ),
        ),
        messageText: Text(
          'Profile updated successfully!',
          style: AppTextStyle.withColor(
            AppTextStyle.bodySmall,
            isDark ? const Color(0xFF7F1618) : Colors.white,
          ),
        ),
        snackPosition: SnackPosition.TOP,
        backgroundColor: isDark ? Colors.white : const Color(0xFF7F1618),
      );
    } on FirebaseException catch (e) {
      debugPrint('Firestore/Auth Error: ${e.code} - ${e.message}');
      Get.snackbar(
        'Update Failed',
        'Could not save profile changes. Please try again. (${e.code})',
        titleText: Text(
          'Error',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? const Color(0xFF7F1618) : Colors.white,
          ),
        ),
        messageText: Text(
          'Failed to save changes: ${e.message}',
          style: AppTextStyle.withColor(
            AppTextStyle.bodySmall,
            isDark ? const Color(0xFF7F1618) : Colors.white,
          ),
        ),
        snackPosition: SnackPosition.TOP,
        backgroundColor: isDark ? Colors.white : const Color(0xFF7F1618),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        title: Text(
          'Edit Profile',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile picture
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!) as ImageProvider
                              : (_profileImageUrl != null
                                    ? NetworkImage(_profileImageUrl!)
                                    : const AssetImage('assets/images/logo.png')
                                          as ImageProvider),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              _pickImage();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Text fields
                    CustomTextfield(
                      label: 'Full Name',
                      controller: _nameController,
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextfield(
                      label: 'Email Address',
                      controller: _emailController,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!GetUtils.isEmail(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextfield(
                      label: 'Phone Number',
                      controller: _phoneController,
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : Text(
                        'Save Changes',
                        style: AppTextStyle.withColor(
                          AppTextStyle.buttonMedium,
                          Colors.white,
                        ),
                      ),
              ),
            ),
          ),
          const CustomBottomNavbar(),
        ],
      ),
    );
  }
}
