class Address {
  const Address({
    required this.id,
    required this.userId,
    required this.label,
    required this.address,
    required this.isDefault,
    this.landmark,
    this.lat,
    this.lng,
  });

  final String id;
  final String userId;
  final String label;
  final String address;
  final String? landmark;
  final double? lat;
  final double? lng;
  final bool isDefault;

  String get title => label.trim().isEmpty ? 'Address' : label;

  String get subtitle {
    final parts = <String>[
      address.trim(),
      if ((landmark ?? '').trim().isNotEmpty) 'Landmark: ${landmark!.trim()}',
    ].where((e) => e.isNotEmpty).toList();
    return parts.join(' • ');
  }
}

