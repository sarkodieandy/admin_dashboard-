import 'cart_line.dart';

class CartSnapshot {
  const CartSnapshot({
    required this.lines,
    this.promoCode,
    this.tip = 0,
    this.scheduledFor,
  });

  factory CartSnapshot.empty() => const CartSnapshot(lines: []);

  factory CartSnapshot.fromJson(Map<String, dynamic> json) {
    final linesJson = json['lines'];
    return CartSnapshot(
      lines: linesJson is List
          ? linesJson.whereType<Map<String, dynamic>>().map(CartLine.fromJson).toList()
          : const [],
      promoCode: (json['promoCode'] as String?)?.trim(),
      tip: double.tryParse(json['tip']?.toString() ?? '') ?? 0,
      scheduledFor:
          json['scheduledFor'] == null ? null : DateTime.parse(json['scheduledFor'] as String),
    );
  }

  final List<CartLine> lines;
  final String? promoCode;
  final double tip;
  final DateTime? scheduledFor;

  Map<String, dynamic> toJson() => {
        'lines': lines.map((l) => l.toJson()).toList(),
        'promoCode': promoCode,
        'tip': tip,
        'scheduledFor': scheduledFor?.toIso8601String(),
      };
}

