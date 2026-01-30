import 'item_addon.dart';
import 'item_variant.dart';
import 'menu_item_image.dart';

class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.spiceLevel,
    required this.isSoldOut,
    required this.isActive,
    this.categoryId,
    this.description,
    this.imageUrl,
    this.images = const [],
    this.variants = const [],
    this.addons = const [],
  });

  final String id;
  final String? categoryId;
  final String name;
  final String? description;
  final double basePrice;
  final String? imageUrl;
  final int spiceLevel;
  final bool isSoldOut;
  final bool isActive;

  final List<MenuItemImage> images;
  final List<ItemVariant> variants;
  final List<ItemAddon> addons;
}

