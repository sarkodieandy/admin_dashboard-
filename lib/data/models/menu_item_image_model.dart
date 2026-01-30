import '../../domain/entities/menu_item_image.dart';

class MenuItemImageModel {
  const MenuItemImageModel({
    required this.id,
    required this.itemId,
    required this.imagePath,
    required this.sortOrder,
  });

  factory MenuItemImageModel.fromJson(Map<String, dynamic> json) {
    return MenuItemImageModel(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      imagePath: json['image_url'] as String,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String itemId;
  final String imagePath;
  final int sortOrder;

  MenuItemImage toEntity({required String imageUrl}) => MenuItemImage(
        id: id,
        itemId: itemId,
        imageUrl: imageUrl,
        sortOrder: sortOrder,
      );
}

