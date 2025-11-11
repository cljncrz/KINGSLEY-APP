class Technician {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final int reviews;
  final List<String> servicesOffered;
  final String description;

  Technician({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.reviews,
    required this.servicesOffered,
    required this.description,
  });
}
