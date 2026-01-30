enum OrderStatus {
  placed,
  confirmed,
  preparing,
  ready,
  enRoute,
  delivered,
  cancelled,
}

enum PaymentMethod { cash, momo, paystack }

enum PaymentStatus { unpaid, pending, paid, failed, refunded }

class Order {
  const Order({
    required this.id,
    required this.userId,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.tip,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.addressSnapshot,
    required this.createdAt,
    this.scheduledFor,
  });

  final String id;
  final String userId;
  final OrderStatus status;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double tip;
  final double total;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final Map<String, dynamic> addressSnapshot;
  final DateTime? scheduledFor;
  final DateTime createdAt;

  bool get isActive => status != OrderStatus.delivered && status != OrderStatus.cancelled;
}

OrderStatus orderStatusFromDb(String raw) {
  switch (raw.toLowerCase()) {
    case 'placed':
      return OrderStatus.placed;
    case 'confirmed':
      return OrderStatus.confirmed;
    case 'preparing':
      return OrderStatus.preparing;
    case 'ready':
      return OrderStatus.ready;
    case 'en_route':
      return OrderStatus.enRoute;
    case 'delivered':
      return OrderStatus.delivered;
    case 'cancelled':
      return OrderStatus.cancelled;
    default:
      return OrderStatus.placed;
  }
}

PaymentMethod paymentMethodFromDb(String raw) {
  switch (raw.toLowerCase()) {
    case 'momo':
      return PaymentMethod.momo;
    case 'paystack':
      return PaymentMethod.paystack;
    case 'cash':
    default:
      return PaymentMethod.cash;
  }
}

PaymentStatus paymentStatusFromDb(String raw) {
  switch (raw.toLowerCase()) {
    case 'pending':
      return PaymentStatus.pending;
    case 'paid':
      return PaymentStatus.paid;
    case 'failed':
      return PaymentStatus.failed;
    case 'refunded':
      return PaymentStatus.refunded;
    case 'unpaid':
    default:
      return PaymentStatus.unpaid;
  }
}

String orderStatusToDb(OrderStatus status) {
  switch (status) {
    case OrderStatus.enRoute:
      return 'en_route';
    default:
      return status.name;
  }
}
