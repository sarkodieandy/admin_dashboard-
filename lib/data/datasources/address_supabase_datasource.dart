import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../models/address_model.dart';

class AddressSupabaseDatasource {
  AddressSupabaseDatasource(this._client);

  final SupabaseClient _client;

  Future<List<AddressModel>> fetchMyAddresses({required String userId}) async {
    try {
      final data = await _client
          .from('addresses')
          .select('id,user_id,label,address,landmark,lat,lng,is_default,created_at')
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      return (data as List).whereType<Map<String, dynamic>>().map(AddressModel.fromJson).toList();
    } catch (error, stackTrace) {
      AppLogger.e(
        'addresses_fetch_failed',
        tag: 'address',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<AddressModel> createAddress({
    required String userId,
    required String label,
    required String address,
    required String landmark,
    double? lat,
    double? lng,
    required bool isDefault,
  }) async {
    try {
      final data = await _client
          .from('addresses')
          .insert({
            'user_id': userId,
            'label': label,
            'address': address,
            'landmark': landmark,
            'lat': lat,
            'lng': lng,
            'is_default': isDefault,
          })
          .select()
          .single();

      return AddressModel.fromJson(data);
    } catch (error, stackTrace) {
      AppLogger.e(
        'addresses_create_failed',
        tag: 'address',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<AddressModel> updateAddress({
    required String id,
    required String userId,
    required String label,
    required String address,
    required String landmark,
    double? lat,
    double? lng,
    required bool isDefault,
  }) async {
    try {
      final data = await _client
          .from('addresses')
          .update({
            'label': label,
            'address': address,
            'landmark': landmark,
            'lat': lat,
            'lng': lng,
            'is_default': isDefault,
          })
          .eq('id', id)
          .eq('user_id', userId)
          .select()
          .single();

      return AddressModel.fromJson(data);
    } catch (error, stackTrace) {
      AppLogger.e(
        'addresses_update_failed',
        tag: 'address',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> deleteAddress({required String id, required String userId}) async {
    try {
      await _client.from('addresses').delete().eq('id', id).eq('user_id', userId);
    } catch (error, stackTrace) {
      AppLogger.e(
        'addresses_delete_failed',
        tag: 'address',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> unsetDefaultForUser({required String userId}) async {
    try {
      await _client.from('addresses').update({'is_default': false}).eq('user_id', userId);
    } catch (error, stackTrace) {
      AppLogger.e(
        'addresses_unset_default_failed',
        tag: 'address',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> setDefault({required String userId, required String addressId}) async {
    try {
      await unsetDefaultForUser(userId: userId);
      await _client
          .from('addresses')
          .update({'is_default': true})
          .eq('id', addressId)
          .eq('user_id', userId);
    } catch (error, stackTrace) {
      AppLogger.e(
        'addresses_set_default_failed',
        tag: 'address',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
