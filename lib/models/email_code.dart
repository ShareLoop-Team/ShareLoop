/// What an emailed one-time code is for.
enum EmailCodePurpose { register, login, reset }

/// Model: a one-time code that has just been emailed.
class EmailCodeTicket {
  final String email;
  final EmailCodePurpose purpose;

  /// Seconds before another code may be requested.
  final int resendInSeconds;

  /// Only set when the backend has no real mailer (local development), so
  /// the code can be shown on screen instead.
  final String? debugCode;

  const EmailCodeTicket({
    required this.email,
    required this.purpose,
    this.resendInSeconds = 60,
    this.debugCode,
  });
}

/// The registration form's details, held while the email code is entered.
class PendingRegistration {
  final String name;
  final String email;
  final String password;
  final String phone;
  final String district;
  final String city;

  const PendingRegistration({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.district,
    required this.city,
  });
}

/// Arguments for the verify-code screen.
class VerifyCodeArgs {
  final EmailCodeTicket ticket;

  /// Set when [ticket] is for registration.
  final PendingRegistration? registration;

  const VerifyCodeArgs({required this.ticket, this.registration});
}

/// Result of "Sign in with Google": either signed in, or a new person who
/// still has to give a phone number and district.
class GoogleSignUpNeeded {
  final String idToken;
  final String email;
  final String name;

  const GoogleSignUpNeeded({
    required this.idToken,
    required this.email,
    required this.name,
  });
}
