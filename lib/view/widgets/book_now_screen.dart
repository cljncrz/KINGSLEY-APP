import 'package:capstone/utils/app_textstyles.dart';
import 'package:capstone/controllers/custom_bottom_navbar.dart';
import 'package:capstone/models/product.dart';
import 'package:capstone/controllers/booking_controller.dart';
import 'package:capstone/models/booking.dart';
import 'package:capstone/view/booking_successful_screen.dart';
import 'package:capstone/screens/signup/signup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class BookNowScreen extends StatefulWidget {
  final Product product;
  final String selectedSize;
  final double selectedPrice;

  const BookNowScreen({
    super.key,
    required this.product,
    required this.selectedSize,
    required this.selectedPrice,
  });

  @override
  State<BookNowScreen> createState() => _BookNowScreenState();
}

class TimeSlot {
  final TimeOfDay start;
  final TimeOfDay end;

  const TimeSlot({required this.start, required this.end});

  String format(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatTimeOfDay(start)} - ${localizations.formatTimeOfDay(end)}';
  }
}

class _BookNowScreenState extends State<BookNowScreen> {
  String _selectedPaymentMethod = 'Cash on Hand'; // Default selection
  DateTime? _selectedDate;
  TimeSlot? _selectedTimeSlot;
  final _carTypeController = TextEditingController();
  final _carNameController = TextEditingController();
  final _plateNumberController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final BookingController bookingController = Get.find<BookingController>();
  late final Map<DateTime, List<TimeSlot>>
  _availableSlots; // Keep this for date/time selection
  @override
  void initState() {
    super.initState();
    _availableSlots = _getMockAvailableSlots();
  }

