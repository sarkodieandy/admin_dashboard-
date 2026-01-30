class Review {
  const Review({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.rating,
    required this.createdAt,
    this.comment,
  });

  final String id;
  final String orderId;
  final String userId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
}

class ReviewItemDraft {
  const ReviewItemDraft({
    required this.itemId,
    required this.rating,
    this.comment,
  });

  final String? itemId;
  final int rating;
  final String? comment;
}

