import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:finger_licking_customer/data/datasources/order_supabase_datasource.dart';
import 'package:finger_licking_customer/data/models/order_model.dart';
import 'package:finger_licking_customer/data/repositories/order_repository_impl.dart';
import 'package:finger_licking_customer/domain/entities/order.dart';
import 'package:finger_licking_customer/domain/entities/order_item.dart';

class _CaptureOrderSupabaseDatasource extends OrderSupabaseDatasource {
  _CaptureOrderSupabaseDatasource() : super(SupabaseClient('http://localhost', 'anon'));

  String? lastUserId;
  String? lastReference;

  @override
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
    lastReference = reference;
    lastUserId = userId;

    return OrderModel(
      id: 'order_1',
      userId: userId,
      status: OrderStatus.placed,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discount: discount,
      tip: tip,
      total: total,
      paymentMethod: PaymentMethod.paystack,
      paymentStatus: PaymentStatus.paid,
      addressSnapshot: addressSnapshot,
      scheduledFor: scheduledFor,
      createdAt: DateTime.utc(2026, 1, 1),
    );
  }
}

void main() {
  test('OrderRepositoryImpl passes userId to paystack datasource', () async {
    final ds = _CaptureOrderSupabaseDatasource();
    final repo = OrderRepositoryImpl(ds);

    await repo.createPaidOrderFromPaystack(
      reference: 'ref_123',
      userId: 'user_123',
      subtotal: 10,
      deliveryFee: 2,
      discount: 0,
      tip: 1,
      total: 13,
      addressSnapshot: const {'label': 'Home'},
      items: const [
        OrderItemDraft(
          itemId: 'item_1',
          nameSnapshot: 'Fried rice',
          qty: 1,
          price: 10,
          variantSnapshot: null,
          addonsSnapshot: [],
        ),
      ],
    );

    expect(ds.lastReference, 'ref_123');
    expect(ds.lastUserId, 'user_123');
  });
}

