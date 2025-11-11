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

  Technician({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.reviews,
    required this.servicesOffered,
    required this.description,
    this.userReviews = const [],
  });
}
