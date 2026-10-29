import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shareloop/core/errors/app_exception.dart';
import 'package:shareloop/repositories/firebase/firebase_user_repository.dart';
import 'package:shareloop/services/mock_data_service.dart';

/// Just enough of a Firebase user for [FirebaseUserRepository].
class _FakeUser implements User {
  _FakeUser({required this.uid, required this.email, this.displayName});

  @override
  final String uid;

  @override
  final String? email;

  @override
  String? displayName;

  /// Thrown by [reload], e.g. once the account has been disabled.
  FirebaseAuthException? reloadError;

  @override
  Future<void> updateDisplayName(String? displayName) async {
    this.displayName = displayName;
  }

  @override
  Future<void> sendEmailVerification([
    ActionCodeSettings? actionCodeSettings,
  ]) async {}

  @override
  Future<void> reload() async {
    if (reloadError case final error?) throw error;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _FakeCredential implements UserCredential {
  _FakeCredential(this.user);

  @override
  final User? user;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// In-memory stand-in for Firebase Authentication's email/password accounts.
class _FakeAuth implements FirebaseAuth {
  final Map<String, (String password, _FakeUser user)> accounts = {};
  final List<String> resetEmailsSent = [];

  @override
  User? currentUser;

  _FakeUser addAccount(String email, String password, {String? name}) {
    final user = _FakeUser(uid: 'fb-$email', email: email, displayName: name);
    accounts[email] = (password, user);
    return user;
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (accounts.containsKey(email)) {
      throw FirebaseAuthException(code: 'email-already-in-use');
    }
    final user = addAccount(email, password);
    currentUser = user;
    return _FakeCredential(user);
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final account = accounts[email];
    if (account == null || account.$1 != password) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    currentUser = account.$2;
    return _FakeCredential(account.$2);
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    if (!accounts.containsKey(email)) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    resetEmailsSent.add(email);
  }

  @override
  Future<void> signOut() async {
    currentUser = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  final data = MockDataService.instance;
  late _FakeAuth auth;
  late FirebaseUserRepository repository;
  var emailCounter = 0;
  String uniqueEmail() => 'firebase${emailCounter++}@example.com';

  setUp(() {
    auth = _FakeAuth();
    repository = FirebaseUserRepository(auth: auth);
    data.currentUserId = null;
  });

  test('register creates the Firebase account and signs in', () async {
    final email = uniqueEmail();
    final user = await repository.register(
      name: 'Kasun Silva',
      email: email,
      password: 'secret1',
      phone: '0771234567',
      district: 'Kandy',
      city: 'Peradeniya',
    );

    expect(auth.accounts, contains(email));
    expect(user.id, auth.currentUser!.uid);
    expect(user.district, 'Kandy');
    expect(auth.currentUser!.displayName, 'Kasun Silva');
    expect(data.currentUserId, user.id);
  });

  test('register reports an email that is already taken', () async {
    final email = uniqueEmail();
    auth.addAccount(email, 'secret1');

    expect(
      () => repository.register(
        name: 'Kasun Silva',
        email: email,
        password: 'secret1',
        phone: '0771234567',
        district: 'Kandy',
        city: '',
      ),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          contains('already exists'),
        ),
      ),
    );
  });

  test('login checks the password with Firebase', () async {
    final email = uniqueEmail();
    auth.addAccount(email, 'secret1', name: 'Dilani Fernando');

    expect(
      () => repository.login(email, 'wrong'),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          'Incorrect email or password.',
        ),
      ),
    );

    final user = await repository.login(email, 'secret1');
    // Not seen in this run yet, so the profile starts from Firebase's data.
    expect(user!.name, 'Dilani Fernando');
    expect(user.email, email);
    expect(data.currentUserId, user.id);
  });

  test('restores the Firebase session from a previous launch', () async {
    final email = uniqueEmail();
    auth.currentUser = auth.addAccount(email, 'secret1', name: 'Ruwan');

    final user = await repository.getCurrentUser();

    expect(user!.name, 'Ruwan');
    expect(data.currentUserId, user.id);
  });

  test('no session without a Firebase user', () async {
    expect(await repository.getCurrentUser(), isNull);
  });

  test('a disabled account is signed out instead of restored', () async {
    final user = auth.addAccount(uniqueEmail(), 'secret1');
    user.reloadError = FirebaseAuthException(code: 'user-disabled');
    auth.currentUser = user;

    expect(await repository.getCurrentUser(), isNull);
    expect(auth.currentUser, isNull);
  });

  test('profile edits update the Firebase display name', () async {
    final email = uniqueEmail();
    auth.addAccount(email, 'secret1', name: 'Old Name');
    final user = await repository.login(email, 'secret1');

    await repository.updateUser(user!.copyWith(name: 'New Name'));

    expect(auth.currentUser!.displayName, 'New Name');
    expect((await repository.getUserById(user.id))!.name, 'New Name');
  });

  test('password reset is sent without revealing unknown emails', () async {
    final email = uniqueEmail();
    auth.addAccount(email, 'secret1');

    expect(repository.supportsPasswordReset, isTrue);
    await repository.sendPasswordReset(email);
    await repository.sendPasswordReset('nobody@example.com');

    expect(auth.resetEmailsSent, [email]);
  });

  test('logout signs out of Firebase', () async {
    final email = uniqueEmail();
    auth.addAccount(email, 'secret1');
    await repository.login(email, 'secret1');

    await repository.logout();

    expect(auth.currentUser, isNull);
    expect(data.currentUserId, isNull);
  });
}
