import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/cart_line.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/repositories/order_repository.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider({required OrderRepository repository}) : _repository = repository;

  final OrderRepository _repository;

  String? _userId;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  bool _hasMore = true;
  int _offset = 0;

  List<Order> _orders = const [];

  bool _isPlacingOrder = false;
  String? _placeError;

  bool get isReady => _userId != null;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;
  List<Order> get orders => _orders;

  bool get isPlacingOrder => _isPlacingOrder;
  String? get placeError => _placeError;

  void setUserId(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _orders = const [];
    _error = null;
    _offset = 0;
    _hasMore = true;
    notifyListeners();

    if (userId != null) {
      refresh();
    }
  }

  Future<void> refresh() async {
    if (_isLoading) return;
    if (_userId == null) return;

    _isLoading = true;
    _error = null;
    _offset = 0;
    _hasMore = true;
    notifyListeners();

    try {
      final items = await _repository.fetchMyOrders(limit: 20, offset: 0);
      _orders = items;
      _offset = items.length;
      _hasMore = items.length >= 20;
    } catch (error, stackTrace) {
      AppLogger.e('orders_refresh_failed', tag: 'orders', error: error, stackTrace: stackTrace);
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore) return;
    if (_userId == null) return;
    if (!_hasMore) return;

    _isLoadingMore = true;
    _error = null;
    notifyListeners();

    try {
      final next = await _repository.fetchMyOrders(limit: 20, offset: _offset);
      _orders = [..._orders, ...next];
      _offset += next.length;
      _hasMore = next.length >= 20;
    } catch (error, stackTrace) {
      AppLogger.e('orders_load_more_failed', tag: 'orders', error: error, stackTrace: stackTrace);
      _error = error.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<Order?> placeOrder({
    required Address address,
    required List<CartLine> lines,
    required double subtotal,
    required double deliveryFee,
    required double discount,
    required double tip,
    required double total,
    required PaymentMethod paymentMethod,
    required PaymentStatus paymentStatus,
    DateTime? scheduledFor,
  }) async {
    final userId = _userId;
    if (userId == null) return null;
    if (_isPlacingOrder) return null;

    _isPlacingOrder = true;
    _placeError = null;
    notifyListeners();

    try {
      AppLogger.i(
        'place_order_start method=${paymentMethod.name} status=${paymentStatus.name} scheduled=${scheduledFor != null}',
        tag: 'orders',
      );
      final order = await _repository.createOrder(
        userId: userId,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        discount: discount,
        tip: tip,
        total: total,
        addressSnapshot: {
          'label': address.label,
          'address': address.address,
          'landmark': address.landmark,
          'lat': address.lat,
          'lng': address.lng,
        },
        scheduledFor: scheduledFor,
        items: lines
            .map(
              (l) => OrderItemDraft(
                itemId: l.itemId,
                nameSnapshot: l.name,
                variantSnapshot: l.variantName,
                addonsSnapshot: [
                  for (final a in l.addons)
                    {
                      'id': a.id,
                      'name': a.name,
                      'price': a.price,
                    },
                ],
                qty: l.qty,
                price: l.unitPrice,
              ),
            )
            .toList(),
      );

      _orders = [order, ..._orders];
      _offset += 1;
      notifyListeners();
      AppLogger.i('place_order_ok orderId=${order.id}', tag: 'orders');
      return order;
    } catch (error, stackTrace) {
      AppLogger.e('place_order_failed', tag: 'orders', error: error, stackTrace: stackTrace);
      _placeError = error.toString();
      notifyListeners();
      return null;
    } finally {
      _isPlacingOrder = false;
      notifyListeners();
    }
  }

  Future<Order?> finalizePaystackOrder({
    required String reference,
    required Address address,
    required List<CartLine> lines,
    required double subtotal,
    required double deliveryFee,
    required double discount,
    required double tip,
    required double total,
    DateTime? scheduledFor,
  }) async {
    final userId = _userId;
    if (userId == null) return null;
    if (_isPlacingOrder) return null;

    _isPlacingOrder = true;
    _placeError = null;
    notifyListeners();

    try {
      AppLogger.i('paystack_finalize_start reference=$reference scheduled=${scheduledFor != null}', tag: 'orders');
      final order = await _repository.createPaidOrderFromPaystack(
        reference: reference,
        userId: userId,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        discount: discount,
        tip: tip,
        total: total,
        addressSnapshot: {
          'label': address.label,
          'address': address.address,
          'landmark': address.landmark,
          'lat': address.lat,
          'lng': address.lng,
        },
        scheduledFor: scheduledFor,
        items: lines
            .map(
              (l) => OrderItemDraft(
                itemId: l.itemId,
                nameSnapshot: l.name,
                variantSnapshot: l.variantName,
                addonsSnapshot: [
                  for (final a in l.addons)
                    {
                      'id': a.id,
                      'name': a.name,
                      'price': a.price,
                    },
                ],
                qty: l.qty,
                price: l.unitPrice,
              ),
            )
            .toList(),
      );

      _orders = [order, ..._orders];
      _offset += 1;
      notifyListeners();
      AppLogger.i('paystack_finalize_ok orderId=${order.id} reference=$reference', tag: 'orders');
      return order;
    } catch (error, stackTrace) {
      AppLogger.e(
        'paystack_finalize_failed reference=$reference',
        tag: 'orders',
        error: error,
        stackTrace: stackTrace,
      );
      _placeError = error.toString();
      notifyListeners();
      return null;
    } finally {
      _isPlacingOrder = false;
      notifyListeners();
    }
  }
}
