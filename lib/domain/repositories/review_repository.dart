import '../entities/review.dart';

abstract class ReviewRepository {
  Future<Review?> fetchMyReviewForOrder({required String orderId});

  Future<Review> createReview({
    required String orderId,
    required int rating,
    required String? comment,
    required List<ReviewItemDraft> items,
  });
}

