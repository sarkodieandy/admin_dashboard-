import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category_model.dart';
import '../models/menu_item_model.dart';
import '../models/promo_model.dart';

class MenuSupabaseDatasource {
  MenuSupabaseDatasource(this._client);

  final SupabaseClient _client;

  Future<List<CategoryModel>> fetchCategories() async {
    final data = await _client
        .from('categories')
        .select('id,name,sort_order')
        .order('sort_order', ascending: true);

    return (data as List).whereType<Map<String, dynamic>>().map(CategoryModel.fromJson).toList();
  }

  Future<List<PromoModel>> fetchActivePromos({required int limit}) async {
    final data = await _client
        .from('promos')
        .select('id,code,type,value,min_subtotal,expires_at,is_active,created_at')
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List).whereType<Map<String, dynamic>>().map(PromoModel.fromJson).toList();
  }

  Future<PromoModel?> fetchPromoByCode({required String code}) async {
    final data = await _client
        .from('promos')
        .select('id,code,type,value,min_subtotal,expires_at,is_active,created_at')
        .eq('code', code.trim())
        .limit(1);

    final list = (data as List).whereType<Map<String, dynamic>>().toList();
    if (list.isEmpty) return null;
    return PromoModel.fromJson(list.first);
  }

  Future<List<MenuItemModel>> fetchPopularItems({required int limit}) async {
    final data = await _client
        .from('menu_items')
        .select('id,category_id,name,description,base_price,image_url,spice_level,is_active,is_sold_out,created_at')
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List).whereType<Map<String, dynamic>>().map(MenuItemModel.fromJson).toList();
  }

  Future<List<MenuItemModel>> fetchMenuItemsByCategory({
    required String categoryId,
    required int limit,
    required int offset,
  }) async {
    final data = await _client
        .from('menu_items')
        .select('id,category_id,name,description,base_price,image_url,spice_level,is_active,is_sold_out,created_at')
        .eq('category_id', categoryId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List).whereType<Map<String, dynamic>>().map(MenuItemModel.fromJson).toList();
  }

  Future<List<MenuItemModel>> searchMenuItems({
    required String query,
    required int limit,
  }) async {
    final pattern = '%${query.trim()}%';
    final data = await _client
        .from('menu_items')
        .select('id,category_id,name,description,base_price,image_url,spice_level,is_active,is_sold_out,created_at')
        .ilike('name', pattern)
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List).whereType<Map<String, dynamic>>().map(MenuItemModel.fromJson).toList();
  }

  Future<MenuItemModel> fetchMenuItemDetail({required String itemId}) async {
    final data = await _client
        .from('menu_items')
        .select(
          'id,category_id,name,description,base_price,image_url,spice_level,is_active,is_sold_out,created_at,'
          'menu_item_images(id,item_id,image_url,sort_order),'
          'item_variants(id,item_id,name,price_delta),'
          'item_addons(id,item_id,name,price)',
        )
        .eq('id', itemId)
        .single();

    return MenuItemModel.fromJson(data);
  }

  Future<List<MenuItemModel>> fetchFrequentlyBoughtTogether({
    required String itemId,
    required String? categoryId,
    required int limit,
  }) async {
    if (categoryId == null) return [];

    final data = await _client
        .from('menu_items')
        .select('id,category_id,name,description,base_price,image_url,spice_level,is_active,is_sold_out,created_at')
        .eq('category_id', categoryId)
        .neq('id', itemId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List).whereType<Map<String, dynamic>>().map(MenuItemModel.fromJson).toList();
  }
}
