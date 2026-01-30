import '../../domain/entities/order.dart';
import '../../domain/entities/order_status_event.dart';

class OrderStatusEventModel {
  const OrderStatusEventModel({
    required this.id,
    required this.orderId,
    required this.status,
    required this.createdAt,
  });

  factory OrderStatusEventModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusEventModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      status: orderStatusFromDb((json['status'] as String?) ?? 'placed'),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String orderId;
  final OrderStatus status;
  final DateTime createdAt;

  OrderStatusEvent toEntity() => OrderStatusEvent(
        id: id,
        orderId: orderId,
        status: status,
        createdAt: createdAt,
      );
}

