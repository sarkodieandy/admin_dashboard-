import '../entities/address.dart';

abstract class AddressRepository {
  Future<List<Address>> fetchMyAddresses({required String userId});

  Future<Address> createAddress({
    required String userId,
    required String label,
    required String address,
    required String landmark,
    double? lat,
    double? lng,
    required bool isDefault,
  });

  Future<Address> updateAddress({
    required String id,
    required String userId,
    required String label,
    required String address,
    required String landmark,
    double? lat,
    double? lng,
    required bool isDefault,
  });

  Future<void> deleteAddress({required String id, required String userId});

  Future<void> setDefault({required String userId, required String addressId});
}

