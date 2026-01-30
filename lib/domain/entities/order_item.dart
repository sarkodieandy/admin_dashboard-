class OrderItem {
  const OrderItem({
    required this.id,
    required this.orderId,
    required this.nameSnapshot,
    required this.qty,
    required this.price,
    this.itemId,
    this.variantSnapshot,
    this.addonsSnapshot = const [],
  });

  final String id;
  final String orderId;
  final String? itemId;
  final String nameSnapshot;
  final String? variantSnapshot;
  final List<Map<String, dynamic>> addonsSnapshot;
  final int qty;
  final double price;

  double get total => price * qty;
}

class OrderItemDraft {
  const OrderItemDraft({
    required this.itemId,
    required this.nameSnapshot,
    required this.qty,
    required this.price,
    this.variantSnapshot,
    this.addonsSnapshot = const [],
  });

  final String itemId;
  final String nameSnapshot;
  final String? variantSnapshot;
  final List<Map<String, dynamic>> addonsSnapshot;
  final int qty;
  final double price;
}

