/// Public client configuration for the real backend, passed at build time:
///
///   flutter run --dart-define-from-file=.env
///
/// (see `.env.example`). Both values are safe to ship in the app — access is
/// enforced by Row Level Security, never by keeping them secret. Server-only
/// credentials (service-role key, database password) must never appear here.
///
/// When they are absent (tests, offline UI work) the app runs entirely on
/// [MockDataService] instead.
library;

class BackendConfig {
  BackendConfig._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// The project's publishable (or legacy anon) key.
  static const String supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  /// Supabase Storage bucket for item photos (see the storage migration).
  static const String itemImagesBucket = 'item-images';

  /// Matches the bucket's file_size_limit.
  static const int maxImageBytes = 5 * 1024 * 1024;

  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
  ];

  /// How long signed photo URLs stay valid.
  static const Duration signedUrlLifetime = Duration(hours: 1);

  /// Rows fetched per feed page.
  static const int pageSize = 50;
}
