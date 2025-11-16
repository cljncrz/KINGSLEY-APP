import 'package:capstone/utils/app_textstyles.dart';
import 'package:capstone/models/booking.dart';
import 'package:capstone/controllers/booking_controller.dart';
import 'package:capstone/controllers/product_controller.dart';
import 'package:capstone/view/widgets/booking_rescheduled_success.dart';
import 'package:capstone/view/home/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone/controllers/custom_bottom_navbar.dart';
import 'package:intl/intl.dart';

class BookingRescheduledScreen extends StatefulWidget {
  final Booking booking;
  const BookingRescheduledScreen({super.key, required this.booking});

  @override
  State<BookingRescheduledScreen> createState() =>
      _BookingRescheduledScreenState();
}

class _BookingRescheduledScreenState extends State<BookingRescheduledScreen> {
  late DateTime _selectedDate;
  TimeSlot? _selectedTimeSlot;
  late final Map<DateTime, List<TimeSlot>> _availableSlots;
  final TextEditingController _rescheduleReasonController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    // For simplicity, we'll initialize with the current date and time.
    // A more robust solution would parse the date/time from the booking object.
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _availableSlots = _getMockAvailableSlots();
  }

  @override
  void dispose() {
    _rescheduleReasonController.dispose();
    super.dispose();
  }

  Map<DateTime, List<TimeSlot>> _getMockAvailableSlots() {
    final now = DateTime.now();
    // Normalize dates to midnight to avoid time-based comparison issues.
    final today = DateTime(now.year, now.month, now.day);
    const slots = [
      TimeSlot(
        start: TimeOfDay(hour: 8, minute: 20),
        end: TimeOfDay(hour: 9, minute: 20),
      ),
      TimeSlot(
        start: TimeOfDay(hour: 9, minute: 20),
        end: TimeOfDay(hour: 10, minute: 20),
      ),
      TimeSlot(
        start: TimeOfDay(hour: 10, minute: 20),
        end: TimeOfDay(hour: 11, minute: 20),
      ),
      TimeSlot(
        start: TimeOfDay(hour: 11, minute: 20),
        end: TimeOfDay(hour: 12, minute: 10),
      ),
      TimeSlot(
        start: TimeOfDay(hour: 12, minute: 10),
        end: TimeOfDay(hour: 13, minute: 0),
      ),
      TimeSlot(
        start: TimeOfDay(hour: 13, minute: 20),
        end: TimeOfDay(hour: 14, minute: 20),
      ),
      TimeSlot(
        start: TimeOfDay(hour: 14, minute: 20),
        end: TimeOfDay(hour: 15, minute: 20),
      ),
      TimeSlot(
        start: TimeOfDay(hour: 15, minute: 50),
        end: TimeOfDay(hour: 16, minute: 50),
      ),
      TimeSlot(
        start: TimeOfDay(hour: 16, minute: 50),
        end: TimeOfDay(hour: 17, minute: 50),
      ),
      TimeSlot(
        start: TimeOfDay(hour: 17, minute: 50),
        end: TimeOfDay(hour: 18, minute: 50),
      ),
      TimeSlot(
        start: TimeOfDay(hour: 18, minute: 50),
        end: TimeOfDay(hour: 19, minute: 50),
      ),
      TimeSlot(
        start: TimeOfDay(hour: 19, minute: 50),
        end: TimeOfDay(hour: 20, minute: 50),
      ),
    ];

    return {
      // For demonstration, making slots available for the next 7 days.
      // In a real app, this data would come from your admin panel.
      today.add(const Duration(days: 1)): slots,
      today.add(const Duration(days: 2)): slots,
      today.add(const Duration(days: 3)): slots,
      today.add(const Duration(days: 4)): slots,
      today.add(const Duration(days: 5)): slots,
    };
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (DateTime day) {
        // Allow selection only if the day is in our available slots
        return _availableSlots.keys.any(
          (availableDate) =>
              day.year == availableDate.year &&
              day.month == availableDate.month &&
              day.day == availableDate.day,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final availableTimes = _availableSlots[_selectedDate] ?? [];

    if (availableTimes.isEmpty) {
      Get.snackbar('No Slots', 'No available time slots for this date.');
      return;
    }

    final TimeSlot? picked = await showDialog<TimeSlot>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select a Time'),
          content: SizedBox(
            width: double.minPositive,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableTimes.length,
              itemBuilder: (context, index) {
                final timeSlot = availableTimes[index];
                return ListTile(
                  title: Text(timeSlot.format(context)),
                  onTap: () {
                    Navigator.of(context).pop(timeSlot);
                  },
                );
              },
            ),
          ),
        );
      },
    );
    if (picked != null && picked != _selectedTimeSlot) {
      setState(() {
        _selectedTimeSlot = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBar = AppBar(
      title: Text(
        'Reschedule Booking',
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
    );
    return Scaffold(
      appBar: appBar,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                MediaQuery.of(context).size.height -
                appBar.preferredSize.height -
                kBottomNavigationBarHeight -
                32,
          ), // Adjust for padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Only allow rescheduling when booking status is "pending".
              // If booking has a different status (e.g. approved), we disable inputs and show a notice.
              Builder(
                builder: (context) {
                  final bookingStatus = widget.booking.status
                      .toString()
                      .toLowerCase();
                  final canReschedule = bookingStatus == 'pending';
                  if (!canReschedule) {
                    final statusText = widget.booking.status.toString();
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      margin: const EdgeInsets.only(bottom: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Text(
                              'Reschedule not allowed — booking status: $statusText. Contact support or wait for admin decision.',
                              style: AppTextStyle.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
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
              const Divider(height: 32, thickness: 1),
              Text(
                'Select a new date and time for your booking.',
                style: AppTextStyle.bodyMedium,
              ),
              const SizedBox(height: 24),
              // Date picker disabled when reschedule not allowed.
              ListTile(
                title: Text('New Date', style: AppTextStyle.bodyMedium),
                subtitle: Text(
                  DateFormat.yMMMMd().format(_selectedDate),
                  style: AppTextStyle.withColor(
                    AppTextStyle.h3,
                    Theme.of(context).textTheme.bodyLarge!.color!,
                  ),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () {
                  final bookingStatus = widget.booking.status
                      .toString()
                      .toLowerCase();
                  final canReschedule = bookingStatus == 'pending';
                  if (!canReschedule) {
                    Get.snackbar(
                      'Not allowed',
                      'You cannot reschedule this booking at the moment.',
                    );
                    return;
                  }
                  _selectDate(context);
                },
                enabled:
                    widget.booking.status.toString().toLowerCase() == 'pending',
              ),
              const Divider(),
              ListTile(
                title: Text('New Time', style: AppTextStyle.bodyMedium),
                subtitle: Text(
                  _selectedTimeSlot == null
                      ? 'Select a time slot'
                      : _selectedTimeSlot!.format(context),
                  style: AppTextStyle.withColor(
                    AppTextStyle.h3,
                    Theme.of(context).textTheme.bodyLarge!.color!,
                  ),
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () {
                  final bookingStatus = widget.booking.status
                      .toString()
                      .toLowerCase();
                  final canReschedule = bookingStatus == 'pending';
                  if (!canReschedule) {
                    Get.snackbar(
                      'Not allowed',
                      'You cannot reschedule this booking at the moment.',
                    );
                    return;
                  }
                  _selectTime(context);
                },
                enabled:
                    widget.booking.status.toString().toLowerCase() == 'pending',
              ),
              const SizedBox(height: 24),
              Text('Reason for Rescheduling', style: AppTextStyle.bodyMedium),
              const SizedBox(height: 16),
              TextField(
                controller: _rescheduleReasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g., I have a conflict, need a different time.',
                  hintStyle: AppTextStyle.withColor(
                    AppTextStyle.bodyMedium,
                    isDark ? Colors.grey[600]! : Colors.grey[400]!,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1E1E1E)
                      : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
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
                onPressed: () async {
                  final bookingStatus = widget.booking.status
                      .toString()
                      .toLowerCase();
                  final canReschedule = bookingStatus == 'pending';
                  if (!canReschedule) {
                    Get.snackbar(
                      'Not allowed',
                      'This booking cannot be rescheduled because it is not pending approval.',
                      snackPosition: SnackPosition.TOP,
                    );
                    return;
                  }
                  if (_selectedTimeSlot == null) {
                    Get.snackbar(
                      'Incomplete',
                      'Please select a time slot.',
                      snackPosition: SnackPosition.TOP,
                    );
                    return;
                  }
                  final bookingController = Get.find<BookingController>();
                  await bookingController.rescheduleBooking(
                    bookingId: widget.booking.id!,
                    newDate: _selectedDate,
                    newTime: _selectedTimeSlot!.format(context),
                    reason: _rescheduleReasonController.text,
                  );
                  Get.offAll(
                    () => BookingRescheduledSuccess(
                      booking: widget.booking,
                      newDate: _selectedDate,
                      newTimeSlot: _selectedTimeSlot!,
                      rescheduleReason: _rescheduleReasonController.text,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  'Confirm request Reschedule',
                  style: AppTextStyle.buttonMedium.copyWith(
                    color: Colors.white,
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
