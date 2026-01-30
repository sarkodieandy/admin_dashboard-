import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/delivery_settings.dart';
import '../../domain/repositories/delivery_settings_repository.dart';

class DeliverySettingsProvider extends ChangeNotifier {
  DeliverySettingsProvider({required DeliverySettingsRepository repository})
      : _repository = repository {
    unawaited(load());
  }

  final DeliverySettingsRepository _repository;

  bool _isLoading = false;
  String? _error;
  DeliverySettings? _settings;

  bool get isLoading => _isLoading;
  String? get error => _error;
  DeliverySettings? get settings => _settings;

  double get baseFee => _settings?.baseFee ?? AppConstants.baseDeliveryFee;
  double get minimumOrderAmount => _settings?.minimumOrderAmount ?? AppConstants.minOrderSubtotal;

  Future<void> load({bool force = false}) async {
    if (_isLoading) return;
    if (!force && _settings != null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _settings = await _repository.fetchDeliverySettings();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load(force: true);
}

