import '../../domain/entities/address.dart';
import '../../domain/repositories/address_repository.dart';
import '../datasources/address_supabase_datasource.dart';

class AddressRepositoryImpl implements AddressRepository {
  AddressRepositoryImpl(this._datasource);

  final AddressSupabaseDatasource _datasource;

  @override
  Future<List<Address>> fetchMyAddresses({required String userId}) async {
    final models = await _datasource.fetchMyAddresses(userId: userId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Address> createAddress({
    required String userId,
    required String label,
    required String address,
    required String landmark,
    double? lat,
    double? lng,
    required bool isDefault,
  }) async {
    if (isDefault) {
      await _datasource.unsetDefaultForUser(userId: userId);
    }

    final model = await _datasource.createAddress(
      userId: userId,
      label: label,
      address: address,
      landmark: landmark,
      lat: lat,
      lng: lng,
      isDefault: isDefault,
    );
    return model.toEntity();
  }

  @override
  Future<Address> updateAddress({
    required String id,
    required String userId,
    required String label,
    required String address,
    required String landmark,
    double? lat,
    double? lng,
    required bool isDefault,
  }) async {
    if (isDefault) {
      await _datasource.unsetDefaultForUser(userId: userId);
    }

    final model = await _datasource.updateAddress(
      id: id,
      userId: userId,
      label: label,
      address: address,
      landmark: landmark,
      lat: lat,
      lng: lng,
      isDefault: isDefault,
    );
    return model.toEntity();
  }

  @override
  Future<void> deleteAddress({required String id, required String userId}) async {
    await _datasource.deleteAddress(id: id, userId: userId);
  }

  @override
  Future<void> setDefault({required String userId, required String addressId}) {
    return _datasource.setDefault(userId: userId, addressId: addressId);
  }
}

