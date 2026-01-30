import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/order_status_event.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_supabase_datasource.dart';

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._datasource);

  final OrderSupabaseDatasource _datasource;

  @override
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
  }) async {
    final method = paymentMethod.name;
    final payStatus = paymentStatus.name;

    final model = await _datasource.createOrder(
      userId: userId,
      paymentMethod: method,
      paymentStatus: payStatus,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discount: discount,
      tip: tip,
      total: total,
      addressSnapshot: addressSnapshot,
      scheduledFor: scheduledFor,
      items: items
          .map(
            (i) => {
              'item_id': i.itemId,
              'name_snapshot': i.nameSnapshot,
              'variant_snapshot': i.variantSnapshot,
              'addons_snapshot': i.addonsSnapshot,
              'qty': i.qty,
              'price': i.price,
            },
          )
          .toList(),
    );

    return model.toEntity();
  }

  @override
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
  }) async {
    final model = await _datasource.createPaidOrderFromPaystack(
      reference: reference,
      userId: userId,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discount: discount,
      tip: tip,
      total: total,
      addressSnapshot: addressSnapshot,
      scheduledFor: scheduledFor,
      items: items
          .map(
            (i) => {
              'item_id': i.itemId,
              'name_snapshot': i.nameSnapshot,
              'variant_snapshot': i.variantSnapshot,
              'addons_snapshot': i.addonsSnapshot,
              'qty': i.qty,
              'price': i.price,
            },
          )
          .toList(),
    );

    return model.toEntity();
  }

  @override
  Future<List<Order>> fetchMyOrders({required int limit, required int offset}) async {
    final models = await _datasource.fetchMyOrders(limit: limit, offset: offset);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Order> fetchOrder({required String orderId}) async {
    final model = await _datasource.fetchOrder(orderId: orderId);
    return model.toEntity();
  }

  @override
  Future<List<OrderItem>> fetchOrderItems({required String orderId}) async {
    final models = await _datasource.fetchOrderItems(orderId: orderId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<OrderStatusEvent>> fetchOrderStatusEvents({required String orderId}) async {
    final models = await _datasource.fetchOrderStatusEvents(orderId: orderId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Stream<Order?> watchOrder({required String orderId}) {
    return _datasource.watchOrder(orderId: orderId).map((list) => list.isEmpty ? null : list.first.toEntity());
  }

  @override
  Stream<List<OrderStatusEvent>> watchOrderStatusEvents({required String orderId}) {
    return _datasource
        .watchOrderStatusEvents(orderId: orderId)
        .map((list) => list.map((m) => m.toEntity()).toList());
  }
}
