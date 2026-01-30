import '../../domain/entities/profile.dart';

class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.role,
    this.name,
    this.phone,
    this.defaultDeliveryNote,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      defaultDeliveryNote: json['default_delivery_note'] as String?,
      role: (json['role'] as String?) ?? 'customer',
    );
  }

  final String id;
  final String? name;
  final String? phone;
  final String? defaultDeliveryNote;
  final String role;

  Profile toEntity() => Profile(
        id: id,
        name: name,
        phone: phone,
        defaultDeliveryNote: defaultDeliveryNote,
        role: role,
      );
}

