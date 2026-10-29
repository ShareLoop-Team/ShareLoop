import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/config/backend_config.dart';
import '../../core/errors/app_exception.dart';
import '../../core/routes/app_routes.dart';
import '../../models/email_code.dart';
import '../../models/user_model.dart';
import '../../services/facebook_auth_service.dart';
import '../auth_form_widgets.dart';

/// "Continue with Facebook" for the login and register screens. Signs in an
/// existing account, or opens the finish-sign-up screen for a new person.
/// Without FACEBOOK_APP_ID (mock data, tests) [onUnavailable] runs instead.
class FacebookSignInButton extends StatefulWidget {
  const FacebookSignInButton({
    super.key,
    required this.label,
    required this.onUnavailable,
  });

  final String label;
  final VoidCallback onUnavailable;

  @override
  State<FacebookSignInButton> createState() => _FacebookSignInButtonState();
}

class _FacebookSignInButtonState extends State<FacebookSignInButton> {
  bool _busy = false;

  bool get _enabled => BackendConfig.isFacebookConfigured;

  FacebookAuthService get _facebook => FacebookAuthService.instance;

  @override
  void initState() {
    super.initState();
    if (_enabled && _facebook.isSupported) {
      // Preload the SDK so the popup can open straight from the tap.
      _facebook.ensureInitialized().ignore();
    }
  }

  Future<void> _signIn() async {
    if (_busy) return;
    final auth = context.read<AuthController>();
    final navigator = Navigator.of(context);
    String? token;
    try {
      // Called before anything else is awaited, so the popup isn't blocked.
      token = await _facebook.signIn();
    } on AppException catch (e) {
      auth.reportError(e.message);
      return;
    }
    if (token == null || !mounted) return; // popup closed
    setState(() => _busy = true);
    final result = await auth.signInWithFacebook(token);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result is UserModel) {
      navigator.pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
    } else if (result is GoogleSignUpNeeded) {
      navigator.pushNamed(AppRoutes.completeGoogleProfile, arguments: result);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const SizedBox(
        height: 52,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return AuthSocialButton(
      asset: AuthSocialButton.facebookLogo,
      label: widget.label,
      onPressed: _enabled ? _signIn : widget.onUnavailable,
    );
  }
}
