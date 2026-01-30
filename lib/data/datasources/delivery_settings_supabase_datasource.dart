import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/delivery_settings.dart';

class DeliverySettingsSupabaseDatasource {
  DeliverySettingsSupabaseDatasource(this._client);

  final SupabaseClient _client;

  bool _isUndefinedTable(Object error, String tableName) {
    if (error is PostgrestException) {
      final msg = ('${error.message} ${error.details ?? ''}').toLowerCase();
      return error.code == '42P01' && msg.contains(tableName.toLowerCase());
    }
    final msg = error.toString().toLowerCase();
    final t = tableName.toLowerCase();
    return (msg.contains('42p01') && msg.contains(t)) ||
        (msg.contains('relation') && msg.contains(t) && msg.contains('does not exist'));
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  Future<DeliverySettings?> fetchSingleton() async {
    try {
      final data = await _client
          .from('delivery_settings')
          .select(
            'base_fee,free_radius_km,per_km_fee_after_free_radius,minimum_order_amount,max_delivery_distance_km,updated_at',
          )
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data == null) return null;

      return DeliverySettings(
        baseFee: _toDouble(data['base_fee']),
        freeRadiusKm: _toDouble(data['free_radius_km']),
        perKmFeeAfterFreeRadius: _toDouble(data['per_km_fee_after_free_radius']),
        minimumOrderAmount: _toDouble(data['minimum_order_amount']),
        maxDeliveryDistanceKm: _toDouble(data['max_delivery_distance_km']),
        updatedAt: data['updated_at'] == null ? null : DateTime.tryParse(data['updated_at'].toString()),
      );
    } catch (e) {
      if (_isUndefinedTable(e, 'delivery_settings')) return null;
      rethrow;
    }
  }
}

