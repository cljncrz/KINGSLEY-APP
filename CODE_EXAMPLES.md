# Code Examples & Reference

## Quick Reference Guide for Walk-In Services Implementation

### 1. Using WalkinService Directly

```dart
import 'package:capstone/services/walkin_service.dart';

final walkinService = WalkinService();

// Get one-time fetch
List<Booking> bookings = await walkinService.getWalkinBookings();

// Get real-time stream
walkinService.getWalkinBookingsStream().listen((bookings) {
  print('Updated bookings: ${bookings.length}');
});

// Check for pending
bool hasPending = await walkinService.hasPendingWalkins();

// Update status
await walkinService.updateBookingStatus('docId', 'Completed');
```

### 2. StreamBuilder Pattern Used

```dart
StreamBuilder<List<Booking>>(
  stream: _walkinService.getWalkinBookingsStream(limit: 4),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      // Show loading
      return LoadingWidget();
    }
    
    if (snapshot.hasError) {
      // Show error
      return ErrorWidget();
    }
    
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      // Show empty state
      return EmptyWidget();
    }
    
    // Show data
    return DataWidget(snapshot.data!);
  },
)
```

### 3. Service Card Widget

```dart
InkWell(
  onTap: () => _showBookingDetailsDialog(context, booking),
  child: Container(
    decoration: BoxDecoration(
      color: Theme.of(context).primaryColor,
      border: Border.all(color: statusColor, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        // Service info
        Text(booking.serviceNames[0]),
        // Status badge
        Container(
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(booking.status),
        ),
      ],
    ),
  ),
)
```

### 4. Pull-to-Refresh Pattern

```dart
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GlobalKey<RefreshIndicatorState> _refreshKey;

  @override
  void initState() {
    super.initState();
    _refreshKey = GlobalKey<RefreshIndicatorState>();
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {}); // StreamBuilder will refresh
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Content with StreamBuilder
          ],
        ),
      ),
    );
  }
}
```

### 5. Booking Details Dialog

```dart
void _showBookingDetailsDialog(BuildContext context, Booking booking) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Booking Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Booking ID', booking.id ?? 'N/A'),
              _buildDetailRow('Service', booking.serviceNames.join(', ')),
              _buildDetailRow('Status', booking.status),
              _buildDetailRow('Date', booking.bookingDate),
              _buildDetailRow('Time', booking.bookingTime),
              _buildDetailRow('Price', '\$${booking.price}'),
              _buildDetailRow('Car', booking.carName ?? 'N/A'),
              _buildDetailRow('Plate', booking.plateNumber ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

Widget _buildDetailRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      Text(value),
    ],
  );
}
```

### 6. Status Color Logic

```dart
Color getStatusColor(String status) {
  switch (status) {
    case 'Pending':
      return Colors.orange;
    case 'In Progress':
      return Colors.blue;
    case 'Completed':
      return Colors.green;
    default:
      return Colors.grey;
  }
}
```

### 7. Empty State Card

```dart
Widget _buildNoDataCard(bool isDark, String text) {
  return Container(
    decoration: BoxDecoration(
      color: Theme.of(context).primaryColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.grey.withOpacity(0.3),
      ),
    ),
    child: Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey),
      ),
    ),
  );
}
```

### 8. Querying Firestore for Walk-Ins

```dart
// Get all pending walk-ins
FirebaseFirestore.instance
  .collection('walkins')
  .where('status', isEqualTo: 'Pending')
  .get();

// Get first 4 bookings
FirebaseFirestore.instance
  .collection('walkins')
  .where('status', whereIn: ['Pending', 'In Progress'])
  .orderBy('bookingDate')
  .orderBy('bookingTime')
  .limit(4)
  .get();

// Real-time stream
FirebaseFirestore.instance
  .collection('walkins')
  .where('status', whereIn: ['Pending', 'In Progress', 'Completed'])
  .snapshots()
  .map((snapshot) => snapshot.docs
    .map((doc) => Booking.fromSnapshot(doc))
    .toList());
```

### 9. Adding a New Card Programmatically

```dart
// To add a new booking card, just add to Firestore:
await FirebaseFirestore.instance.collection('walkins').add({
  'userId': 'user123',
  'serviceNames': ['Hydrophobic Wash'],
  'bookingDate': '2025-11-24',
  'bookingTime': '14:30',
  'status': 'Pending',
  'price': 150.0,
  'carName': 'Honda Civic',
  'carType': 'Sedan',
  'plateNumber': 'ABC123',
  'phoneNumber': '+1234567890',
  'technician': 'John Doe',
  'paymentMethod': 'Credit Card'
});
// The StreamBuilder will automatically reflect this new booking!
```

### 10. Updating Booking Status

```dart
// In WalkinService or directly:
await FirebaseFirestore.instance
  .collection('walkins')
  .doc(bookingId)
  .update({
    'status': 'In Progress',
    // or 'Completed'
  });
// The UI updates in real-time!
```

## Common Modifications

### Change number of displayed cards
```dart
// In onsite_services.dart, line with:
stream: _walkinService.getWalkinBookingsStream(limit: 4), // Change 4 to desired number
```

### Add more columns to grid
```dart
GridView.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3, // Change from 2 to 3
    // ...
  ),
)
```

### Change card height
```dart
gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  // ...
  childAspectRatio: 1.2, // Change from 1.5 to 1.2
)
```

### Customize status colors
```dart
if (booking.status == 'Pending') {
  statusColor = Colors.orange;
} else if (booking.status == 'In Progress') {
  statusColor = Colors.blue;
} else if (booking.status == 'Completed') {
  statusColor = Colors.green;
}
```

### Add custom field display
```dart
_buildDetailRow('Custom Field', booking.customField ?? 'N/A'),
```

## Testing

### Manual Testing Checklist
- [ ] Cards load on app start
- [ ] Add new booking in Firestore → card appears instantly
- [ ] Update booking status → color badge updates
- [ ] Pull down to refresh → works smoothly
- [ ] Click card → dialog shows full details
- [ ] No bookings → shows "No Walk-In Customers"
- [ ] Theme toggle → colors adapt (light/dark)

### Test Data Template
```json
{
  "userId": "test_user",
  "serviceNames": ["Test Service"],
  "bookingDate": "2025-11-24",
  "bookingTime": "15:00",
  "status": "Pending",
  "price": 100.0,
  "carName": "Test Car",
  "carType": "Sedan",
  "plateNumber": "TEST123",
  "phoneNumber": "+9876543210",
  "technician": "Test Tech",
  "paymentMethod": "Cash"
}
```
