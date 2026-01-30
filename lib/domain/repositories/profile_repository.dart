import '../entities/profile.dart';

abstract class ProfileRepository {
  Future<Profile> fetchMyProfile({required String userId});

  Future<Profile> updateMyProfile({
    required String userId,
    required String name,
    required String phone,
    required String defaultDeliveryNote,
  });
}

