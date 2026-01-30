import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app.dart';
import 'core/env/app_env.dart';
import 'core/utils/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.e(
      'flutter_error',
      tag: 'error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  await runZonedGuarded(
    () async {
      if (AppEnv.isSupabaseConfigured) {
        await Supabase.initialize(
          url: AppEnv.supabaseUrl,
          anonKey: AppEnv.supabaseAnonKey,
        );
      }

      runApp(App(isSupabaseConfigured: AppEnv.isSupabaseConfigured));
    },
    (error, stackTrace) {
      AppLogger.e(
        'uncaught_zone_error',
        tag: 'error',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}
