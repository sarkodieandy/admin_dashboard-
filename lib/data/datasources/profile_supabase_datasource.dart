import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';

class ProfileSupabaseDatasource {
  ProfileSupabaseDatasource(this._client);

  final SupabaseClient _client;

  Future<ProfileModel> fetchMyProfile({required String userId}) async {
    final data = await _client.from('profiles').select().eq('id', userId).maybeSingle();
    if (data != null) return ProfileModel.fromJson(data);

    // Self-heal: if the profile row is missing (e.g., trigger not installed),
    // create it so subsequent updates succeed.
    try {
      final created = await _client
          .from('profiles')
          .insert({'id': userId, 'role': 'customer'})
          .select()
          .single();
      return ProfileModel.fromJson(created);
    } catch (e) {
      final retry = await _client.from('profiles').select().eq('id', userId).maybeSingle();
      if (retry != null) return ProfileModel.fromJson(retry);
      rethrow;
    }
  }

  Future<ProfileModel> updateMyProfile({
    required String userId,
    required String name,
    required String phone,
    required String defaultDeliveryNote,
  }) async {
    final updated = await _client
        .from('profiles')
        .update(
          {
            'name': name,
            'phone': phone,
            'default_delivery_note': defaultDeliveryNote,
          },
        )
        .eq('id', userId)
        .select()
        .maybeSingle();

    if (updated != null) return ProfileModel.fromJson(updated);

    try {
      final created = await _client
          .from('profiles')
          .insert(
            {
              'id': userId,
              'role': 'customer',
              'name': name,
              'phone': phone,
              'default_delivery_note': defaultDeliveryNote,
            },
          )
          .select()
          .single();

      return ProfileModel.fromJson(created);
    } catch (e) {
      final retry = await _client.from('profiles').select().eq('id', userId).maybeSingle();
      if (retry != null) return ProfileModel.fromJson(retry);
      rethrow;
    }
  }
}
