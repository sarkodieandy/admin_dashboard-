import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../models/order_item_model.dart';
import '../models/order_model.dart';
import '../models/order_status_event_model.dart';

class OrderSupabaseDatasource {
  OrderSupabaseDatasource(this._client);

  final SupabaseClient _client;

  bool _isUndefinedColumn(Object error, String columnName) {
    if (error is PostgrestException) {
      final msg = ('${error.message} ${error.details ?? ''}').toLowerCase();
      return error.code == '42703' && msg.contains(columnName.toLowerCase());
    }
    final msg = error.toString().toLowerCase();
    final col = columnName.toLowerCase();
    return (msg.contains('42703') && msg.contains(col)) ||
        (msg.contains('column') &&
            msg.contains(col) &&
            msg.contains('does not exist'));
  }

  Future<OrderModel> createPaidOrderFromPaystack({
    required String reference,
    required String userId,
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

    // Prefer Edge Function (server-side payment verification + idempotency). Falls back to direct insert
    // when functions aren’t deployed yet.
    try {
      AppLogger.i(
        'paystack_create_order_fn_start reference=$reference',
        tag: 'orders',
      );
      final res = await _client.functions.invoke(
        'paystack-create-order',
        body: payload,
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final orderJson = data['order'];
        if (orderJson is Map<String, dynamic>) {
          AppLogger.i(
            'paystack_create_order_fn_ok reference=$reference',
            tag: 'orders',
          );
          return OrderModel.fromJson(orderJson);
        }
      }
      AppLogger.w(
        'paystack_create_order_fn_invalid_response reference=$reference',
        tag: 'orders',
      );
    } catch (error, stackTrace) {
      AppLogger.w(
        'paystack_create_order_fn_failed reference=$reference',
        tag: 'orders',
        error: error,
        stackTrace: stackTrace,
      );
      // Fall through to direct insert.
    }

    // Try idempotent fetch first (unique on payment_reference).
    try {
      final existing = await _client
          .from('orders')
          .select()
          .eq('payment_reference', reference)
          .maybeSingle();

      if (existing != null) {
        AppLogger.i(
          'paystack_create_order_existing reference=$reference',
          tag: 'orders',
        );
        return OrderModel.fromJson(existing);
      }
    } catch (error, stackTrace) {
      AppLogger.w(
        'paystack_create_order_existing_lookup_failed reference=$reference',
        tag: 'orders',
        error: error,
        stackTrace: stackTrace,
      );
      // Ignore and attempt insert below.
    }

    try {
      AppLogger.i(
        'paystack_create_order_fallback_insert_start reference=$reference',
        tag: 'orders',
      );
      final baseInsert = <String, dynamic>{
        'user_id': userId,
        'status': 'placed',
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'discount': discount,
        'tip': tip,
        'total': total,
        'payment_method': 'paystack',
        // When the Edge Function isn't available we can't verify the Paystack transaction server-side,
        // so keep this as pending.
        'payment_status': 'pending',
        'payment_reference': reference,
        'address_snapshot': addressSnapshot,
        'scheduled_for': scheduledFor?.toIso8601String(),
      };

      Map<String, dynamic> order;
      try {
        order = await _client
            .from('orders')
            .insert(baseInsert)
            .select()
            .single();
      } catch (error) {
        // Older deployments may not have `tip` yet.
        if (_isUndefinedColumn(error, 'tip') ||
            _isUndefinedColumn(error, 'tips')) {
          final fallbackInsert = Map<String, dynamic>.from(baseInsert)
            ..remove('tip');
          order = await _client
              .from('orders')
              .insert(fallbackInsert)
              .select()
              .single();
        } else {
          rethrow;
        }
      }

      final model = OrderModel.fromJson(order);

      if (items.isNotEmpty) {
        await _client.from('order_items').insert([
          for (final it in items) {'order_id': model.id, ...it},
        ]);
      }

      AppLogger.i(
        'paystack_create_order_fallback_insert_ok reference=$reference',
        tag: 'orders',
      );
      return model;
    } catch (error, stackTrace) {
      AppLogger.w(
        'paystack_create_order_fallback_insert_failed reference=$reference',
        tag: 'orders',
        error: error,
        stackTrace: stackTrace,
      );
      final existing = await _client
          .from('orders')
          .select()
          .eq('payment_reference', reference)
          .maybeSingle();

      if (existing != null) {
        AppLogger.i(
          'paystack_create_order_fallback_race_won reference=$reference',
          tag: 'orders',
        );
        return OrderModel.fromJson(existing);
      }
      rethrow;
    }
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
      AppLogger.i(
        'create_order_fn_start userId=$userId method=$paymentMethod status=$paymentStatus',
        tag: 'orders',
      );
      final res = await _client.functions.invoke('create-order', body: payload);
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final orderJson = data['order'];
        if (orderJson is Map<String, dynamic>) {
          AppLogger.i('create_order_fn_ok userId=$userId', tag: 'orders');
          return OrderModel.fromJson(orderJson);
        }
      }
      AppLogger.w(
        'create_order_fn_invalid_response userId=$userId',
        tag: 'orders',
      );
    } catch (error, stackTrace) {
      AppLogger.w(
        'create_order_fn_failed userId=$userId',
        tag: 'orders',
        error: error,
        stackTrace: stackTrace,
      );
      // Fall through to direct insert.
    }

