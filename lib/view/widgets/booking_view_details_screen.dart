import 'package:capstone/models/booking.dart';
import 'package:capstone/controllers/product_controller.dart';
import 'package:capstone/utils/app_textstyles.dart';
import 'package:flutter/material.dart';
import 'package:capstone/controllers/custom_bottom_navbar.dart';
import 'package:get/get.dart';
import 'package:capstone/view/widgets/booking_cancel_screen.dart';

class ViewDetailsScreen extends StatelessWidget {
  final Booking booking;

  const ViewDetailsScreen({super.key, required this.booking});

  void _showCancelConfirmationDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool canCancel = booking.status == 'Pending';

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
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(
                canCancel ? Icons.warning_amber_rounded : Icons.info_outline,
                color: Colors.red[400],
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              canCancel ? 'Confirm Cancellation' : 'Cannot Cancel Booking',
              textAlign: TextAlign.center,
              style: AppTextStyle.withColor(
                AppTextStyle.h3,
                Theme.of(context).textTheme.bodyLarge!.color!,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              canCancel
                  ? 'Bookings can only be canceled within 24 hours and before admin approval. Do you want to proceed?'
                  : 'This booking has been approved by the admin and can no longer be canceled. You may reschedule it instead.',
              textAlign: TextAlign.center,
              style: AppTextStyle.withColor(
                AppTextStyle.bodySmall,
                isDark ? Colors.grey[400]! : Colors.grey[600]!,
              ),
            ),
            const SizedBox(height: 24),
            if (canCancel)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7F1618),
                      ),
                      child: Text(
                        'Back',
                        style: AppTextStyle.buttonMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Get.to(() => CancelBookingScreen(booking: booking)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7F1618),
                      ),
                      child: Text(
                        'Proceed',
                        style: AppTextStyle.buttonMedium.copyWith(
                          color: Colors.white,
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
          'Booking Details',
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
              ...booking.serviceNames.asMap().entries.map((entry) {
                int idx = entry.key;
                String serviceName = entry.value;
                return _BookingDetailsCard(
                  serviceName: serviceName,
                  bookingPrice: booking.price,
                  isFirst: idx == 0,
                  isMultiple: booking.serviceNames.length > 1,
                );
              }),
            ],
          ),
          const SizedBox(height: 24.0),
          Card(
            elevation: 2,
            shadowColor: isDark
                ? Colors.black.withOpacity(0.5)
                : Colors.grey.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildDetailRow(
                    context,
                    icon: Icons.calendar_today_outlined,
                    label: 'Date', // Use formattedDate from the Booking model
                    value: Text(
                      booking.bookingDate,
                      style: AppTextStyle.bodySmall,
                    ),
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    context,
                    icon: Icons.access_time_outlined,
                    label: 'Time', // Use formattedTime from the Booking model
                    value: Text(
                      booking.bookingTime,
                      style: AppTextStyle.bodySmall,
                    ),
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    context,
                    icon: Icons.payment_outlined,
                    label: 'Payment',
                    value: Text('Cash on Hand', style: AppTextStyle.bodySmall),
                  ), // Example
                  const Divider(height: 24),
                  _buildDetailRow(
                    context,
                    icon: Icons.monetization_on_outlined,
                    label: 'Total Amount',
                    value: Text(
                      booking.price.toStringAsFixed(2),
                      style: AppTextStyle.bodySmall,
                    ),
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    context,
                    icon: Icons.person_outline,
                    label: 'Technician',
                    value: Text(
                      booking.technician ?? 'Awaiting',
                      style: AppTextStyle.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showCancelConfirmationDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel Booking',
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
          const CustomBottomNavbar(),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Widget value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).textTheme.bodySmall!.color,
          size: 20,
        ),
        const SizedBox(width: 16.0),
        Text(
          label,
          style: AppTextStyle.withColor(
            AppTextStyle.bodyMedium,
            Theme.of(context).textTheme.bodySmall!.color!,
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Align(alignment: Alignment.centerRight, child: value),
        ),
      ],
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
                    const SizedBox(height: 4.0),
                    if (priceToShow != null)
                      Text(
                        priceToShow.toStringAsFixed(2),
                        style: AppTextStyle.h3,
                      ),
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
