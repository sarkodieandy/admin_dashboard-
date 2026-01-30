import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_notification_model.dart';

class NotificationSupabaseDatasource {
  NotificationSupabaseDatasource(this._client);

  final SupabaseClient _client;

  Future<List<AppNotificationModel>> fetchMyNotifications({
    required String userId,
    required int limit,
    required int offset,
  }) async {
    final data = await _client
        .from('notifications')
        .select('id,user_id,title,body,is_read,created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map(AppNotificationModel.fromJson)
        .toList();
  }

  Stream<List<AppNotificationModel>> watchMyNotifications({required String userId}) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map(
          (rows) => rows.whereType<Map<String, dynamic>>().map(AppNotificationModel.fromJson).toList(),
        );
  }

  Future<void> markAsRead({required String id, required String userId}) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id)
        .eq('user_id', userId);
  }

  Future<void> markAllAsRead({required String userId}) async {
    await _client.from('notifications').update({'is_read': true}).eq('user_id', userId);
  }
}

