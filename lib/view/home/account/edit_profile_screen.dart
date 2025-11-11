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
  void _loadInitialDataFromController() {
    final userController = Get.find<UserController>();
    final firebaseUser = userController.firebaseUser.value;
    final firestoreData = userController.firestoreUserData.value;

    if (firebaseUser != null) {
      _emailController.text =
          firestoreData?['email'] ?? firebaseUser.email ?? '';
      _nameController.text =
          firestoreData?['fullName'] ?? firebaseUser.displayName ?? '';
      _phoneController.text = firestoreData?['phoneNumber'] ?? '';
      _profileImageUrl =
          firestoreData?['profileImageUrl'] ?? firebaseUser.photoURL;
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
    final ImagePicker picker = ImagePicker();
    // Pick an image from the gallery.
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
  }

  Future<void> _saveChanges() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user is currently logged in.');
      }

      String? newImageUrl = _profileImageUrl;

      // 1. Upload new image to Firebase Storage if one was selected
      if (_selectedImage != null) {
        final ref = firebase_storage.FirebaseStorage.instance.ref(
          'users/${user.uid}/profile.jpg',
        );
        await ref.putFile(_selectedImage!);
        newImageUrl = await ref.getDownloadURL();
      }

      // 2. Update Firebase Auth profile
      if (user.displayName != _nameController.text.trim() ||
          user.photoURL != newImageUrl) {
        await user.updateDisplayName(_nameController.text.trim());
        await user.updatePhotoURL(newImageUrl);
      }

      // 3. Update Firestore user document
      final Map<String, dynamic> dataToUpdate = {
        'fullName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'profileImageUrl': newImageUrl,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(dataToUpdate);

      // 4. Update email if it has changed (requires re-authentication for security)
      if (user.email != _emailController.text.trim()) {
        // This is a sensitive operation. For a production app, you should
        // handle potential errors by asking the user to re-authenticate.
        await user.verifyBeforeUpdateEmail(_emailController.text.trim());
      }

      // 5. Fetch the latest user data in the background without blocking.
      Get.find<UserController>().fetchFirestoreUserData(user.uid);

      Get.rawSnackbar(
        titleText: Text(
          'Success',
          style: AppTextStyle.withColor(
            AppTextStyle.bodySmall,
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
    } catch (e) {
      Get.snackbar(
        'Error updating profile',
        'An error occurred while saving your changes. Please try again.',
        titleText: Text(
          'Error',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? const Color(0xFF7F1618) : Colors.white,
          ),
        ),
        messageText: Text(
          'Failed to save changes: ${e.toString()}',
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
      // Navigate back after the operation is complete.
      Get.back();
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
