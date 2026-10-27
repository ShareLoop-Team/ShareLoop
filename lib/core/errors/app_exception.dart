/// A failure with a message fit to show the user. Repositories throw this
/// for anything the user can act on (wrong password, item already taken,
/// no connection) so controllers never need to know which backend failed.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}
