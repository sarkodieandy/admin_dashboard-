import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/cart_addon.dart';
import '../../domain/entities/cart_line.dart';
import '../../domain/entities/cart_snapshot.dart';
import '../../domain/entities/item_addon.dart';
import '../../domain/entities/item_variant.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/promo.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../domain/repositories/menu_repository.dart';

class CartProvider extends ChangeNotifier {
  CartProvider({
    required CartRepository repository,
    required MenuRepository menuRepository,
    double? deliveryBaseFee,
    double? minimumOrderSubtotal,
  })  : _repository = repository,
        _menuRepository = menuRepository,
        _deliveryBaseFee = (deliveryBaseFee ?? AppConstants.baseDeliveryFee)
            .clamp(0.0, double.infinity)
            .toDouble(),
        _minimumOrderSubtotal =
            (minimumOrderSubtotal ?? AppConstants.minOrderSubtotal)
                .clamp(0.0, double.infinity)
                .toDouble() {
    unawaited(_restore());
  }

  final CartRepository _repository;
  final MenuRepository _menuRepository;

  final _uuid = const Uuid();

  bool _isRestoring = true;
  String? _error;

  List<CartLine> _lines = [];
  Promo? _promo;
  String? _promoCode;
  String? _promoError;
  bool _isApplyingPromo = false;

  double _tip = 0;
  DateTime? _scheduledFor;

  double _deliveryBaseFee;
  double _minimumOrderSubtotal;

  double get baseDeliveryFee => _deliveryBaseFee;
  double get minimumOrderSubtotal => _minimumOrderSubtotal;
  bool get hasMinimumOrder => _minimumOrderSubtotal > 0;

  bool get isRestoring => _isRestoring;
  String? get error => _error;
  List<CartLine> get lines => List.unmodifiable(_lines);

  Promo? get promo => _promo;
  String? get promoCode => _promoCode;
  String? get promoError => _promoError;
  bool get isApplyingPromo => _isApplyingPromo;

  double get tip => _tip;
  DateTime? get scheduledFor => _scheduledFor;

  int get itemCount => _lines.fold<int>(0, (sum, l) => sum + l.qty);

  double get subtotal => _lines.fold<double>(0, (sum, l) => sum + l.total);

  double get deliveryFee => _lines.isEmpty ? 0 : _deliveryBaseFee;

  double get discount {
    final promo = _promo;
    if (promo == null) return 0;
    if (subtotal < promo.minSubtotal) return 0;

    final raw = switch (promo.type) {
      PromoType.percent => subtotal * (promo.value / 100),
      PromoType.fixed => promo.value,
    };

    if (raw < 0) return 0;
    if (raw > subtotal) return subtotal;
    return raw;
  }

  double get total => (subtotal + deliveryFee - discount + _tip).clamp(0, double.infinity);

  bool get meetsMinimumOrder => subtotal >= _minimumOrderSubtotal;

  void setDeliveryRules({
    required double deliveryBaseFee,
    required double minimumOrderSubtotal,
  }) {
    final nextBase = deliveryBaseFee.clamp(0.0, double.infinity).toDouble();
    final nextMin = minimumOrderSubtotal.clamp(0.0, double.infinity).toDouble();
    if (nextBase == _deliveryBaseFee && nextMin == _minimumOrderSubtotal) return;
    _deliveryBaseFee = nextBase;
    _minimumOrderSubtotal = nextMin;
    notifyListeners();
  }

  Future<void> _restore() async {
    _isRestoring = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _repository.load();
      _lines = snapshot.lines;
      _promoCode = snapshot.promoCode?.trim();
      _tip = snapshot.tip;
      _scheduledFor = snapshot.scheduledFor;

      if ((_promoCode ?? '').isNotEmpty) {
        await _applyPromoInternal(_promoCode!, isRestore: true);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  Future<void> _persist() {
    return _repository.save(
      CartSnapshot(
        lines: _lines,
        promoCode: _promoCode,
        tip: _tip,
        scheduledFor: _scheduledFor,
      ),
    );
  }

  Future<void> clear() async {
    _lines = [];
    _promo = null;
    _promoCode = null;
    _promoError = null;
    _tip = 0;
    _scheduledFor = null;
    notifyListeners();
    await _repository.clear();
  }

  Future<void> addFromMenuItem({
    required MenuItem item,
    required int qty,
    required String note,
    ItemVariant? variant,
    List<ItemAddon> addons = const [],
  }) async {
    final safeQty = qty < 1 ? 1 : qty;
    final normalizedNote = note.trim();

    final line = CartLine(
      id: _uuid.v4(),
      itemId: item.id,
      name: item.name,
      imageUrl: item.imageUrl,
      basePrice: item.basePrice,
      qty: safeQty,
      note: normalizedNote,
      variantId: variant?.id,
      variantName: variant?.name,
      variantDelta: variant?.priceDelta ?? 0,
      addons: addons
          .map((a) => CartAddon(id: a.id, name: a.name, price: a.price))
          .toList(),
    );

    final key = _mergeKey(line);
    final idx = _lines.indexWhere((l) => _mergeKey(l) == key);
    if (idx >= 0) {
      final existing = _lines[idx];
      _lines[idx] = existing.copyWith(qty: existing.qty + line.qty);
    } else {
      _lines = [..._lines, line];
    }

    _promoError = null;
    notifyListeners();
    await _persist();
  }

  Future<void> removeLine(String lineId) async {
    _lines = _lines.where((l) => l.id != lineId).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> updateQty(String lineId, int qty) async {
    final clamped = qty < 1 ? 1 : qty;
    _lines = _lines.map((l) => l.id == lineId ? l.copyWith(qty: clamped) : l).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> updateNote(String lineId, String note) async {
    _lines = _lines.map((l) => l.id == lineId ? l.copyWith(note: note.trim()) : l).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> setTip(double tip) async {
    _tip = tip < 0 ? 0 : tip;
    notifyListeners();
    await _persist();
  }

  Future<void> setScheduledFor(DateTime? when) async {
    _scheduledFor = when;
    notifyListeners();
    await _persist();
  }

  Future<bool> applyPromoCode(String code) async {
    final normalized = code.trim();
    if (normalized.isEmpty) return false;
    return _applyPromoInternal(normalized, isRestore: false);
  }

  Future<bool> _applyPromoInternal(String code, {required bool isRestore}) async {
    _isApplyingPromo = true;
    _promoError = null;
    notifyListeners();

    try {
      final promo = await _menuRepository.fetchPromoByCode(code: code);
      if (promo == null || !promo.isActive) {
        _promo = null;
        _promoCode = null;
        if (!isRestore) _promoError = 'That code isn’t available right now.';
        notifyListeners();
        await _persist();
        return false;
      }

      if (subtotal < promo.minSubtotal) {
        _promo = promo;
        _promoCode = promo.code;
        if (!isRestore) _promoError = 'Add a bit more to use this promo.';
        notifyListeners();
        await _persist();
        return false;
      }

      _promo = promo;
      _promoCode = promo.code;
      notifyListeners();
      await _persist();
      return true;
    } catch (e) {
      if (!isRestore) _promoError = e.toString();
      return false;
    } finally {
      _isApplyingPromo = false;
      notifyListeners();
    }
  }

  Future<void> removePromo() async {
    _promo = null;
    _promoCode = null;
    _promoError = null;
    notifyListeners();
    await _persist();
  }

  static String _mergeKey(CartLine line) {
    final addonIds = [...line.addons.map((a) => a.id)]..sort();
    return [
      line.itemId,
      (line.variantId ?? ''),
      addonIds.join(','),
      line.note.trim(),
    ].join('|');
  }
}
