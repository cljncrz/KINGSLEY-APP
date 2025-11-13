import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingProgress { started, inProgress, completed }

class Booking {
  final String? id;
  final String userId;
  final List<String> serviceNames;
  final String bookingDate;
  final String bookingTime;
  final String status;
  final double price;
  final String? technician;
  final String? carName;
  final String? carType;
  final String? plateNumber;
  final String? phoneNumber;
  final BookingProgress progress;
  final bool? feedbackGiven;

  Booking({
    this.id,
    required this.userId,
    required this.serviceNames,
    required this.bookingDate,
    required this.bookingTime,
    this.status = 'Pending',
    required this.price,
    this.technician = 'Awaiting',
    this.carName,
    this.carType,
    this.plateNumber,
    this.phoneNumber,
    this.progress = BookingProgress.started,
    this.feedbackGiven = false,
  });

  /// Converts a Booking object into a Map<String, dynamic> for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'serviceNames': serviceNames,
      'bookingDate': bookingDate,
      'bookingTime': bookingTime,
      'status': status,
      'price': price,
      'technician': technician,
      'carName': carName,
      'carType': carType,
      'plateNumber': plateNumber,
      'phoneNumber': phoneNumber,
      'progress': progress.name, // Store enum as a string
      'feedbackGiven': feedbackGiven,
    };
  }

  /// Creates a Booking object from a Firestore DocumentSnapshot.
  factory Booking.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Booking(
      id: doc.id,
      userId: data['userId'],
      serviceNames: List<String>.from(data['serviceNames']),
      bookingDate: data['bookingDate'],
      bookingTime: data['bookingTime'],
      status: data['status'],
      price: (data['price'] as num).toDouble(),
      technician: data['technician'],
      carName: data['carName'],
      carType: data['carType'],
      plateNumber: data['plateNumber'],
      phoneNumber: data['phoneNumber'],
      progress: BookingProgress.values.firstWhere(
        (e) => e.name == data['progress'],
        orElse: () => BookingProgress.started,
      ),
      feedbackGiven: data['feedbackGiven'] ?? false,
    );
  }

  Booking copyWith({
    String? id,
    String? userId,
    List<String>? serviceNames,
    String? bookingDate,
    String? bookingTime,
    String? status,
    double? price,
    String? technician,
    String? carName,
    String? carType,
    String? plateNumber,
    String? phoneNumber,
    BookingProgress? progress,
    bool? feedbackGiven,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serviceNames: serviceNames ?? this.serviceNames,
      bookingDate: bookingDate ?? this.bookingDate,
      bookingTime: bookingTime ?? this.bookingTime,
      status: status ?? this.status,
      price: price ?? this.price,
      technician: technician ?? this.technician,
      carName: carName ?? this.carName,
      carType: carType ?? this.carType,
      plateNumber: plateNumber ?? this.plateNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      progress: progress ?? this.progress,
      feedbackGiven: feedbackGiven ?? this.feedbackGiven,
    );
  }
}
