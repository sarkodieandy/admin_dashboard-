import 'order.dart';

class OrderStatusEvent {
  const OrderStatusEvent({
    required this.id,
    required this.orderId,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String orderId;
  final OrderStatus status;
  final DateTime createdAt;
}

