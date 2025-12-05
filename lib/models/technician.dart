class Review {
  final String id;
  final String userName;
  final String userAvatarUrl;
  final double rating;
  final String comment;

  Review({
    required this.id,
    required this.userName,
    required this.userAvatarUrl,
    required this.rating,
    required this.comment,
  });
}

class Technician {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final int reviews;
  final List<String> servicesOffered;
  final String description;
  final List<Review> userReviews;
  final String role;
  final String status;

  Technician({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.reviews,
    required this.servicesOffered,
    required this.description,
    this.userReviews = const [],
    this.role = 'Technician',
    this.status = 'active',
  });

  // Factory constructor to create Technician from Firestore document
  factory Technician.fromFirestore(Map<String, dynamic> data, String docId) {
    // Try multiple field names for photo URL
    final photoUrl =
        data['photo'] ??
        data['photoUrl'] ??
        data['photo_url'] ??
        data['image'] ??
        data['imageUrl'] ??
        data['image_url'] ??
        'assets/images/logo.png';

    return Technician(
      id: docId,
      name: data['name'] ?? '',
      imageUrl: photoUrl,
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviews: data['reviews'] ?? 0,
      servicesOffered: List<String>.from(data['servicesOffered'] ?? []),
      description: data['description'] ?? '',
      role: data['role'] ?? 'Technician',
      status: data['status'] ?? 'active',
      userReviews: data['userReviews'] != null
          ? (data['userReviews'] as List)
                .map(
                  (review) => Review(
                    id: review['id'] ?? '',
                    userName: review['userName'] ?? '',
                    userAvatarUrl: review['userAvatarUrl'] ?? '',
                    rating: (review['rating'] ?? 0.0).toDouble(),
                    comment: review['comment'] ?? '',
                  ),
                )
                .toList()
          : [],
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'photo': imageUrl,
      'rating': rating,
      'reviews': reviews,
      'servicesOffered': servicesOffered,
      'description': description,
      'role': role,
      'status': status,
    };
  }
}
