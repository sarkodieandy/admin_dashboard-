import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/cart_snapshot.dart';
import '../../domain/repositories/cart_repository.dart';

class CartRepositoryImpl implements CartRepository {
  static const _storageKey = 'cart_snapshot_v1';

  @override
  Future<CartSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) return CartSnapshot.empty();

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return CartSnapshot.empty();
      return CartSnapshot.fromJson(decoded);
    } catch (_) {
      return CartSnapshot.empty();
    }
  }

  @override
  Future<void> save(CartSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(snapshot.toJson()));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}

