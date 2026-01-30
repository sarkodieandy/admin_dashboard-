class DeliverySettings {
  const DeliverySettings({
    required this.baseFee,
    required this.freeRadiusKm,
    required this.perKmFeeAfterFreeRadius,
    required this.minimumOrderAmount,
    required this.maxDeliveryDistanceKm,
    this.updatedAt,
  });

  final double baseFee;
  final double freeRadiusKm;
  final double perKmFeeAfterFreeRadius;
  final double minimumOrderAmount;
  final double maxDeliveryDistanceKm;
  final DateTime? updatedAt;
}

