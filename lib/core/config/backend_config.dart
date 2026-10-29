/// Client configuration for the ShareLoop Laravel API, passed at build time:
///
///   flutter run --dart-define-from-file=.env
///
/// (see `.env.example`). When API_BASE_URL is absent (tests, offline UI work)
/// the app runs entirely on [MockDataService] instead.
library;

class BackendConfig {
  BackendConfig._();

  /// Root of the Laravel API, e.g. http://localhost:8000/api (web/desktop)
  /// or http://10.0.2.2:8000/api (Android emulator).
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static bool get isConfigured => apiBaseUrl.isNotEmpty;

  /// The Google OAuth **Web** client ID ("Sign in with Google"). On Android
  /// it is used as the server client ID so the ID token is issued for the
  /// same audience the backend checks (GOOGLE_CLIENT_IDS in backend/.env).
  static const String googleClientId =
      String.fromEnvironment('GOOGLE_CLIENT_ID');

  static bool get isGoogleConfigured =>
      isConfigured && googleClientId.isNotEmpty;

  /// The Meta (Facebook) App ID for "Continue with Facebook". Not a secret;
  /// the App Secret lives only in backend/.env (FACEBOOK_APP_SECRET).
  static const String facebookAppId =
      String.fromEnvironment('FACEBOOK_APP_ID');

  static bool get isFacebookConfigured =>
      isConfigured && facebookAppId.isNotEmpty;

  /// Matches the backend's per-photo limit (config/shareloop.php).
  static const int maxImageBytes = 5 * 1024 * 1024;

  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
  ];

  /// Rows fetched per feed page.
  static const int pageSize = 50;

  /// How long to wait for the API before giving up on a request.
  static const Duration requestTimeout = Duration(seconds: 20);
}
