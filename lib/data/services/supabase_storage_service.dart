import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  SupabaseStorageService(this._client);

  final SupabaseClient _client;

  String? publicUrl({required String bucket, required String? path}) {
    var normalizedPath = (path ?? '').trim();
    if (normalizedPath.isEmpty) return null;
    if (normalizedPath.startsWith('http://') ||
        normalizedPath.startsWith('https://')) {
      return normalizedPath;
    }

    if (normalizedPath.startsWith('/')) {
      normalizedPath = normalizedPath.substring(1);
    }

    const marker = 'storage/v1/object/public/';
    final markerIndex = normalizedPath.indexOf(marker);
    if (markerIndex != -1) {
      final after = normalizedPath.substring(markerIndex + marker.length);
      if (after.startsWith('$bucket/')) {
        normalizedPath = after.substring(bucket.length + 1);
      }
    }

    if (normalizedPath.startsWith('$bucket/')) {
      normalizedPath = normalizedPath.substring(bucket.length + 1);
    }

    return _client.storage.from(bucket).getPublicUrl(normalizedPath);
  }
}
