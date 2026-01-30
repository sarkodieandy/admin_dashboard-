import '../../domain/entities/review.dart';

class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.rating,
    required this.createdAt,
    this.comment,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      userId: json['user_id'] as String,
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String orderId;
  final String userId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  Review toEntity() => Review(
        id: id,
        orderId: orderId,
        userId: userId,
        rating: rating,
        comment: comment,
        createdAt: createdAt,
      );
}

