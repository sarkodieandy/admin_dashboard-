import '../../domain/entities/order_item.dart';

class OrderItemModel {
  const OrderItemModel({
    required this.id,
    required this.orderId,
    required this.nameSnapshot,
    required this.qty,
    required this.price,
    this.itemId,
    this.variantSnapshot,
    this.addonsSnapshot = const [],
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final addonsRaw = json['addons_snapshot'];
    final addons = addonsRaw is List
        ? addonsRaw
            .whereType<Map<String, dynamic>>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList()
        : const <Map<String, dynamic>>[];

    return OrderItemModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      itemId: json['item_id'] as String?,
      nameSnapshot: json['name_snapshot'] as String,
      variantSnapshot: json['variant_snapshot'] as String?,
      addonsSnapshot: addons,
      qty: (json['qty'] as num).toInt(),
      price: _toDouble(json['price']),
    );
  }

  final String id;
  final String orderId;
  final String? itemId;
  final String nameSnapshot;
  final String? variantSnapshot;
  final List<Map<String, dynamic>> addonsSnapshot;
  final int qty;
  final double price;

  OrderItem toEntity() => OrderItem(
        id: id,
        orderId: orderId,
        itemId: itemId,
        nameSnapshot: nameSnapshot,
        variantSnapshot: variantSnapshot,
        addonsSnapshot: addonsSnapshot,
        qty: qty,
        price: price,
      );

  static double _toDouble(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;
}

