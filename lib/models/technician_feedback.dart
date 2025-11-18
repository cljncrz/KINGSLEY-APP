import 'package:cloud_firestore/cloud_firestore.dart';

class TechnicianFeedback {
  String? id;
  final String bookingId;
  final String userId;
  final String technicianName;
  final double rating;
  final String? comment;
  final DateTime createdAt;
  final String? adminReply;
  final DateTime? adminReplyDate;

  TechnicianFeedback({
    this.id,
    required this.bookingId,
    required this.userId,
    required this.technicianName,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.adminReply,
    this.adminReplyDate,
  });

  factory TechnicianFeedback.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TechnicianFeedback(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      userId: data['userId'] ?? '',
      technicianName: data['technicianName'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'],
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
          (data['feedbackCreatedAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      adminReply: data['adminReply'],
      adminReplyDate: (data['adminReplyDate'] as Timestamp?)?.toDate(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'userId': userId,
      'technicianName': technicianName,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
