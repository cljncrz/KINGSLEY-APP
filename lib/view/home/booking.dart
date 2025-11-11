import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum BookingProgress { started, inProgress, completed }

class Booking {
  final String? id;
  final String userId;
  final List<String> serviceNames;
  final DateTime bookingDateTime;
  final String status;
  final double price;
  final String? technician;
  final BookingProgress progress;

  Booking({
    this.id,
    required this.userId,
    required this.serviceNames,
    required this.bookingDateTime,
    this.status = 'Pending',
    required this.price,
    this.technician = 'Awaiting',
    this.progress = BookingProgress.started,
  });

  /// Converts a Booking object into a Map<String, dynamic> for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'serviceNames': serviceNames,
      'bookingDateTime': Timestamp.fromDate(bookingDateTime),
      'status': status,
      'price': price,
      'technician': technician,
      'progress': progress.name, // Store enum as a string
    };
  }

  /// Creates a Booking object from a Firestore DocumentSnapshot.
  factory Booking.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Booking(
      id: doc.id,
      userId: data['userId'],
      serviceNames: List<String>.from(data['serviceNames']),
      bookingDateTime: (data['bookingDateTime'] as Timestamp).toDate(),
      status: data['status'],
      price: (data['price'] as num).toDouble(),
      technician: data['technician'],
      progress: BookingProgress.values.firstWhere(
        (e) => e.name == data['progress'],
        orElse: () => BookingProgress.started,
      ),
    );
  }

  /// Helper to format the date part of bookingDateTime.
  String get formattedDate {
    // Using intl package for formatting
    return DateFormat.yMMMMd().format(bookingDateTime);
  }

  /// Helper to format the time part of bookingDateTime.
  String get formattedTime {
    // Using intl package for formatting
    return DateFormat.jm().format(bookingDateTime);
  }
}
