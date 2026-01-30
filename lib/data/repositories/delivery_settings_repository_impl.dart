import '../../domain/entities/delivery_settings.dart';
import '../../domain/repositories/delivery_settings_repository.dart';
import '../datasources/delivery_settings_supabase_datasource.dart';

class DeliverySettingsRepositoryImpl implements DeliverySettingsRepository {
  DeliverySettingsRepositoryImpl(this._datasource);

  final DeliverySettingsSupabaseDatasource _datasource;

  @override
  Future<DeliverySettings?> fetchDeliverySettings() => _datasource.fetchSingleton();
}

