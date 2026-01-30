import 'package:flutter/foundation.dart';

import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({required ProfileRepository repository})
      : _repository = repository;

  final ProfileRepository _repository;

  String? _userId;
  Profile? _profile;
  bool _isLoading = false;
  String? _error;

  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isReady => _userId != null;
  bool get isComplete => _profile?.isComplete ?? false;

  void setUserId(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _profile = null;
    _error = null;
    notifyListeners();

    if (userId != null) {
      refresh();
    }
  }

  Future<void> refresh() async {
    final userId = _userId;
    if (userId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _repository.fetchMyProfile(userId: userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateMyProfile({
    required String name,
    required String phone,
    required String defaultDeliveryNote,
  }) async {
    final userId = _userId;
    if (userId == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _repository.updateMyProfile(
        userId: userId,
        name: name,
        phone: phone,
        defaultDeliveryNote: defaultDeliveryNote,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

