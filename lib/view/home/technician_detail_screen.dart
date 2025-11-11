import 'package:capstone/controllers/custom_bottom_navbar.dart';
import 'package:capstone/models/technician.dart';
import 'package:capstone/utils/app_textstyles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';

class TechnicianDetailScreen extends StatelessWidget {
  final Technician technician;

  const TechnicianDetailScreen({super.key, required this.technician});

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
          'Technician Details',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(context, isDark),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'About'),
            const SizedBox(height: 8),
            Text(
              technician.description,
              style: AppTextStyle.withColor(
                AppTextStyle.bodyMedium,
                Theme.of(context).textTheme.bodyMedium!.color!,
              ),
            ),
            const Divider(height: 32),
            _buildSectionTitle(context, 'Services Offered'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: technician.servicesOffered.map((service) {
                return Chip(
                  label: Text(service),
                  backgroundColor: const Color(0xFF7F1618),
                  labelStyle: AppTextStyle.withColor(
                    AppTextStyle.bodySmall,
                    Colors.white,
                  ),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
            const Divider(height: 32),
            _buildSectionTitle(context, 'Reviews'),
            const SizedBox(height: 16),
            if (technician.userReviews.isEmpty)
              Text(
                'No reviews yet.',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodyMedium,
                  Theme.of(context).textTheme.bodyMedium!.color!,
                ),
              )
            else
              ...technician.userReviews
                  .map((review) => _buildReviewCard(context, review, isDark))
                  .toList(),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavbar(),
    );
  }

  Widget _buildProfileHeader(BuildContext context, bool isDark) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: AssetImage(technician.imageUrl),
          backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                technician.name,
                style: AppTextStyle.withColor(
                  AppTextStyle.h2,
                  Theme.of(context).textTheme.bodyLarge!.color!,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  RatingBarIndicator(
                    rating: technician.rating,
                    itemBuilder: (context, index) =>
                        Icon(Icons.star, color: Theme.of(context).primaryColor),
                    itemCount: 5,
                    itemSize: 20.0,
                    direction: Axis.horizontal,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${technician.rating} (${technician.reviews} reviews)',
                    style: AppTextStyle.withColor(
                      AppTextStyle.bodySmall,
                      isDark ? Colors.grey[400]! : Colors.grey[600]!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: AppTextStyle.withColor(
        AppTextStyle.h3,
        Theme.of(context).textTheme.bodyLarge!.color!,
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, Review review, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: isDark ? Colors.grey[800] : Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage(review.userAvatarUrl),
                  backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: AppTextStyle.withColor(
                          AppTextStyle.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          Theme.of(context).textTheme.bodyLarge!.color!,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RatingBarIndicator(
                        rating: review.rating,
                        itemBuilder: (context, index) => Icon(
                          Icons.star,
                          color: Theme.of(context).primaryColor,
                        ),
                        itemCount: 5,
                        itemSize: 16.0,
                        direction: Axis.horizontal,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: AppTextStyle.withColor(
                AppTextStyle.bodySmall,
                Theme.of(context).textTheme.bodyMedium!.color!,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
