import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:capstone/models/walkin.dart';
import 'package:flutter/foundation.dart';

class WalkinService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches walk-in bookings from the walkins collection
  /// Returns up to [limit] bookings (default: 4)
  /// Excludes cancelled bookings
  Future<List<Walkin>> getWalkinBookings({int limit = 4}) async {
    try {
      final query = await _firestore.collection('walkins').limit(limit).get();

      final walkins = query.docs
          .map(
            (doc) => Walkin.fromSnapshot(
              doc as DocumentSnapshot<Map<String, dynamic>>,
            ),
          )
          .toList();

      // Filter out cancelled bookings
      final filteredWalkins = walkins
          .where((w) => w.status != 'Cancelled')
          .toList();

      // Sort by date and time in Dart
      filteredWalkins.sort((a, b) {
        int dateCompare = a.bookingDate.compareTo(b.bookingDate);
        if (dateCompare != 0) return dateCompare;
        return a.bookingTime.compareTo(b.bookingTime);
      });

      return filteredWalkins;
    } catch (e) {
      debugPrint('Error fetching walk-in bookings: $e');
      return [];
    }
  }

  /// Streams walk-in bookings in real-time
  /// Useful for real-time updates
  /// Filters for PENDING, IN PROGRESS, and COMPLETED bookings
  Stream<List<Walkin>> getWalkinBookingsStream({int limit = 4}) {
    return _firestore.collection('walkins').snapshots().map((snapshot) {
      debugPrint(
        'Stream received ${snapshot.docs.length} documents from walkins collection',
      );

      // Map Firestore docs to Walkin objects
      final walkins = snapshot.docs.map((doc) {
        final data = doc.data();
        debugPrint('Doc ID: ${doc.id}, Data: $data');
        return Walkin.fromSnapshot(
          doc as DocumentSnapshot<Map<String, dynamic>>,
        );
      }).toList();

      debugPrint('Parsed walkins: ${walkins.length}');
      walkins.forEach((w) {
        debugPrint(
          '  - ID: ${w.id}, Services: ${w.serviceNames}, Status: ${w.status}',
        );
      });

      // Filter for PENDING, IN PROGRESS, and COMPLETED bookings (exclude Cancelled)
      final filteredWalkins = walkins
          .where(
            (w) =>
                w.status == 'Pending' ||
                w.status == 'In Progress' ||
                w.status == 'Completed',
          )
          .toList();

      debugPrint(
        'After filtering for Pending, In Progress, and Completed: ${filteredWalkins.length} walkins',
      );

      // Sort by date and time
      filteredWalkins.sort((a, b) {
        int dateCompare = a.bookingDate.compareTo(b.bookingDate);
        if (dateCompare != 0) return dateCompare;
        return a.bookingTime.compareTo(b.bookingTime);
      });

      // Return only first [limit] items
      final result = filteredWalkins.take(limit).toList();
      debugPrint('Returning ${result.length} walkins to UI');
      return result;
    });
  }

  /// Checks if there are any pending walk-in bookings
  Future<bool> hasPendingWalkins() async {
    try {
      final query = await _firestore
          .collection('walkins')
          .where('status', isEqualTo: 'Pending')
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking pending walkins: $e');
      return false;
    }
  }

  /// Updates booking status
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await _firestore.collection('walkins').doc(bookingId).update({
        'status': newStatus,
      });
    } catch (e) {
      debugPrint('Error updating booking status: $e');
    }
  }

  /// Adds a new walk-in booking
  Future<String?> addWalkinBooking(Walkin walkin) async {
    try {
      final docRef = await _firestore
          .collection('walkins')
          .add(walkin.toJson());
      debugPrint('Walk-in booking added with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding walk-in booking: $e');
      return null;
    }
  }

  /// Checks and logs all documents in walkins collection (for debugging)
  Future<void> debugLogAllWalkins() async {
    try {
      final snapshot = await _firestore.collection('walkins').get();
      debugPrint('====== DEBUG: Walkins Collection ======');
      debugPrint('Total documents: ${snapshot.docs.length}');

      for (var doc in snapshot.docs) {
        debugPrint('Doc ${doc.id}: ${doc.data()}');
      }
      debugPrint('======================================');
    } catch (e) {
      debugPrint('Error debugging walkins: $e');
    }
  }

  /// Fixes existing walkin documents by adding missing serviceNames, dates, times
  Future<void> fixWalkinsData() async {
    try {
      final snapshot = await _firestore.collection('walkins').get();
      final todayDate = DateTime.now().toString().split(' ')[0];
      final currentTime = DateTime.now();
      final currentTimeStr =
          '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}';

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final updates = <String, dynamic>{};

        // If serviceNames is missing or empty, add a default
        if ((data['serviceNames'] as List?)?.isEmpty ?? true) {
          updates['serviceNames'] = ['Service'];
          debugPrint('Fixed doc ${doc.id}: added serviceNames');
        }

        // If bookingDate is missing, add today's date
        if ((data['bookingDate'] as String?)?.isEmpty ?? true) {
          updates['bookingDate'] = todayDate;
          debugPrint('Fixed doc ${doc.id}: added bookingDate');
        }

        // If bookingTime is missing, add current time
        if ((data['bookingTime'] as String?)?.isEmpty ?? true) {
          updates['bookingTime'] = currentTimeStr;
          debugPrint('Fixed doc ${doc.id}: added bookingTime');
        }

        if (updates.isNotEmpty) {
          await _firestore.collection('walkins').doc(doc.id).update(updates);
        }
      }
    } catch (e) {
      debugPrint('Error fixing walkins data: $e');
    }
  }

  /// Adds test/demo walk-in booking data (for development/testing)
  Future<void> addTestWalkinData() async {
    try {
      // Add multiple test walk-ins with different statuses and services
      final testWalkinsData = [
        {
          'serviceNames': ['Full Car Wash'],
          'bookingDate': DateTime.now().toString().split(' ')[0],
          'bookingTime': '09:00',
          'status': 'Pending',
          'price': 100.0,
        },
        {
          'serviceNames': ['Hydrophobic & Engine Wash'],
          'bookingDate': DateTime.now().toString().split(' ')[0],
          'bookingTime': '10:30',
          'status': 'In Progress',
          'price': 150.0,
        },
        {
          'serviceNames': ['Interior Detailing'],
          'bookingDate': DateTime.now().toString().split(' ')[0],
          'bookingTime': '11:00',
          'status': 'Completed',
          'price': 200.0,
        },
        {
          'serviceNames': ['Paint Protection'],
          'bookingDate': DateTime.now().toString().split(' ')[0],
          'bookingTime': '14:00',
          'status': 'Pending',
          'price': 250.0,
        },
      ];

      for (var data in testWalkinsData) {
        await _firestore.collection('walkins').add(data);
        debugPrint('Added test walkin: $data');
      }

      debugPrint('Test walk-in data added successfully to walkins collection');
    } catch (e) {
      debugPrint('Error adding test walk-in data: $e');
    }
  }
}
