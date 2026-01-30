import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/review_supabase_datasource.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  ReviewRepositoryImpl(this._datasource);

  final ReviewSupabaseDatasource _datasource;

  @override
  Future<Review?> fetchMyReviewForOrder({required String orderId}) async {
    final model = await _datasource.fetchMyReviewForOrder(orderId: orderId);
    return model?.toEntity();
  }

  @override
  Future<Review> createReview({
    required String orderId,
    required int rating,
    required String? comment,
    required List<ReviewItemDraft> items,
  }) async {
    final review = await _datasource.createReview(orderId: orderId, rating: rating, comment: comment);
    await _datasource.createReviewItems(
      reviewId: review.id,
      items: items
          .map(
            (i) => {
              'item_id': i.itemId,
              'rating': i.rating,
              'comment': i.comment,
            },
          )
          .toList(),
    );
    return review.toEntity();
  }
}

