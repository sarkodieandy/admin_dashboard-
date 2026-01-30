import 'cart_addon.dart';

class CartLine {
  const CartLine({
    required this.id,
    required this.itemId,
    required this.name,
    required this.basePrice,
    required this.qty,
    this.imageUrl,
    this.note = '',
    this.variantId,
    this.variantName,
    this.variantDelta = 0,
    this.addons = const [],
  });

  factory CartLine.fromJson(Map<String, dynamic> json) {
    final addonsJson = json['addons'];
    return CartLine(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String?,
      basePrice: double.tryParse(json['basePrice']?.toString() ?? '') ?? 0,
      qty: (json['qty'] as num?)?.toInt() ?? 1,
      note: (json['note'] as String?) ?? '',
      variantId: json['variantId'] as String?,
      variantName: json['variantName'] as String?,
      variantDelta: double.tryParse(json['variantDelta']?.toString() ?? '') ?? 0,
      addons: addonsJson is List
          ? addonsJson
              .whereType<Map<String, dynamic>>()
              .map(CartAddon.fromJson)
              .toList()
          : const [],
    );
  }

  final String id;
  final String itemId;
  final String name;
  final String? imageUrl;
  final double basePrice;
  final int qty;
  final String note;

  final String? variantId;
  final String? variantName;
  final double variantDelta;

  final List<CartAddon> addons;

  double get addonsTotal => addons.fold<double>(0, (sum, a) => sum + a.price);
  double get unitPrice => basePrice + variantDelta + addonsTotal;
  double get total => unitPrice * qty;

  CartLine copyWith({
    int? qty,
    String? note,
  }) {
    return CartLine(
      id: id,
      itemId: itemId,
      name: name,
      imageUrl: imageUrl,
      basePrice: basePrice,
      qty: qty ?? this.qty,
      note: note ?? this.note,
      variantId: variantId,
      variantName: variantName,
      variantDelta: variantDelta,
      addons: addons,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemId': itemId,
        'name': name,
        'imageUrl': imageUrl,
        'basePrice': basePrice,
        'qty': qty,
        'note': note,
        'variantId': variantId,
        'variantName': variantName,
        'variantDelta': variantDelta,
        'addons': addons.map((a) => a.toJson()).toList(),
      };
}

