import '../../domain/entities/item_addon.dart';

class ItemAddonModel {
  const ItemAddonModel({
    required this.id,
    required this.itemId,
    required this.name,
    required this.price,
  });

  factory ItemAddonModel.fromJson(Map<String, dynamic> json) {
    return ItemAddonModel(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      name: json['name'] as String,
      price: _toDouble(json['price']),
    );
  }

  final String id;
  final String itemId;
  final String name;
  final double price;

  ItemAddon toEntity() => ItemAddon(id: id, itemId: itemId, name: name, price: price);

  static double _toDouble(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;
}

