import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _session = Supabase.instance.client.auth.currentSession;
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      _session = data.session;
      AppLogger.d('auth_state_change: ${data.event}', tag: 'auth');
      notifyListeners();
    });
  }

  Session? _session;
  late final StreamSubscription<AuthState> _sub;

  Session? get session => _session;
  User? get user => _session?.user;

  bool get isSignedIn => _session != null;

  bool get isGuest {
    final u = user;
    if (u == null) return false;

    final provider = u.appMetadata['provider'];
    return provider == 'anonymous';
  }

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    AppLogger.i('sign_in_with_password', tag: 'auth');
    try {
      await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
    } catch (error, stackTrace) {
      AppLogger.e('sign_in_with_password_failed', tag: 'auth', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? name,
    String? phone,
  }) async {
    AppLogger.i('sign_up', tag: 'auth');
    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
        },
      );
    } catch (error, stackTrace) {
      AppLogger.e('sign_up_failed', tag: 'auth', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> signInAnonymously() async {
    AppLogger.i('sign_in_anonymously', tag: 'auth');
    try {
      await Supabase.instance.client.auth.signInAnonymously();
    } catch (error, stackTrace) {
      AppLogger.e('sign_in_anonymously_failed', tag: 'auth', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    AppLogger.i('sign_out', tag: 'auth');
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (error, stackTrace) {
      AppLogger.e('sign_out_failed', tag: 'auth', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
