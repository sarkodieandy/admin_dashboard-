import '../entities/category.dart';
import '../entities/menu_item.dart';
import '../entities/promo.dart';

abstract class MenuRepository {
  Future<List<Category>> fetchCategories();

  Future<List<Promo>> fetchActivePromos({int limit = 10});
  Future<Promo?> fetchPromoByCode({required String code});

  Future<List<MenuItem>> fetchPopularItems({int limit = 10});

  Future<List<MenuItem>> fetchMenuItemsByCategory({
    required String categoryId,
    required int limit,
    required int offset,
  });

  Future<List<MenuItem>> searchMenuItems({
    required String query,
    int limit = 8,
  });

  Future<MenuItem> fetchMenuItemDetail({required String itemId});

  Future<List<MenuItem>> fetchFrequentlyBoughtTogether({
    required String itemId,
    required String? categoryId,
    int limit = 4,
  });
}
