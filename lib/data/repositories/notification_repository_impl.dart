import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_supabase_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._datasource);

  final NotificationSupabaseDatasource _datasource;

  @override
  Future<List<AppNotificationItem>> fetchMyNotifications({
    required String userId,
    required int limit,
    required int offset,
  }) async {
    final models = await _datasource.fetchMyNotifications(userId: userId, limit: limit, offset: offset);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Stream<List<AppNotificationItem>> watchMyNotifications({required String userId}) {
    return _datasource
        .watchMyNotifications(userId: userId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<void> markAsRead({required String id, required String userId}) {
    return _datasource.markAsRead(id: id, userId: userId);
  }

  @override
  Future<void> markAllAsRead({required String userId}) => _datasource.markAllAsRead(userId: userId);
}

