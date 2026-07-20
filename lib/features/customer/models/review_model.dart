/// ReviewModel
/// Data model for customer review records.
class ReviewModel {
  final int id;
  final int rating;
  final String? comment;
  final String? customerName;
  final String? createdAt;

  ReviewModel({
    required this.id,
    required this.rating,
    this.comment,
    this.customerName,
    this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      rating: json['rating'] is int ? json['rating'] : int.parse(json['rating'].toString()),
      comment: json['comment'],
      customerName: json['customer_name'],
      createdAt: json['created_at'],
    );
  }
}
