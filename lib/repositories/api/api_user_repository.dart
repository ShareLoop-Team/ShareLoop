import '../../core/errors/app_exception.dart';
import '../../models/email_code.dart';
import '../../models/photo_upload.dart';
import '../../models/user_model.dart';
import '../../services/api_client.dart';
import '../../services/google_auth_service.dart';
import '../user_repository.dart';
import 'api_item_post_repository.dart';
import 'api_rows.dart';

/// [UserRepository] backed by the Laravel API: email + password accounts
/// with a bearer token kept on the device until logout.
class ApiUserRepository implements UserRepository {
  ApiClient get _api => ApiClient.instance;

  /// Remembered so updateUser can check it edits the signed-in account.
  static String? _currentUserId;

  Future<UserModel> _signedIn(dynamic body) async {
    final map = body as Map<String, dynamic>;
    await _api.saveToken(map['token'] as String);
    final user = ApiRows.user(map['user'] as Map<String, dynamic>);
    _currentUserId = user.id;
    return user;
  }

  @override
  Future<UserModel?> login(String email, String password) async {
    final body = await _api.post('/auth/login', {
      'email': email,
      'password': password,
      'device_name': 'shareloop-app',
    });
    return _signedIn(body);
  }

  @override
  Future<EmailCodeTicket> requestEmailCode(
    String email,
    EmailCodePurpose purpose, {
    PendingRegistration? registration,
  }) async {
    final body = await _api.post('/auth/code', {
      'email': email,
      'purpose': purpose.name,
      if (registration != null) ...{
        'name': registration.name,
        'password': registration.password,
        'phone': registration.phone,
        'district': registration.district,
        'city': registration.city,
      },
    }) as Map<String, dynamic>;
    return EmailCodeTicket(
      email: email,
      purpose: purpose,
      resendInSeconds: body['resend_in'] as int? ?? 60,
      debugCode: body['debug_code'] as String?,
    );
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String district,
    required String city,
    required String code,
  }) async {
    final body = await _api.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'district': district,
      'city': city,
      'code': code,
      'device_name': 'shareloop-app',
    });
    return _signedIn(body);
  }

  @override
  Future<UserModel> loginWithCode(String email, String code) async {
    final body = await _api.post('/auth/login-with-code', {
      'email': email,
      'code': code,
      'device_name': 'shareloop-app',
    });
    return _signedIn(body);
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _api.post('/auth/reset-password', {
      'email': email,
      'code': code,
      'password': newPassword,
    });
  }

  @override
  Future<Object> signInWithGoogle(
    String idToken, {
    String? name,
    String? phone,
    String? district,
    String? city,
  }) async {
    final body = await _api.post('/auth/google', {
      'id_token': idToken,
      'name': ?name,
      'phone': ?phone,
      'district': ?district,
      'city': ?city,
      'device_name': 'shareloop-app',
    }) as Map<String, dynamic>;
    if (body['needs_profile'] == true) {
      return GoogleSignUpNeeded(
        idToken: idToken,
        email: body['email'] as String? ?? '',
        name: body['name'] as String? ?? '',
      );
    }
    return _signedIn(body);
  }

  @override
  Future<Object> signInWithFacebook(
    String accessToken, {
    String? name,
    String? phone,
    String? district,
    String? city,
  }) async {
    final body = await _api.post('/auth/facebook', {
      'access_token': accessToken,
      'name': ?name,
      'phone': ?phone,
      'district': ?district,
      'city': ?city,
      'device_name': 'shareloop-app',
    }) as Map<String, dynamic>;
    if (body['needs_profile'] == true) {
      return GoogleSignUpNeeded(
        idToken: accessToken,
        email: body['email'] as String? ?? '',
        name: body['name'] as String? ?? '',
        provider: SocialProvider.facebook,
      );
    }
    return _signedIn(body);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    if (!_api.hasToken) return null;
    try {
      final user = ApiRows.user(ApiRows.object(await _api.get('/auth/me')));
      _currentUserId = user.id;
      return user;
    } on AppException catch (e) {
      // Expired, revoked (the client already dropped the token) or
      // suspended: start again from the welcome screen. Anything else, like
      // no connection, keeps the token for next time.
      if (!_api.hasToken || e.message == 'This account has been suspended.') {
        await _api.clearToken();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<UserModel?> getUserById(String id) async {
    try {
      return ApiRows.user(ApiRows.object(await _api.get('/users/$id')));
    } on AppException catch (e) {
      if (e.message == 'Not found.') {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    final body = await _api.get('/users');
    return [for (final row in ApiRows.list(body)) ApiRows.user(row)];
  }

  @override
  Future<void> updateUser(UserModel user) async {
    if (_currentUserId != null && user.id != _currentUserId) {
      throw const AppException('You can only edit your own profile.');
    }
    await _api.patch('/me', {
      'name': user.name,
      'phone': user.phone,
      'district': user.district,
      'city': user.city,
    });
  }

  @override
  Future<String?> updateAvatar(String userId, PhotoUpload photo) async {
    if (_currentUserId != null && userId != _currentUserId) {
      throw const AppException('You can only edit your own profile.');
    }
    ApiItemPostRepository.checkPhotos([photo]);
    final body = await _api.postMultipart(
      '/me/avatar',
      fields: const {},
      photos: [photo],
      fileField: 'photo',
    );
    return ApiRows.user(ApiRows.object(body)).avatarUrl;
  }

  @override
  Future<void> logout() async {
    try {
      if (_api.hasToken) await _api.post('/auth/logout');
    } on AppException {
      // Signing out locally is what matters.
    } finally {
      _currentUserId = null;
      await _api.clearToken();
      await GoogleAuthService.instance.signOut();
    }
  }
}
