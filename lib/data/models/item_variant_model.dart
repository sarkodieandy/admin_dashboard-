import '../../domain/entities/item_variant.dart';

class ItemVariantModel {
  const ItemVariantModel({
    required this.id,
    required this.itemId,
    required this.name,
    required this.priceDelta,
  });

  factory ItemVariantModel.fromJson(Map<String, dynamic> json) {
    return ItemVariantModel(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      name: json['name'] as String,
      priceDelta: _toDouble(json['price_delta']),
    );
  }

  final String id;
  final String itemId;
  final String name;
  final double priceDelta;

  ItemVariant toEntity() => ItemVariant(id: id, itemId: itemId, name: name, priceDelta: priceDelta);

  static double _toDouble(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;
}

