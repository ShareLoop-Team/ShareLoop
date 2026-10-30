import '../core/config/backend_config.dart';
import '../core/errors/app_exception.dart';
import 'facebook_web_sdk_stub.dart'
    if (dart.library.js_interop) 'facebook_web_sdk_web.dart';

/// Service: "Continue with Facebook" on the device. Produces a Facebook user
/// access token (which the backend checks with Facebook); it never sees or
/// stores a password.
class FacebookAuthService {
  FacebookAuthService._();

  static final FacebookAuthService instance = FacebookAuthService._();

  Future<void>? _initialization;
  bool _ready = false;

  /// False outside the web app (see facebook_web_sdk_stub.dart).
  bool get isSupported => facebookSdkSupported;

  /// True once Facebook's SDK has loaded, so [signIn] can open its popup.
  bool get isReady => _ready;

  /// Loads Facebook's SDK. Call early: the login popup must open straight
  /// from a tap, with nothing left to download.
  Future<void> ensureInitialized() {
    return _initialization ??=
        initFacebookSdk(BackendConfig.facebookAppId).then((_) {
      _ready = true;
    }, onError: (Object error) {
      _initialization = null; // allow a retry later
      throw error;
    });
  }

  /// Opens Facebook's login popup. Returns the access token, or null when
  /// the person closed it. Throws [AppException] when it can't sign in.
  Future<String?> signIn() async {
    if (!isSupported) {
      throw const AppException(
          'Facebook sign-in is available in the web app for now.');
    }
    if (!_ready) {
      ensureInitialized().ignore();
      throw const AppException(
          'Facebook is still loading. Please try again in a moment.');
    }
    final String token;
    try {
      token = await loginWithFacebookSdk();
    } catch (_) {
      throw const AppException('Facebook sign-in failed. Please try again.');
    }
    return token.isEmpty ? null : token;
  }
}
