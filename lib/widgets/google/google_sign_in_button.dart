import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/config/backend_config.dart';
import '../../core/routes/app_routes.dart';
import '../../models/email_code.dart';
import '../../models/user_model.dart';
import '../../services/google_auth_service.dart';
import '../auth_form_widgets.dart';
import 'google_web_button_stub.dart'
    if (dart.library.js_interop) 'google_web_button_web.dart';

/// "Sign in with Google" for the login and register screens. Signs in an
/// existing account, or opens the finish-sign-up screen for a new person.
/// Without GOOGLE_CLIENT_ID (mock data, tests) it shows the plain button
/// and [onUnavailable] runs instead.
class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({
    super.key,
    required this.label,
    required this.onUnavailable,
  });

  final String label;
  final VoidCallback onUnavailable;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  final List<StreamSubscription<String>> _subscriptions = [];
  bool _ready = !kIsWeb;
  bool _busy = false;

  bool get _enabled => BackendConfig.isGoogleConfigured;

  @override
  void initState() {
    super.initState();
    if (!_enabled) return;
    final google = GoogleAuthService.instance;
    _subscriptions
      ..add(google.idTokens.listen(_handleIdToken))
      ..add(google.errors.listen(_handleError));
    google.ensureInitialized().then((_) {
      if (mounted) setState(() => _ready = true);
    }, onError: (Object _) {
      if (mounted) {
        _handleError('Google sign-in is not available right now.');
      }
    });
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  Future<void> _handleIdToken(String idToken) async {
    if (_busy || !mounted) return;
    setState(() => _busy = true);
    final auth = context.read<AuthController>();
    final navigator = Navigator.of(context);
    final result = await auth.signInWithGoogle(idToken);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result is UserModel) {
      navigator.pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
    } else if (result is GoogleSignUpNeeded) {
      navigator.pushNamed(AppRoutes.completeGoogleProfile, arguments: result);
    }
  }

  void _handleError(String message) {
    if (!mounted) return;
    context.read<AuthController>().reportError(message);
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled) {
      return AuthSocialButton(
        asset: AuthSocialButton.googleLogo,
        label: widget.label,
        onPressed: widget.onUnavailable,
      );
    }
    if (_busy) {
      return const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (kIsWeb) {
      return SizedBox(
        height: 48,
        child: Center(
          child: _ready ? buildGoogleWebButton() : const SizedBox.shrink(),
        ),
      );
    }
    return AuthSocialButton(
      asset: AuthSocialButton.googleLogo,
      label: widget.label,
      onPressed: GoogleAuthService.instance.signIn,
    );
  }
}
