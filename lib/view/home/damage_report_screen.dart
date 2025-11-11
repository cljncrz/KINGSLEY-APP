import 'dart:io';

import 'package:capstone/utils/app_textstyles.dart';
import 'package:capstone/utils/custom_textfield.dart';
import 'package:capstone/controllers/custom_bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:capstone/screens/signup/signup_screen.dart';

class DamageReportScreen extends StatefulWidget {
  const DamageReportScreen({super.key});

  @override
  State<DamageReportScreen> createState() => _DamageReportScreenState();
}

class _DamageReportScreenState extends State<DamageReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  final _descriptionController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];
  @override
  void dispose() {
    _dateController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> _pickImages() async {
    final int remainingImages = 10 - _images.length;
    if (remainingImages <= 0) {
      Get.snackbar(
        'Limit Reached',
        'You can only upload a maximum of 10 photos.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 80, // To reduce file size
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _images.addAll(pickedFiles.take(remainingImages));
        });
      }
    } catch (e) {
      // Handle potential errors, e.g., permissions denied
      Get.snackbar(
        'Error',
        'Could not pick images: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _submitReport() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_formKey.currentState!.validate()) {
      if (_images.length < 5) {
        Get.snackbar(
          'Incomplete Report',
          'Please attach at least 5 photos.',
          titleText: Text(
            'Incomplete Report',
            style: AppTextStyle.withColor(
              AppTextStyle.h3,
              isDark ? const Color(0xFF7F1618) : Colors.white,
            ),
          ),
          messageText: Text(
            'Please attach at least 5 photos.',
            style: AppTextStyle.withColor(
              AppTextStyle.bodySmall,
              isDark ? const Color(0xFF7F1618) : Colors.white,
            ),
          ),
          snackPosition: SnackPosition.TOP,
          backgroundColor: isDark ? Colors.white : const Color(0xFF7F1618),
          colorText: isDark ? Colors.white : const Color(0xFF7F1618),
        );
        return;
      }

      // TODO: Implement the logic to send the report to the admin.
      // This would involve uploading images and sending form data to a server.

      Get.dialog(
        AlertDialog(
          title: Text('Report Submitted', style: AppTextStyle.h3),
          content: Text(
            'Your damage report has been successfully submitted. Our team will review it and get back to you.',
            style: AppTextStyle.bodySmall,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back(); // Close the dialog
                Get.back(); // Go back from the report screen
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        title: Text(
          'Damage Report',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: user == null
          ? _buildGuestView(context)
          : _buildLoggedInView(context),
      bottomNavigationBar: const CustomBottomNavbar(),
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
              Icons.warning_amber_rounded,
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
              'Sign up or log in to file a damage report.',
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

  Widget _buildLoggedInView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please provide the details of the incident.',
              style: AppTextStyle.bodyMedium,
            ),
            const SizedBox(height: 24),
            _buildPhotoAttachmentSection(),
            const SizedBox(height: 24),
            TextFormField(
              style: AppTextStyle.bodyMedium,
              controller: _dateController,
              decoration: InputDecoration(
                labelText: 'Date',
                labelStyle: AppTextStyle.bodyMedium,
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2.0,
                  ),
                ),
              ),
              readOnly: true,
              onTap: _selectDate,
              validator: (value) =>
                  value!.isEmpty ? 'Please select a date' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              style: AppTextStyle.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Location',
                labelStyle: AppTextStyle.bodyMedium,
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2.0,
                  ),
                ),
              ),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter the location' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactController,
              style: AppTextStyle.bodyMedium,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Contact Number',
                labelStyle: AppTextStyle.bodyMedium,
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2.0,
                  ),
                ),
              ),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter your contact number' : null,
            ),
            const SizedBox(height: 16),
            CustomTextfield(
              label: 'Description of Damage',
              prefixIcon: Icons.description_outlined,
              controller: _descriptionController,
              maxLines: 5,
              validator: (value) =>
                  value!.isEmpty ? 'Please describe the damage' : null,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Submit Report',
                  style: AppTextStyle.withColor(
                    AppTextStyle.buttonMedium,
                    Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoAttachmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('(Attach Photos)', style: AppTextStyle.h3),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _images.length + 1,
          itemBuilder: (context, index) {
            if (index == _images.length) {
              return _buildAddPhotoButton();
            }
            return _buildImageThumbnail(index);
          },
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey[400]!,
            style: BorderStyle.solid,
            width: 1,
          ),
        ),
        child: Icon(
          Icons.add_a_photo_outlined,
          color: Colors.grey[600],
          size: 32,
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(_images[index].path),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: IconButton(
            icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
            onPressed: () {
              setState(() {
                _images.removeAt(index);
              });
            },
          ),
        ),
      ],
    );
  }
}
