import 'package:capstone/utils/app_textstyles.dart';
import 'package:capstone/controllers/cart_controller.dart';
import 'package:capstone/controllers/booking_controller.dart';
import 'package:capstone/view/booking_successful_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:capstone/screens/signup/signup_screen.dart';
import 'package:capstone/controllers/custom_bottom_navbar.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:capstone/models/booking.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
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

class _CartScreenState extends State<CartScreen> {
  String _selectedPaymentMethod = 'Cash on Hand'; // Default selection
  final _carTypeController = TextEditingController();
  final _carNameController = TextEditingController();
  final _plateNumberController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  DateTime? _selectedDate;
  TimeSlot? _selectedTimeSlot;
  late final Map<DateTime, List<TimeSlot>> _availableSlots;

  final CartController cartController = Get.find<CartController>();
  final BookingController bookingController = Get.find<BookingController>();

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
  Map<DateTime, List<TimeSlot>> _getMockAvailableSlots({
    int numberOfServices = 1,
  }) {
    final now = DateTime.now();
    // Normalize dates to midnight to avoid time-based comparison issues.
    final today = DateTime(now.year, now.month, now.day);

    const List<TimeSlot> generatedSlots = [
      TimeSlot(
        start: TimeOfDay(hour: 8, minute: 20),
        end: TimeOfDay(hour: 10, minute: 20),
      ),
      TimeSlot(
        start: TimeOfDay(hour: 10, minute: 20),
        end: TimeOfDay(hour: 12, minute: 20),
      ),
      TimeSlot(
        start: TimeOfDay(hour: 13, minute: 30),
        end: TimeOfDay(hour: 15, minute: 30),
      ),
      TimeSlot(
        start: TimeOfDay(hour: 15, minute: 30),
        end: TimeOfDay(hour: 17, minute: 30),
      ),
      TimeSlot(
        start: TimeOfDay(hour: 17, minute: 30),
        end: TimeOfDay(hour: 19, minute: 30),
      ),
      TimeSlot(
        start: TimeOfDay(hour: 19, minute: 30),
        end: TimeOfDay(hour: 21, minute: 30),
      ),
    ];

    return {
      // For demonstration, making slots available for the next 7 days.
      // In a real app, this data would come from your admin panel.
      today.add(const Duration(days: 1)): generatedSlots,
      today.add(const Duration(days: 2)): generatedSlots,
      today.add(const Duration(days: 3)): generatedSlots,
      today.add(const Duration(days: 4)): generatedSlots,
      today.add(const Duration(days: 5)): generatedSlots,
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
          'Book Services Cart',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: user == null
          ? _buildGuestView(context)
          : Obx(() {
              if (cartController.cartItems.isEmpty) {
                return Center(
                  child: Text(
                    'Your Book Cart is empty.',
                    style: AppTextStyle.withColor(
                      AppTextStyle.h3,
                      Theme.of(context).textTheme.bodyLarge!.color!,
                    ),
                  ),
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListView.builder(
                      // Added padding to the bottom of the ListView to ensure content
                      // doesn't get cut off by the bottom navigation bar.
                      padding: const EdgeInsets.only(bottom: 16.0),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cartController.cartItems.length,
                      itemBuilder: (context, index) => _buildCartItem(
                        context,
                        cartController.cartItems[index],
                      ),
                    ),
                    _buildCarDetailsInput(),
                    const SizedBox(height: 24),
                    _buildDateTimePicker(),
                    const SizedBox(height: 24),
                    const SizedBox(height: 24),
                    _buildPaymentSummary(context),
                    const SizedBox(height: 24),
                    _buildPaymentMethodSelection(context),
                  ],
                ),
              );
            }),
      bottomNavigationBar: user == null
          ? const CustomBottomNavbar()
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(
                  () => cartController.cartItems.isEmpty
                      ? const SizedBox.shrink()
                      : _buildConfirmPaymentButton(context, user),
                ),
                const CustomBottomNavbar(),
              ],
            ),
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
              Icons.shopping_cart_outlined,
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
              'Sign up or log in to book services.',
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

  Widget _buildCarDetailsInput() {
    // If any item is for a motorcycle, we assume it's a motorcycle booking.
    // A more complex implementation could handle mixed carts.
    final bool isMotorcycle = cartController.cartItems.any(
      (item) => item.product.name.contains('Motorcycle'),
    );

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

    final availableTimes =
        _getMockAvailableSlots(
          numberOfServices: cartController.cartItems.length,
        )[_selectedDate] ??
        [];

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

  Widget _buildCartItem(BuildContext context, CartItem cartItem) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.3),
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
              cartItem.product.imageUrl,
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
                          '${cartItem.product.name} (${cartItem.selectedSize})',
                          style: AppTextStyle.withColor(
                            AppTextStyle.bodySmall,
                            Theme.of(context).textTheme.bodyMedium!.color!,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            _showDeleteConfirmationDialog(context, cartItem),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFF7F1618),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        cartItem.price.toStringAsFixed(2),
                        style: AppTextStyle.withColor(
                          AppTextStyle.h3,
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

  void _showDeleteConfirmationDialog(BuildContext context, CartItem cartItem) {
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[400]!.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline,
                color: const Color(0xFF7F1618),
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Remove ${cartItem.product.name} from cart?',
              textAlign: TextAlign.center,
              style: AppTextStyle.withColor(
                AppTextStyle.bodyMedium,
                isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to remove this from your bookcart',
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
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7F1618),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTextStyle.bodySmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      cartController.removeFromCart(cartItem);
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7F1618),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Remove',
                      style: AppTextStyle.withColor(
                        AppTextStyle.bodySmall,
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
                'Subtotal (${cartController.cartItems.length})',
                style: AppTextStyle.bodyMedium,
              ),
              Text(
                cartController.total.toStringAsFixed(2),
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
                cartController.total.toStringAsFixed(2),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        Text(
          'Select Payment Method',
          style: AppTextStyle.withColor(
            AppTextStyle.bodyMedium,
            isDark ? Colors.white : Colors.black,
          ),
        ),
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
          Expanded(
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                  0xFF7F1618,
                ), // Consistent secondary action color
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
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
              onPressed: () async {
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
                  // Format the date and time into strings for the Booking model.
                  final String formattedDate = DateFormat.yMMMMd().format(
                    _selectedDate!,
                  );
                  final String formattedTime = _selectedTimeSlot!.format(
                    context,
                  );

                  final newBooking = Booking(
                    userId: user.uid,
                    serviceNames: cartController.cartItems
                        .map(
                          (item) =>
                              '${item.product.name} (${item.selectedSize})',
                        )
                        .toList(),
                    bookingDate: formattedDate,
                    bookingTime: formattedTime,
                    price: cartController.total,
                    carType: _carTypeController.text.trim(),
                    carName: _carNameController.text.trim(),
                    plateNumber: _plateNumberController.text.trim(),
                    phoneNumber: _phoneNumberController.text.trim(),
                    paymentMethod: _selectedPaymentMethod,
                  );

                  await bookingController.addBooking(
                    newBooking,
                    paymentMethod: _selectedPaymentMethod,
                  );
                  cartController.cartItems.clear();
                  Get.offAll(() => const BookingSuccessfulScreen());
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
                Theme.of(context).textTheme.bodyLarge!.color!,
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
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.to(() => const SignupScreen()),
                    child: const Text('Sign Up'),
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
