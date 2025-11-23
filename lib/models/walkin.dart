import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Walkin {
  final String? id;
  final List<String> serviceNames;
  final String bookingDate;
  final String bookingTime;
  final String status; // Pending, In Progress, Completed
  final double price;

  Walkin({
    this.id,
    required this.serviceNames,
    required this.bookingDate,
    required this.bookingTime,
    this.status = 'Pending',
    required this.price,
  });

  /// Converts a Walkin object into a Map<String, dynamic> for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'serviceNames': serviceNames,
      'bookingDate': bookingDate,
      'bookingTime': bookingTime,
      'status': status,
      'price': price,
    };
  }

  /// Creates a Walkin object from a Firestore DocumentSnapshot.
  factory Walkin.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    debugPrint('Walkin.fromSnapshot - Raw data: $data');

    // Handle serviceNames - try multiple field names for compatibility
    List<String> serviceNames = [];
    if (data.containsKey('serviceNames')) {
      final sn = data['serviceNames'];
      if (sn is List) {
        serviceNames = List<String>.from(sn.map((e) => e.toString()));
      } else if (sn is String) {
        serviceNames = [sn];
      }
    } else if (data.containsKey('service')) {
      final service = data['service'];
      if (service is List) {
        serviceNames = List<String>.from(service.map((e) => e.toString()));
      } else if (service is String) {
        serviceNames = [service];
      }
    }

    // Handle bookingDate - try multiple field names and provide defaults
    String bookingDate = '';
    if (data.containsKey('bookingDate') &&
        data['bookingDate']?.toString().isNotEmpty == true) {
      bookingDate = data['bookingDate'].toString();
    } else if (data.containsKey('date') &&
        data['date']?.toString().isNotEmpty == true) {
      bookingDate = data['date'].toString();
    } else {
      // Default to today's date if not specified
      bookingDate = DateTime.now().toString().split(' ')[0];
    }

    // Handle bookingTime - try multiple field names and provide defaults
    String bookingTime = '';
    if (data.containsKey('bookingTime') &&
        data['bookingTime']?.toString().isNotEmpty == true) {
      bookingTime = data['bookingTime'].toString();
    } else if (data.containsKey('time') &&
        data['time']?.toString().isNotEmpty == true) {
      bookingTime = data['time'].toString();
    } else {
      // Default to current time if not specified
      final now = DateTime.now();
      bookingTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    }

    final walkin = Walkin(
      id: doc.id,
      serviceNames: serviceNames,
      bookingDate: bookingDate,
      bookingTime: bookingTime,
      status: data['status']?.toString() ?? 'Pending',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
    );

    debugPrint(
      'Walkin.fromSnapshot - Created: id=${walkin.id}, '
      'serviceNames=${walkin.serviceNames}, '
      'date=${walkin.bookingDate}, '
      'time=${walkin.bookingTime}, '
      'status=${walkin.status}',
    );
    return walkin;
  }

  /// Creates a Walkin object from a JSON map.
  factory Walkin.fromJson(Map<String, dynamic> json) {
    return Walkin(
      serviceNames: List<String>.from(json['serviceNames'] ?? []),
      bookingDate: json['bookingDate'] ?? '',
      bookingTime: json['bookingTime'] ?? '',
      status: json['status'] ?? 'Pending',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Creates a copy of this Walkin with some fields replaced.
  Walkin copyWith({
    String? id,
    List<String>? serviceNames,
    String? bookingDate,
    String? bookingTime,
    String? status,
    double? price,
  }) {
    return Walkin(
      id: id ?? this.id,
      serviceNames: serviceNames ?? this.serviceNames,
      bookingDate: bookingDate ?? this.bookingDate,
      bookingTime: bookingTime ?? this.bookingTime,
      status: status ?? this.status,
      price: price ?? this.price,
    );
  }
}
