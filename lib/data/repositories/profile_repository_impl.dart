import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_supabase_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._datasource);

  final ProfileSupabaseDatasource _datasource;

  @override
  Future<Profile> fetchMyProfile({required String userId}) async {
    final model = await _datasource.fetchMyProfile(userId: userId);
    return model.toEntity();
  }

  @override
  Future<Profile> updateMyProfile({
    required String userId,
    required String name,
    required String phone,
    required String defaultDeliveryNote,
  }) async {
    final model = await _datasource.updateMyProfile(
      userId: userId,
      name: name,
      phone: phone,
      defaultDeliveryNote: defaultDeliveryNote,
    );
    return model.toEntity();
  }
}

