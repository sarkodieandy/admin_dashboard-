import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({required NotificationRepository repository}) : _repository = repository;

  final NotificationRepository _repository;

  String? _userId;
  bool _isLoading = false;
  String? _error;
  List<AppNotificationItem> _items = const [];

  StreamSubscription<List<AppNotificationItem>>? _sub;

  bool get isReady => _userId != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<AppNotificationItem> get notifications => _items;

  int get unreadCount => _items.where((n) => !n.isRead).length;

  void setUserId(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _items = const [];
    _error = null;
    notifyListeners();

    _sub?.cancel();
    _sub = null;

    if (userId != null) {
      _isLoading = true;
      notifyListeners();
      _sub = _repository.watchMyNotifications(userId: userId).listen(
        (items) {
          _items = items.take(50).toList();
          _isLoading = false;
          _error = null;
          notifyListeners();
        },
        onError: (e) {
          _error = e.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    }
  }

  Future<void> markAsRead(String id) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _repository.markAsRead(id: id, userId: userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _repository.markAllAsRead(userId: userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

