class AppConstants {
  const AppConstants._();

  static const appName = 'Moniary';
  static const defaultTimezone = 'Asia/Ho_Chi_Minh';

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://iegjdbcmngtpjoldbixs.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_92rDMp51wgUdNtyAH792QA_MR82rukr',
  );

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
