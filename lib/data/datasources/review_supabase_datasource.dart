import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/review_model.dart';

class ReviewSupabaseDatasource {
  ReviewSupabaseDatasource(this._client);

  final SupabaseClient _client;

  Future<ReviewModel?> fetchMyReviewForOrder({required String orderId}) async {
    final data = await _client
        .from('reviews')
        .select('id,order_id,user_id,rating,comment,created_at')
        .eq('order_id', orderId)
        .limit(1);

    final list = (data as List).whereType<Map<String, dynamic>>().toList();
    if (list.isEmpty) return null;
    return ReviewModel.fromJson(list.first);
  }

  Future<ReviewModel> createReview({
    required String orderId,
    required int rating,
    required String? comment,
  }) async {
    final data = await _client
        .from('reviews')
        .insert({
          'order_id': orderId,
          'user_id': _client.auth.currentUser!.id,
          'rating': rating,
          'comment': comment,
        })
        .select('id,order_id,user_id,rating,comment,created_at')
        .single();

    return ReviewModel.fromJson(data);
  }

  Future<void> createReviewItems({
    required String reviewId,
    required List<Map<String, dynamic>> items,
  }) async {
    if (items.isEmpty) return;
    await _client.from('review_items').insert([
      for (final it in items) {'review_id': reviewId, ...it},
    ]);
  }
}

