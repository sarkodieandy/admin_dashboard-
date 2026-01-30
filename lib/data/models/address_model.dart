import '../../domain/entities/address.dart';

class AddressModel {
  const AddressModel({
    required this.id,
    required this.userId,
    required this.label,
    required this.address,
    required this.isDefault,
    this.landmark,
    this.lat,
    this.lng,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      label: json['label'] as String? ?? '',
      address: json['address'] as String? ?? '',
      landmark: json['landmark'] as String?,
      lat: _toDouble(json['lat']),
      lng: _toDouble(json['lng']),
      isDefault: (json['is_default'] as bool?) ?? false,
    );
  }

  final String id;
  final String userId;
  final String label;
  final String address;
  final String? landmark;
  final double? lat;
  final double? lng;
  final bool isDefault;

  Address toEntity() => Address(
        id: id,
        userId: userId,
        label: label,
        address: address,
        landmark: landmark,
        lat: lat,
        lng: lng,
        isDefault: isDefault,
      );

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    return double.tryParse(v.toString());
  }
}

