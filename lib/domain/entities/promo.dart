enum PromoType { percent, fixed }

class Promo {
  const Promo({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    required this.minSubtotal,
    required this.isActive,
    this.expiresAt,
  });

  final String id;
  final String code;
  final PromoType type;
  final double value;
  final double minSubtotal;
  final DateTime? expiresAt;
  final bool isActive;
}

