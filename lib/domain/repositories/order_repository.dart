import '../entities/order.dart';
import '../entities/order_item.dart';
import '../entities/order_status_event.dart';

abstract class OrderRepository {
  Future<Order> createOrder({
    required String userId,
    required PaymentMethod paymentMethod,
    required PaymentStatus paymentStatus,
    required double subtotal,
    required double deliveryFee,
    required double discount,
    required double tip,
    required double total,
    required Map<String, dynamic> addressSnapshot,
    DateTime? scheduledFor,
    required List<OrderItemDraft> items,
  });

  Future<Order> createPaidOrderFromPaystack({
    required String reference,
    required String userId,
    required double subtotal,
    required double deliveryFee,
    required double discount,
    required double tip,
    required double total,
    required Map<String, dynamic> addressSnapshot,
    DateTime? scheduledFor,
    required List<OrderItemDraft> items,
  });

  Future<List<Order>> fetchMyOrders({required int limit, required int offset});

  Future<Order> fetchOrder({required String orderId});

  Future<List<OrderItem>> fetchOrderItems({required String orderId});

  Future<List<OrderStatusEvent>> fetchOrderStatusEvents({required String orderId});

  Stream<Order?> watchOrder({required String orderId});

  Stream<List<OrderStatusEvent>> watchOrderStatusEvents({required String orderId});
}