  @override
  void dispose() {
    // Dispose controllers to free up resources
    _carTypeController.dispose();
    _carNameController.dispose();
    _plateNumberController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  // In a real app, this would be fetched from a backend (e.g., Firestore)
  // where an admin would manage these available slots.
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
      today.add(const Duration(days: 1)): slots,
      today.add(const Duration(days: 2)): slots,
      today.add(const Duration(days: 3)): slots,
      today.add(const Duration(days: 4)): slots,
      today.add(const Duration(days: 5)): slots,
    };
  }

  @override
  Widget build(BuildContext context) {
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
          'Book Now',
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
            _buildSingleBookingItem(context),
            const SizedBox(height: 24),
            _buildCarDetailsInput(),
            const SizedBox(height: 24),
            _buildDateTimePicker(),
            const SizedBox(height: 24),
            _buildPaymentSummary(context),
            const SizedBox(height: 24),
            _buildPaymentMethodSelection(context),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildConfirmPaymentButton(context, user),
          const CustomBottomNavbar(),
        ],
      ),
    );
  }

  Widget _buildCarDetailsInput() {
    final bool isMotorcycle = widget.product.name.contains('Motorcycle');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isMotorcycle ? 'Enter Motorcycle Details' : 'Enter Car Details',
          style: AppTextStyle.bodyMedium,
        ),
        const SizedBox(height: 16),
        if (!isMotorcycle) ...[
          TextFormField(
            controller: _carTypeController,
            decoration: InputDecoration(
              labelText: 'Car Type (e.g., SUV, Sedan)',
              prefixIcon: const Icon(Icons.directions_car_filled_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _carNameController,
            decoration: InputDecoration(
              labelText: 'Car Name (e.g., Toyota Fortuner)',
              prefixIcon: const Icon(Icons.drive_eta_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        TextFormField(
          controller: _plateNumberController,
          decoration: InputDecoration(
            labelText: isMotorcycle
                ? 'Plate Number (e.g., 123 ABC)'
                : 'Plate Number (e.g., ABC 1234)',
            prefixIcon: const Icon(Icons.pin_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneNumberController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: const Icon(Icons.phone_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          validator: (value) =>
              value!.isEmpty ? 'Please enter a phone number' : null,
        ),
      ],
    );
  }

  Widget _buildDateTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Booking Date & Time', style: AppTextStyle.bodyMedium),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text(
            _selectedDate == null
                ? 'Select a Date'
                : DateFormat.yMMMMd().format(_selectedDate!),
            style: AppTextStyle.bodySmall,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: _selectDate,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.access_time),
          title: Text(
            _selectedTimeSlot == null
                ? 'Select a Time'
                : _selectedTimeSlot!.format(context),
            style: AppTextStyle.bodySmall,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: _selectedDate == null ? null : _selectTime,
          enabled: _selectedDate != null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? _availableSlots.keys.first,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)), // Look one year ahead
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
        _selectedTimeSlot = null; // Reset time when date changes
      });
    }
  }

  Future<void> _selectTime() async {
    if (_selectedDate == null) return;

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

  Widget _buildSingleBookingItem(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
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
      child: Row(
        children: [
          // product image
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(8),
            ),
            child: Image.asset(
              widget.product.imageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${widget.product.name} (${widget.selectedSize})',
                          style: AppTextStyle.withColor(
                            AppTextStyle.bodyMedium,
                            Theme.of(context).textTheme.bodyMedium!.color!,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.selectedPrice.toStringAsFixed(2),
                        style: AppTextStyle.withColor(
                          AppTextStyle.bodyMedium,
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Removed _showDeleteConfirmationDialog, _buildCartItemsList, _buildCancelButton, _buildRemoveButton
  // as they are not relevant for single item direct booking.
  // The user explicitly stated "do not reflect what i booked in book_now_screen in cart_screen"
  // so these cart-related UI elements are removed.

  Widget _buildPaymentSummary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Summary', style: AppTextStyle.bodyMedium),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal (1 item)', // Always 1 item for Book Now
                style: AppTextStyle.bodyMedium,
              ),
              Text(
                widget.selectedPrice.toStringAsFixed(
                  2,
                ), // Use the single item's price
                style: AppTextStyle.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount', style: AppTextStyle.bodyLarge),
              Text(
                widget.selectedPrice.toStringAsFixed(
                  2,
                ), // Use the single item's price
                style: AppTextStyle.withColor(
                  AppTextStyle.bodyLarge,
                  Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelection(BuildContext context) {
    final paymentMethods = {
      'Cash on Hand':
          'assets/images/cash_on_hand.png', // Placeholder for cash icon. Replace with actual asset path.
      'GCash':
          'assets/images/gcash.png', // Placeholder for GCash logo. Replace with actual asset path.
      'PayMaya':
          'assets/images/paymaya.png', // Placeholder for PayMaya logo. Replace with actual asset path.
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Payment Method', style: AppTextStyle.bodyMedium),
        const SizedBox(height: 16),
        ...paymentMethods.entries.map((entry) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: RadioListTile<String>(
              title: Text(entry.key),
              secondary: Image.asset(
                entry.value,
                width: 24, // Adjust size as needed
                height: 24, // Adjust size as needed
              ), // Fallback for unexpected types
              value: entry.key,
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPaymentMethod = value;
                  });
                }
              },
              activeColor: Theme.of(context).primaryColor,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildConfirmPaymentButton(BuildContext context, User? user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Cancel Button
          Expanded(
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                  0xFF7F1618,
                ), // Consistent with other action buttons
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Cancel',
                style: AppTextStyle.withColor(
                  AppTextStyle.buttonMedium,
                  Colors.white, // Text color for contrast
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              // Pay Button
              onPressed: () {
                if (user == null) {
                  _showGuestSignUpDialog(context);
                } else {
                  // Renamed from _handleBooking to be inline
                  if (_selectedDate == null || _selectedTimeSlot == null) {
                    Get.snackbar(
                      'Incomplete Booking',
                      'Please select a date and time for your booking.',
                      titleText: Text(
                        'Incomplete Booking',
                        style: AppTextStyle.withColor(
                          AppTextStyle.h3,
                          isDark ? const Color(0xFF7F1618) : Colors.white,
                        ),
                      ),
                      messageText: Text(
                        'Please select a date and time for your booking.',
                        style: AppTextStyle.withColor(
                          AppTextStyle.bodySmall,
                          isDark ? const Color(0xFF7F1618) : Colors.white,
                        ),
                      ),
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: isDark
                          ? Colors.white
                          : const Color(0xFF7F1618),
                      colorText: isDark
                          ? Colors.white
                          : const Color(0xFF7F1618),
                    );
                    return;
                  }

                  if (_selectedPaymentMethod == 'Cash on Hand') {
                    // In a real app, you would save the booking to a database here
                    // and trigger a notification for the user and admin.
                    final String formattedDate = DateFormat.yMMMMd().format(
                      _selectedDate!,
                    );
                    final String formattedTime = _selectedTimeSlot!.format(
                      context,
                    );

                    final newBooking = Booking(
                      userId: user.uid,
                      serviceNames: [
                        '${widget.product.name} (${widget.selectedSize})',
                      ],
                      bookingDate: formattedDate,
                      bookingTime: formattedTime,
                      price: widget.selectedPrice,
                      carType: _carTypeController.text.trim(),
                      carName: _carNameController.text.trim(),
                      plateNumber: _plateNumberController.text.trim(),
                      phoneNumber: _phoneNumberController.text.trim(),
                      paymentMethod: _selectedPaymentMethod,
                    );

                    bookingController.addBooking(
                      newBooking,
                      paymentMethod: _selectedPaymentMethod,
                    );
                    // The item booked via "Book Now" is not added to the cart, so no need to clear cartController.cartItems.
                    Get.offAll(() => const BookingSuccessfulScreen());
                  } else {
                    // TODO: Implement other payment methods like GCash or PayMaya
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Pay',
                style: AppTextStyle.withColor(
                  AppTextStyle.buttonMedium,
                  Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGuestSignUpDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Sign Up to Book',
              style: AppTextStyle.withColor(
                AppTextStyle.h2,
                isDark ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please sign up or log in to complete your booking.',
              style: AppTextStyle.withColor(
                AppTextStyle.bodyMedium,
                isDark ? Colors.grey[500]! : Colors.grey[600]!,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7F1618),
                    ),
                    onPressed: () => Get.back(),
                    child: Text(
                      'Cancel',
                      style: AppTextStyle.withColor(
                        AppTextStyle.buttonMedium,
                        Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7F1618),
                    ),
                    onPressed: () => Get.to(() => const SignupScreen()),
                    child: Text(
                      'Sign Up',
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
}
