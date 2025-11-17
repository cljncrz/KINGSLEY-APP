import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceFeedback {
  final String id;
  final String userId;
  final String bookingId;
  final double rating;
  final String comment;
  final DateTime createdAt;

  ServiceFeedback({
    required this.id,
    required this.userId,
    required this.bookingId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ServiceFeedback.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceFeedback(
      id: doc.id,
      userId: data['userId'] ?? '',
      bookingId: data['bookingId'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] ?? '',
      createdAt:
          (data['feedbackCreatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
