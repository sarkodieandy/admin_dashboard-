import '../../domain/entities/menu_item.dart';
import '../../domain/entities/menu_item_image.dart';
import 'item_addon_model.dart';
import 'item_variant_model.dart';
import 'menu_item_image_model.dart';

class MenuItemModel {
  const MenuItemModel({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.spiceLevel,
    required this.isSoldOut,
    required this.isActive,
    this.categoryId,
    this.description,
    this.imagePath,
    this.images = const [],
    this.variants = const [],
    this.addons = const [],
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    final imagesJson = json['menu_item_images'];
    final variantsJson = json['item_variants'];
    final addonsJson = json['item_addons'];

    return MenuItemModel(
      id: json['id'] as String,
      categoryId: json['category_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      basePrice: _toDouble(json['base_price']),
      imagePath: json['image_url'] as String?,
      spiceLevel: (json['spice_level'] as num?)?.toInt() ?? 0,
      isSoldOut: (json['is_sold_out'] as bool?) ?? false,
      isActive: (json['is_active'] as bool?) ?? true,
      images: imagesJson is List
          ? imagesJson
              .whereType<Map<String, dynamic>>()
              .map(MenuItemImageModel.fromJson)
              .toList()
          : const [],
      variants: variantsJson is List
          ? variantsJson
              .whereType<Map<String, dynamic>>()
              .map(ItemVariantModel.fromJson)
              .toList()
          : const [],
      addons: addonsJson is List
          ? addonsJson
              .whereType<Map<String, dynamic>>()
              .map(ItemAddonModel.fromJson)
              .toList()
          : const [],
    );
  }

  final String id;
  final String? categoryId;
  final String name;
  final String? description;
  final double basePrice;
  final String? imagePath;
  final int spiceLevel;
  final bool isSoldOut;
  final bool isActive;
  final List<MenuItemImageModel> images;
  final List<ItemVariantModel> variants;
  final List<ItemAddonModel> addons;

  MenuItem toEntity({
    required String? imageUrl,
    required List<MenuItemImage> images,
  }) {
    return MenuItem(
      id: id,
      categoryId: categoryId,
      name: name,
      description: description,
      basePrice: basePrice,
      imageUrl: imageUrl,
      spiceLevel: spiceLevel,
      isSoldOut: isSoldOut,
      isActive: isActive,
      images: images,
      variants: variants.map((v) => v.toEntity()).toList(),
      addons: addons.map((a) => a.toEntity()).toList(),
    );
  }

  static double _toDouble(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;
}