    AppLogger.i(
      'create_order_fallback_insert_start userId=$userId',
      tag: 'orders',
    );
    final baseInsert = <String, dynamic>{
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
    };

    Map<String, dynamic> order;
    try {
      order = await _client.from('orders').insert(baseInsert).select().single();
    } catch (error) {
      // Older deployments may not have `tip` yet.
      if (_isUndefinedColumn(error, 'tip') ||
          _isUndefinedColumn(error, 'tips')) {
        final fallbackInsert = Map<String, dynamic>.from(baseInsert)
          ..remove('tip');
        order = await _client
            .from('orders')
            .insert(fallbackInsert)
            .select()
            .single();
      } else {
        rethrow;
      }
    }

    AppLogger.i(
      'create_order_fallback_insert_ok userId=$userId',
      tag: 'orders',
    );
    final model = OrderModel.fromJson(order);

    if (items.isNotEmpty) {
      await _client.from('order_items').insert([
        for (final it in items) {'order_id': model.id, ...it},
      ]);
    }

    return model;
  }

  Future<List<OrderModel>> fetchMyOrders({
    required int limit,
    required int offset,
  }) async {
    final data = await _client
        .from('orders')
        .select()
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map(OrderModel.fromJson)
        .toList();
  }

  Future<OrderModel> fetchOrder({required String orderId}) async {
    final data = await _client
        .from('orders')
        .select()
        .eq('id', orderId)
        .single();

    return OrderModel.fromJson(data);
  }

  Future<List<OrderItemModel>> fetchOrderItems({
    required String orderId,
  }) async {
    final data = await _client
        .from('order_items')
        .select(
          'id,order_id,item_id,name_snapshot,variant_snapshot,addons_snapshot,qty,price,created_at',
        )
        .eq('order_id', orderId)
        .order('created_at', ascending: true);

    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map(OrderItemModel.fromJson)
        .toList();
  }

  Future<List<OrderStatusEventModel>> fetchOrderStatusEvents({
    required String orderId,
  }) async {
    final data = await _client
        .from('order_status_events')
        .select('id,order_id,status,created_at')
        .eq('order_id', orderId)
        .order('created_at', ascending: true);

    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map(OrderStatusEventModel.fromJson)
        .toList();
  }

  Stream<List<OrderModel>> watchOrder({required String orderId}) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map(
          (rows) => rows
              .whereType<Map<String, dynamic>>()
              .map(OrderModel.fromJson)
              .toList(),
        );
  }

  Stream<List<OrderStatusEventModel>> watchOrderStatusEvents({
    required String orderId,
  }) {
    return _client
        .from('order_status_events')
        .stream(primaryKey: ['id'])
        .eq('order_id', orderId)
        .order('created_at', ascending: true)
        .map(
          (rows) => rows
              .whereType<Map<String, dynamic>>()
              .map(OrderStatusEventModel.fromJson)
              .toList(),
        );
  }
}
