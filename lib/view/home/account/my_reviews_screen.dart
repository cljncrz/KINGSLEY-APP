import 'package:capstone/controllers/custom_bottom_navbar.dart';
import 'package:capstone/controllers/feedback_controller.dart';
import 'package:capstone/models/service_feedback.dart';
import 'package:capstone/models/technician_feedback.dart';
import 'package:capstone/utils/app_textstyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class MyReviewsScreen extends StatelessWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FeedbackController feedbackController =
        Get.find<FeedbackController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        title: Text(
          'My Reviews',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavbar(),
      body: Obx(() {
        final serviceFeedbacks = feedbackController.serviceFeedbacks.values
            .toList();
        final technicianFeedbacks = feedbackController
            .technicianFeedbacks
            .values
            .toList();

        // Combine both feedback types for display
        final allFeedbacks = <Map<String, dynamic>>[];

        // Add service feedbacks
        for (var feedback in serviceFeedbacks) {
          allFeedbacks.add({
            'type': 'service',
            'data': feedback,
            'date': feedback.createdAt,
          });
        }

        // Add technician feedbacks
        for (var feedback in technicianFeedbacks) {
          allFeedbacks.add({
            'type': 'technician',
            'data': feedback,
            'date': feedback.createdAt,
          });
        }

        // Sort by date (newest first)
        allFeedbacks.sort(
          (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
        );

        if (allFeedbacks.isEmpty) {
          return _buildEmptyState(context, isDark);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allFeedbacks.length,
          itemBuilder: (context, index) {
            final feedbackItem = allFeedbacks[index];
            final type = feedbackItem['type'] as String;

            if (type == 'service') {
              final feedback = feedbackItem['data'] as ServiceFeedback;
              return _buildServiceFeedbackCard(context, feedback, isDark);
            } else {
              final feedback = feedbackItem['data'] as TechnicianFeedback;
              return _buildTechnicianFeedbackCard(context, feedback, isDark);
            }
          },
        );
      }),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 80,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Reviews Yet',
              style: AppTextStyle.withColor(
                AppTextStyle.h2,
                Theme.of(context).textTheme.bodyLarge!.color!,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your feedback and reviews will appear here after you complete a service.',
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

  Widget _buildServiceFeedbackCard(
    BuildContext context,
    ServiceFeedback feedback,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_car_wash,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Service Review',
                      style: AppTextStyle.withColor(
                        AppTextStyle.bodySmall,
                        isDark ? Colors.white : const Color(0xFF7F1618),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM dd, yyyy').format(feedback.createdAt),
                style: AppTextStyle.withColor(
                  AppTextStyle.bodySmall,
                  isDark ? Colors.grey[500]! : Colors.grey[600]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < feedback.rating.floor()
                      ? Icons.star
                      : (index < feedback.rating
                            ? Icons.star_half
                            : Icons.star_border),
                  color: Colors.amber,
                  size: 20,
                );
              }),
              const SizedBox(width: 8),
              Text(
                feedback.rating.toStringAsFixed(1),
                style: AppTextStyle.withColor(
                  AppTextStyle.bodyMedium,
                  Theme.of(context).textTheme.bodyMedium!.color!,
                ),
              ),
            ],
          ),
          if (feedback.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              feedback.comment,
              style: AppTextStyle.withColor(
                AppTextStyle.bodyMedium,
                Theme.of(context).textTheme.bodyMedium!.color!,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Booking ID: ${feedback.bookingId}',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodySmall,
                  isDark ? Colors.grey[600]! : Colors.grey[500]!,
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    _showServiceFeedbackDetails(context, feedback, isDark),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View Details'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianFeedbackCard(
    BuildContext context,
    TechnicianFeedback feedback,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      'Technician Review',
                      style: AppTextStyle.withColor(
                        AppTextStyle.bodySmall,
                        isDark ? Colors.white : const Color(0xFF7F1618),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM dd, yyyy').format(feedback.createdAt),
                style: AppTextStyle.withColor(
                  AppTextStyle.bodySmall,
                  isDark ? Colors.grey[500]! : Colors.grey[600]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Technician: ${feedback.technicianName}',
            style: AppTextStyle.withColor(
              AppTextStyle.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              Theme.of(context).textTheme.bodyMedium!.color!,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < feedback.rating.floor()
                      ? Icons.star
                      : (index < feedback.rating
                            ? Icons.star_half
                            : Icons.star_border),
                  color: Colors.amber,
                  size: 20,
                );
              }),
              const SizedBox(width: 8),
              Text(
                feedback.rating.toStringAsFixed(1),
                style: AppTextStyle.withColor(
                  AppTextStyle.bodyMedium,
                  Theme.of(context).textTheme.bodyMedium!.color!,
                ),
              ),
            ],
          ),
          if (feedback.comment != null && feedback.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              feedback.comment!,
              style: AppTextStyle.withColor(
                AppTextStyle.bodyMedium,
                Theme.of(context).textTheme.bodyMedium!.color!,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Booking ID: ${feedback.bookingId}',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodySmall,
                  isDark ? Colors.white : Colors.black,
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    _showTechnicianFeedbackDetails(context, feedback, isDark),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View Details'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showServiceFeedbackDetails(
    BuildContext context,
    ServiceFeedback feedback,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: Text(
          'Service Review Details',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Booking ID',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodySmall,
                  isDark ? Colors.grey[500]! : Colors.grey[600]!,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                feedback.bookingId,
                style: AppTextStyle.withColor(
                  AppTextStyle.bodyMedium,
                  isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Rating',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodySmall,
                  isDark ? Colors.grey[500]! : Colors.grey[600]!,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  ...List.generate(5, (index) {
                    return Icon(
                      index < feedback.rating.floor()
                          ? Icons.star
                          : (index < feedback.rating
                                ? Icons.star_half
                                : Icons.star_border),
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                  const SizedBox(width: 8),
                  Text(
                    feedback.rating.toStringAsFixed(1),
                    style: AppTextStyle.withColor(
                      AppTextStyle.bodyMedium,
                      isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Your Review',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodySmall,
                  isDark ? Colors.grey[500]! : Colors.grey[600]!,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                feedback.comment.isNotEmpty
                    ? feedback.comment
                    : 'No comment provided',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodyMedium,
                  isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Review Date',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodySmall,
                  isDark ? Colors.grey[500]! : Colors.grey[600]!,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat(
                  'MMMM dd, yyyy - hh:mm a',
                ).format(feedback.createdAt),
                style: AppTextStyle.withColor(
                  AppTextStyle.bodyMedium,
                  isDark ? Colors.white : Colors.black,
                ),
              ),
              if (feedback.adminReply != null &&
                  feedback.adminReply!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            size: 20,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Admin Reply',
                            style: AppTextStyle.withColor(
                              AppTextStyle.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              isDark ? Colors.white : const Color(0xFF7F1618),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        feedback.adminReply!,
                        style: AppTextStyle.withColor(
                          AppTextStyle.bodyMedium,
                          isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      if (feedback.adminReplyDate != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          DateFormat(
                            'MMM dd, yyyy - hh:mm a',
                          ).format(feedback.adminReplyDate!),
                          style: AppTextStyle.withColor(
                            AppTextStyle.bodySmall,
                            isDark ? Colors.grey[500]! : Colors.grey[600]!,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey[800]!.withOpacity(0.3)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No admin reply yet',
                          style: AppTextStyle.withColor(
                            AppTextStyle.bodySmall,
                            isDark ? Colors.grey[500]! : Colors.grey[600]!,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTechnicianFeedbackDetails(
    BuildContext context,
    TechnicianFeedback feedback,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: Text(
          'Technician Review Details',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Booking ID',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodySmall,
                  isDark ? Colors.grey[500]! : Colors.grey[600]!,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                feedback.bookingId,
                style: AppTextStyle.withColor(
                  AppTextStyle.bodyMedium,
                  isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Technician',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodySmall,
                  isDark ? Colors.grey[500]! : Colors.grey[600]!,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                feedback.technicianName,
                style: AppTextStyle.withColor(
                  AppTextStyle.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Rating',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodySmall,
                  isDark ? Colors.grey[500]! : Colors.grey[600]!,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  ...List.generate(5, (index) {
                    return Icon(
                      index < feedback.rating.floor()
                          ? Icons.star
                          : (index < feedback.rating
                                ? Icons.star_half
                                : Icons.star_border),
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                  const SizedBox(width: 8),
                  Text(
                    feedback.rating.toStringAsFixed(1),
                    style: AppTextStyle.withColor(
                      AppTextStyle.bodyMedium,
                      isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Your Review',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodySmall,
                  isDark ? Colors.grey[500]! : Colors.grey[600]!,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                feedback.comment != null && feedback.comment!.isNotEmpty
                    ? feedback.comment!
                    : 'No comment provided',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodyMedium,
                  isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Review Date',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodySmall,
                  isDark ? Colors.grey[500]! : Colors.grey[600]!,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat(
                  'MMMM dd, yyyy - hh:mm a',
                ).format(feedback.createdAt),
                style: AppTextStyle.withColor(
                  AppTextStyle.bodyMedium,
                  isDark ? Colors.white : Colors.black,
                ),
              ),
              if (feedback.adminReply != null &&
                  feedback.adminReply!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            size: 20,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Admin Reply',
                            style: AppTextStyle.withColor(
                              AppTextStyle.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              isDark ? Colors.white : const Color(0xFF7F1618),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        feedback.adminReply!,
                        style: AppTextStyle.withColor(
                          AppTextStyle.bodyMedium,
                          isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      if (feedback.adminReplyDate != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          DateFormat(
                            'MMM dd, yyyy - hh:mm a',
                          ).format(feedback.adminReplyDate!),
                          style: AppTextStyle.withColor(
                            AppTextStyle.bodySmall,
                            isDark ? Colors.grey[500]! : Colors.grey[600]!,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey[800]!.withOpacity(0.3)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No admin reply yet',
                          style: AppTextStyle.withColor(
                            AppTextStyle.bodySmall,
                            isDark ? Colors.grey[500]! : Colors.grey[600]!,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
