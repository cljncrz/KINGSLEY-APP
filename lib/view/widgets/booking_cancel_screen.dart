import 'package:capstone/models/booking.dart';
import 'package:capstone/controllers/product_controller.dart';
import 'package:capstone/utils/app_textstyles.dart';
import 'package:capstone/view/widgets/booking_cancel_success_screen.dart';
import 'package:capstone/view/widgets/booking_rescheduled_screen.dart';
import 'package:capstone/controllers/custom_bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CancelBookingScreen extends StatefulWidget {
  final Booking booking;
  const CancelBookingScreen({super.key, required this.booking});

  @override
  State<CancelBookingScreen> createState() => _CancelBookingScreenState();
}

class _CancelBookingScreenState extends State<CancelBookingScreen> {
  int? _selectedReason = 0;
  final _commentController = TextEditingController();

  final List<String> _cancellationReasons = [
    'I have a schedule conflict.',
    'I found a better offer elsewhere.',
    'I am not satisfied with the service details.',
    'I booked it by mistake.',
  ];

  void _showCancelConfirmationDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(
                Icons.cancel_outlined,
                color: Colors.red[400],
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Are you sure about cancelling\nthis booking?',
              textAlign: TextAlign.center,
              style: AppTextStyle.withColor(
                AppTextStyle.h3,
                Theme.of(context).textTheme.bodyLarge!.color!,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You can always reschedule it.',
              textAlign: TextAlign.center,
              style: AppTextStyle.withColor(
                AppTextStyle.bodySmall,
                isDark ? Colors.grey[400]! : Colors.grey[600]!,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Add logic to actually cancel the booking in the backend
                      Get.to(
                        () => CancelSuccessScreen(booking: widget.booking),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7F1618),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Yes, Cancel',
                      style: AppTextStyle.bodySmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.to(
                      () => BookingRescheduledScreen(booking: widget.booking),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: isDark ? Colors.white70 : Colors.black12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Reschedule',
                      style: AppTextStyle.bodySmall.copyWith(
                        color: Theme.of(context).textTheme.bodySmall!.color,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cancel Booking',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Column(
            children: [
              ...widget.booking.serviceNames.asMap().entries.map((entry) {
                int idx = entry.key;
                String serviceName = entry.value;
                return _BookingDetailsCard(
                  serviceName: serviceName,
                  bookingPrice: widget.booking.price,
                  isFirst: idx == 0,
                  isMultiple: widget.booking.serviceNames.length > 1,
                );
              }),
            ],
          ),
          const SizedBox(height: 24.0),
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
            child: Text(
              'REASON FOR CANCELLATION',
              style: AppTextStyle.withColor(
                AppTextStyle.bodySmall,
                isDark ? Colors.grey[400]! : Colors.grey[600]!,
              ).copyWith(letterSpacing: 0.5),
            ),
          ),
          ..._cancellationReasons.asMap().entries.map((entry) {
            int index = entry.key;
            String reason = entry.value;
            return RadioListTile<int>(
              title: Text(
                reason,
                style: AppTextStyle.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              value: index,
              groupValue: _selectedReason,
              onChanged: (int? value) {
                setState(() {
                  _selectedReason = value;
                });
              },
              activeColor: Theme.of(context).primaryColor,
              contentPadding: EdgeInsets.zero,
            );
          }),
          const SizedBox(height: 16.0),
          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Describe a problem / comment',
              hintStyle: AppTextStyle.withColor(
                AppTextStyle.bodyMedium,
                isDark ? Colors.grey[600]! : Colors.grey[400]!,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50.0,
              child: ElevatedButton(
                onPressed: () => _showCancelConfirmationDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Cancel Now',
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

class _BookingDetailsCard extends StatelessWidget {
  final String serviceName;
  final double bookingPrice;
  final bool isFirst;
  final bool isMultiple;

  const _BookingDetailsCard({
    required this.serviceName,
    required this.bookingPrice,
    required this.isFirst,
    required this.isMultiple,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ProductController productController = Get.find<ProductController>();

    // Find the product associated with the service name to get the image.
    // This is a workaround because the Booking model only stores service names with sizes.
    final cleanServiceName = serviceName.split(' (').first;
    final product = productController.allProducts.firstWhere(
      (p) => p.name == cleanServiceName,
      orElse: () => productController.allProducts.first, // Fallback
    );

    // Extract size from serviceName to find the individual price
    final sizeMatch = RegExp(r'\((.*?)\)').firstMatch(serviceName);
    final size = sizeMatch?.group(1);
    double? individualPrice;
    if (size != null && product.prices.containsKey(size)) {
      individualPrice = product.prices[size];
    }

    // If it's a single service booking, we can use the total booking price.
    // Otherwise, we rely on finding the individual price.
    final priceToShow = !isMultiple ? bookingPrice : individualPrice;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              product.imageUrl,
              fit: BoxFit.cover,
              width: 100,
              height: 100,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceName,
                      style: AppTextStyle.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (priceToShow != null) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        priceToShow.toStringAsFixed(2),
                        style: AppTextStyle.h3,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
