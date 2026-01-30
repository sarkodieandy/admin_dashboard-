import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../domain/entities/address.dart';
import '../../domain/repositories/address_repository.dart';

class AddressProvider extends ChangeNotifier {
  AddressProvider({required AddressRepository repository})
    : _repository = repository;

  final AddressRepository _repository;

  String? _userId;
  bool _isLoading = false;
  String? _error;
  List<Address> _addresses = const [];

  bool get isReady => _userId != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Address> get addresses => _addresses;

  Address? get defaultAddress =>
      _addresses.where((a) => a.isDefault).cast<Address?>().firstOrNull;

  void setUserId(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _addresses = const [];
    _error = null;
    AppLogger.d(
      'set_user_id(${userId == null ? 'null' : 'set'})',
      tag: 'address',
    );
    notifyListeners();

    if (userId != null) {
      refresh();
    }
  }

  Future<void> refresh() async {
    final userId = _userId;
    if (userId == null) {
      AppLogger.w('refresh_skipped_no_user', tag: 'address');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _addresses = await _repository.fetchMyAddresses(userId: userId);
      AppLogger.i('refresh_ok(count=${_addresses.length})', tag: 'address');
    } catch (error, stackTrace) {
      AppLogger.e(
        'refresh_failed',
        tag: 'address',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveAddress({
    String? id,
    required String label,
    required String address,
    required String landmark,
    double? lat,
    double? lng,
    required bool isDefault,
  }) async {
    final userId = _userId;
    if (userId == null) {
      _error = 'Please sign in to save an address.';
      AppLogger.w('save_address_no_user', tag: 'address');
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.i('save_address_start', tag: 'address');
      if (id == null) {
        await _repository.createAddress(
          userId: userId,
          label: label,
          address: address,
          landmark: landmark,
          lat: lat,
          lng: lng,
          isDefault: isDefault,
        );
      } else {
        await _repository.updateAddress(
          id: id,
          userId: userId,
          label: label,
          address: address,
          landmark: landmark,
          lat: lat,
          lng: lng,
          isDefault: isDefault,
        );
      }

      _addresses = await _repository.fetchMyAddresses(userId: userId);
      AppLogger.i(
        'save_address_ok(count=${_addresses.length})',
        tag: 'address',
      );
      return true;
    } catch (error, stackTrace) {
      AppLogger.e(
        'save_address_failed',
        tag: 'address',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAddress(String id) async {
    final userId = _userId;
    if (userId == null) {
      AppLogger.w('delete_address_skipped_no_user', tag: 'address');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.deleteAddress(id: id, userId: userId);
      _addresses = await _repository.fetchMyAddresses(userId: userId);
      AppLogger.i(
        'delete_address_ok(count=${_addresses.length})',
        tag: 'address',
      );
    } catch (error, stackTrace) {
      AppLogger.e(
        'delete_address_failed',
        tag: 'address',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setDefault(String addressId) async {
    final userId = _userId;
    if (userId == null) {
      AppLogger.w('set_default_skipped_no_user', tag: 'address');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.setDefault(userId: userId, addressId: addressId);
      _addresses = await _repository.fetchMyAddresses(userId: userId);
      AppLogger.i('set_default_ok(count=${_addresses.length})', tag: 'address');
    } catch (error, stackTrace) {
      AppLogger.e(
        'set_default_failed',
        tag: 'address',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
