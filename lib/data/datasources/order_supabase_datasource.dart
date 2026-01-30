import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/order_item_model.dart';
import '../models/order_model.dart';
import '../models/order_status_event_model.dart';

class OrderSupabaseDatasource {
  OrderSupabaseDatasource(this._client);

  final SupabaseClient _client;

  Future<OrderModel> createPaidOrderFromPaystack({
    required String reference,
    required double subtotal,
    required double deliveryFee,
    required double discount,
    required double tip,
    required double total,
    required Map<String, dynamic> addressSnapshot,
    DateTime? scheduledFor,
    required List<Map<String, dynamic>> items,
  }) async {
    final payload = <String, dynamic>{
      'reference': reference,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'discount': discount,
      'tip': tip,
      'total': total,
      'address_snapshot': addressSnapshot,
      'scheduled_for': scheduledFor?.toIso8601String(),
      'items': items,
    };

    final res = await _client.functions.invoke('paystack-create-order', body: payload);
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final orderJson = data['order'];
      if (orderJson is Map<String, dynamic>) {
        return OrderModel.fromJson(orderJson);
      }
    }

    throw Exception('Invalid Paystack create order response');
  }

  Future<OrderModel> createOrder({
    required String userId,
    required String paymentMethod,
    required String paymentStatus,
    required double subtotal,
    required double deliveryFee,
    required double discount,
    required double tip,
    required double total,
    required Map<String, dynamic> addressSnapshot,
    DateTime? scheduledFor,
    required List<Map<String, dynamic>> items,
  }) async {
    final payload = <String, dynamic>{
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'discount': discount,
      'tip': tip,
      'total': total,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'address_snapshot': addressSnapshot,
      'scheduled_for': scheduledFor?.toIso8601String(),
      'items': items,
    };

    // Prefer Edge Function (server-side validation + notifications). Falls back to direct insert
    // when functions aren’t deployed yet.
    try {
      final res = await _client.functions.invoke('create-order', body: payload);
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final orderJson = data['order'];
        if (orderJson is Map<String, dynamic>) {
          return OrderModel.fromJson(orderJson);
        }
      }
    } catch (_) {
      // Fall through to direct insert.
    }

    final order = await _client
        .from('orders')
        .insert({
          'user_id': userId,
          'status': 'placed',
          'subtotal': subtotal,
          'delivery_fee': deliveryFee,
          'discount': discount,
          'tip': tip,
          'total': total,
          'payment_method': paymentMethod,
          'payment_status': paymentStatus,
          'address_snapshot': addressSnapshot,
          'scheduled_for': scheduledFor?.toIso8601String(),
        })
        .select(
          'id,user_id,status,subtotal,delivery_fee,discount,tip,total,payment_method,payment_status,address_snapshot,scheduled_for,created_at',
        )
        .single();

    final model = OrderModel.fromJson(order);

    if (items.isNotEmpty) {
      await _client.from('order_items').insert([
        for (final it in items) {'order_id': model.id, ...it},
      ]);
    }

    return model;
  }

  Future<List<OrderModel>> fetchMyOrders({required int limit, required int offset}) async {
    final data = await _client
        .from('orders')
        .select(
          'id,user_id,status,subtotal,delivery_fee,discount,tip,total,payment_method,payment_status,address_snapshot,scheduled_for,created_at',
        )
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List).whereType<Map<String, dynamic>>().map(OrderModel.fromJson).toList();
  }

  Future<OrderModel> fetchOrder({required String orderId}) async {
    final data = await _client
        .from('orders')
        .select(
          'id,user_id,status,subtotal,delivery_fee,discount,tip,total,payment_method,payment_status,address_snapshot,scheduled_for,created_at',
        )
        .eq('id', orderId)
        .single();

    return OrderModel.fromJson(data);
  }

  Future<List<OrderItemModel>> fetchOrderItems({required String orderId}) async {
    final data = await _client
        .from('order_items')
        .select('id,order_id,item_id,name_snapshot,variant_snapshot,addons_snapshot,qty,price,created_at')
        .eq('order_id', orderId)
        .order('created_at', ascending: true);

    return (data as List).whereType<Map<String, dynamic>>().map(OrderItemModel.fromJson).toList();
  }

  Future<List<OrderStatusEventModel>> fetchOrderStatusEvents({required String orderId}) async {
    final data = await _client
        .from('order_status_events')
        .select('id,order_id,status,created_at')
        .eq('order_id', orderId)
        .order('created_at', ascending: true);

    return (data as List).whereType<Map<String, dynamic>>().map(OrderStatusEventModel.fromJson).toList();
  }

  Stream<List<OrderModel>> watchOrder({required String orderId}) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map((rows) => rows.whereType<Map<String, dynamic>>().map(OrderModel.fromJson).toList());
  }

  Stream<List<OrderStatusEventModel>> watchOrderStatusEvents({required String orderId}) {
    return _client
        .from('order_status_events')
        .stream(primaryKey: ['id'])
        .eq('order_id', orderId)
        .order('created_at', ascending: true)
        .map(
          (rows) => rows.whereType<Map<String, dynamic>>().map(OrderStatusEventModel.fromJson).toList(),
        );
  }
}
