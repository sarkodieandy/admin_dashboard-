class AppEnv {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qffpfgrktxucmkoylhnx.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFmZnBmZ3JrdHh1Y21rb3lsaG54Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM0NDAyMzUsImV4cCI6MjA3OTAxNjIzNX0.1whCRqVwqvpqf497zMxUbSHWwQ_LpACteNPcjKGhD6M',
  );

  static bool get isSupabaseConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  static const paystackCallbackUrl = String.fromEnvironment(
    'PAYSTACK_CALLBACK_URL',
    defaultValue: 'https://fingerlicking.app/paystack-callback',
  );
}
