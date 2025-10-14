class Product {
  final String id;
  final String title;
  final String subtitle;
  final double price;
  final String? imageUrl;
  final int? calories; // calories (e.g., 320)
  final int? cookTimeMinutes; // cook/prep time in minutes (e.g., 15)
  final String? category;

  Product({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    this.imageUrl,
    this.calories,
    this.cookTimeMinutes,
    this.category,
  });
}
