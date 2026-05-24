class AppConstants {
  const AppConstants._();

  static const appName = 'Moniary';
  static const defaultTimezone = 'Asia/Ho_Chi_Minh';

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
