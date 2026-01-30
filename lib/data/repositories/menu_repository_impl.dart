import '../../core/constants/app_constants.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/menu_item_image.dart';
import '../../domain/entities/promo.dart';
import '../../domain/repositories/menu_repository.dart';
import '../datasources/menu_supabase_datasource.dart';
import '../models/menu_item_model.dart';
import '../services/supabase_storage_service.dart';

class MenuRepositoryImpl implements MenuRepository {
  MenuRepositoryImpl(this._datasource, this._storage);

  final MenuSupabaseDatasource _datasource;
  final SupabaseStorageService _storage;

  @override
  Future<List<Category>> fetchCategories() async {
    final models = await _datasource.fetchCategories();
    final categories = models.map((m) => m.toEntity()).toList();
    categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return categories;
  }

  @override
  Future<List<Promo>> fetchActivePromos({int limit = 10}) async {
    final models = await _datasource.fetchActivePromos(limit: limit);
    return models.map((m) => m.toEntity()).where((p) => p.isActive).toList();
  }

  @override
  Future<Promo?> fetchPromoByCode({required String code}) async {
    final model = await _datasource.fetchPromoByCode(code: code);
    return model?.toEntity();
  }

  @override
  Future<List<MenuItem>> fetchPopularItems({int limit = 10}) async {
    final models = await _datasource.fetchPopularItems(limit: limit);
    return models.map(_mapItem).toList();
  }

  @override
  Future<List<MenuItem>> fetchMenuItemsByCategory({
    required String categoryId,
    required int limit,
    required int offset,
  }) async {
    final models = await _datasource.fetchMenuItemsByCategory(
      categoryId: categoryId,
      limit: limit,
      offset: offset,
    );
    return models.map(_mapItem).toList();
  }

  @override
  Future<List<MenuItem>> searchMenuItems({required String query, int limit = 8}) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final models = await _datasource.searchMenuItems(query: q, limit: limit);
    return models.map(_mapItem).toList();
  }

  @override
  Future<MenuItem> fetchMenuItemDetail({required String itemId}) async {
    final model = await _datasource.fetchMenuItemDetail(itemId: itemId);
    return _mapItem(model, includeImages: true);
  }

  @override
  Future<List<MenuItem>> fetchFrequentlyBoughtTogether({
    required String itemId,
    required String? categoryId,
    int limit = 4,
  }) async {
    final models = await _datasource.fetchFrequentlyBoughtTogether(
      itemId: itemId,
      categoryId: categoryId,
      limit: limit,
    );
    return models.map(_mapItem).toList();
  }

  MenuItem _mapItem(MenuItemModel model, {bool includeImages = false}) {
    final primaryUrl = _storage.publicUrl(bucket: AppConstants.menuImagesBucket, path: model.imagePath);

    final images = <MenuItemImage>[];
    if (includeImages) {
      final sorted = [...model.images]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      for (final img in sorted) {
        final url = _storage.publicUrl(bucket: AppConstants.menuImagesBucket, path: img.imagePath);
        if (url == null) continue;
        images.add(img.toEntity(imageUrl: url));
      }
    }

    if (primaryUrl != null) {
      images.insert(
        0,
        MenuItemImage(
          id: '${model.id}-primary',
          itemId: model.id,
          imageUrl: primaryUrl,
          sortOrder: -1,
        ),
      );
    }

    return model.toEntity(imageUrl: primaryUrl, images: images);
  }
}
