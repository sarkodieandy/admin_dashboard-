import '../../domain/entities/order.dart';

class OrderModel {
  const OrderModel({
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

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final address = json['address_snapshot'];
    return OrderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: orderStatusFromDb((json['status'] as String?) ?? 'placed'),
      subtotal: _toDouble(json['subtotal']),
      deliveryFee: _toDouble(json['delivery_fee']),
      discount: _toDouble(json['discount']),
      tip: _toDouble(json['tip']),
      total: _toDouble(json['total']),
      paymentMethod: paymentMethodFromDb((json['payment_method'] as String?) ?? 'cash'),
      paymentStatus: paymentStatusFromDb((json['payment_status'] as String?) ?? 'unpaid'),
      addressSnapshot: address is Map<String, dynamic> ? address : const {},
      scheduledFor:
          json['scheduled_for'] == null ? null : DateTime.parse(json['scheduled_for'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

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

  Order toEntity() => Order(
        id: id,
        userId: userId,
        status: status,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        discount: discount,
        tip: tip,
        total: total,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        addressSnapshot: addressSnapshot,
        scheduledFor: scheduledFor,
        createdAt: createdAt,
      );

  static double _toDouble(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;
}

