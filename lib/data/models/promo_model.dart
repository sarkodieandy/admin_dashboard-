import '../../domain/entities/promo.dart';

class PromoModel {
  const PromoModel({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    required this.minSubtotal,
    required this.isActive,
    this.expiresAt,
  });

  factory PromoModel.fromJson(Map<String, dynamic> json) {
    final typeRaw = (json['type'] as String?)?.toLowerCase().trim() ?? '';
    final promoType = switch (typeRaw) {
      'percent' => PromoType.percent,
      'fixed' => PromoType.fixed,
      _ => PromoType.fixed,
    };

    return PromoModel(
      id: json['id'] as String,
      code: (json['code'] as String).toUpperCase(),
      type: promoType,
      value: _toDouble(json['value']),
      minSubtotal: _toDouble(json['min_subtotal']),
      expiresAt: json['expires_at'] == null ? null : DateTime.parse(json['expires_at'] as String),
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }

  final String id;
  final String code;
  final PromoType type;
  final double value;
  final double minSubtotal;
  final DateTime? expiresAt;
  final bool isActive;

  Promo toEntity() => Promo(
        id: id,
        code: code,
        type: type,
        value: value,
        minSubtotal: minSubtotal,
        expiresAt: expiresAt,
        isActive: isActive,
      );

  static double _toDouble(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;
}

