class Profile {
  const Profile({
    required this.id,
    required this.role,
    this.name,
    this.phone,
    this.defaultDeliveryNote,
  });

  final String id;
  final String? name;
  final String? phone;
  final String? defaultDeliveryNote;
  final String role;

  bool get isComplete =>
      (name ?? '').trim().isNotEmpty && (phone ?? '').trim().isNotEmpty;
}

