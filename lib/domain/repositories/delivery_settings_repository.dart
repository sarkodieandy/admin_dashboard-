import '../entities/delivery_settings.dart';

abstract class DeliverySettingsRepository {
  Future<DeliverySettings?> fetchDeliverySettings();
}

