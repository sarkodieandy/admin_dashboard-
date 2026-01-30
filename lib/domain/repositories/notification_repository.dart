import '../entities/app_notification.dart';

abstract class NotificationRepository {
  Future<List<AppNotificationItem>> fetchMyNotifications({
    required String userId,
    required int limit,
    required int offset,
  });

  Stream<List<AppNotificationItem>> watchMyNotifications({required String userId});

  Future<void> markAsRead({required String id, required String userId});

  Future<void> markAllAsRead({required String userId});
}

