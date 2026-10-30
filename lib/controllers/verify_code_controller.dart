import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/email_code.dart';
import 'auth_controller.dart';

/// Controller: state for the "enter the emailed code" screen: the current
/// ticket, the resend countdown and password visibility (reset only).
class VerifyCodeController extends ChangeNotifier {
  VerifyCodeController(EmailCodeTicket ticket) : _ticket = ticket {
    _startCountdown(ticket.resendInSeconds);
  }

  EmailCodeTicket _ticket;
  Timer? _timer;

  /// Seconds until another code may be requested (0 = now).
  int secondsUntilResend = 0;

  bool obscurePassword = true;

  EmailCodeTicket get ticket => _ticket;

  bool get canResend => secondsUntilResend == 0;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    secondsUntilResend = seconds;
    notifyListeners();
    if (seconds <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsUntilResend = secondsUntilResend > 0 ? secondsUntilResend - 1 : 0;
      if (secondsUntilResend == 0) timer.cancel();
      notifyListeners();
    });
  }

  /// Emails a new code. Returns whether it was sent.
  Future<bool> resend(
    AuthController auth, {
    PendingRegistration? registration,
  }) async {
    if (!canResend) return false;
    final ticket = await auth.requestEmailCode(
      _ticket.email,
      _ticket.purpose,
      registration: registration,
    );
    if (ticket == null) return false;
    _ticket = ticket;
    _startCountdown(ticket.resendInSeconds);
    return true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
