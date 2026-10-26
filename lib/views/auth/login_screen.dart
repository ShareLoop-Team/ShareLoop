import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/login_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/auth_form_widgets.dart';

/// View: login form. Validation of empty fields happens in the form; the
/// login action and navigation are delegated to [LoginController].
///
/// Always uses the light brand theme so it matches the design even when the
/// device is in dark mode (same as the onboarding screen).
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(data: AppTheme.lightTheme, child: const _LoginView());
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  static const String _wordmarkAsset =
      'assets/images/shareloop_wordmark_green.png';
  static const String _illustrationAsset =
      'assets/images/login_illustration.png';

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _controller = LoginController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _submit(AuthController auth) {
    if (!_formKey.currentState!.validate()) return;
    _controller.submit(
      auth: auth,
      navigator: Navigator.of(context),
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  void _showForgotPasswordUnavailable(AppLocalizations l10n) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.loginForgotPasswordUnavailable)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final auth = context.watch<AuthController>();

    return Scaffold(
      body: Stack(
        children: [
          const AuthCornerCircles(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) => Form(
                      key: _formKey,
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Semantics(
                              label: l10n.appTitle,
                              child: ExcludeSemantics(
                                child: Image.asset(
                                  _wordmarkAsset,
                                  height: 24,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 56),
                            Semantics(
                              header: true,
                              child: Text(
                                l10n.loginWelcomeBack,
                                textAlign: TextAlign.center,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.loginSubtitle,
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const ExcludeSemantics(
                              child: Center(
                                child: SizedBox(
                                  width: 185,
                                  child: AspectRatio(
                                    aspectRatio: 185 / 138,
                                    child: Image(
                                      image: AssetImage(_illustrationAsset),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            TextFormField(
                              controller: _emailController,
                              decoration: authInputDecoration(
                                l10n.loginEmailHint,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                  ? l10n.loginEmailRequired
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _controller.obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onFieldSubmitted: (_) => _submit(auth),
                              decoration: authInputDecoration(
                                l10n.loginPasswordHint,
                                suffixIcon: PasswordVisibilityButton(
                                  obscured: _controller.obscurePassword,
                                  onPressed:
                                      _controller.togglePasswordVisibility,
                                  showTooltip: l10n.loginShowPassword,
                                  hideTooltip: l10n.loginHidePassword,
                                ),
                              ),
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                  ? l10n.loginPasswordRequired
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Flexible(
                                  child: _RememberMe(
                                    label: l10n.loginRememberMe,
                                    value: _controller.rememberMe,
                                    onChanged: _controller.setRememberMe,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: TextButton(
                                      onPressed: () =>
                                          _showForgotPasswordUnavailable(l10n),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.brightGreen,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        textStyle: textTheme.bodySmall,
                                      ),
                                      child: Text(
                                        l10n.loginForgotPassword,
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (auth.errorMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                auth.errorMessage!,
                                textAlign: TextAlign.center,
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: 28),
                            AuthPrimaryButton(
                              label: l10n.loginSignIn,
                              isLoading: auth.isLoading,
                              onPressed: () => _submit(auth),
                            ),
                            const SizedBox(height: 20),
                            _OrDivider(label: l10n.loginOr),
                            const SizedBox(height: 12),
                            AuthSwitchPrompt(
                              question: l10n.loginNoAccount,
                              actionLabel: l10n.loginCreateAccount,
                              onPressed: () => _controller.openRegister(
                                Navigator.of(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Checkbox with a tappable label.
class _RememberMe extends StatelessWidget {
  const _RememberMe({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 18,
                child: Checkbox(
                  value: value,
                  onChanged: (checked) => onChanged(checked ?? false),
                  activeColor: AppColors.brightGreen,
                  side: const BorderSide(
                    color: AppColors.brightGreen,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thin line – "or" – thin line.
class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Divider(color: AppColors.textSecondary.withValues(alpha: 0.2)),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        line,
      ],
    );
  }
}
