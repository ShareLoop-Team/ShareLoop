import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/login_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/auth_form_widgets.dart';
import '../../widgets/pill_button.dart';

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

  /// Emails a reset link to the address typed in the email field.
  Future<void> _forgotPassword(
    AppLocalizations l10n,
    AuthController auth,
  ) async {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    void show(String message) =>
        messenger.showSnackBar(SnackBar(content: Text(message)));

    if (!auth.supportsPasswordReset) {
      show(l10n.loginForgotPasswordUnavailable);
      return;
    }
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      show(l10n.loginResetEnterEmail);
      return;
    }
    final error = await auth.sendPasswordReset(email);
    if (!mounted) return;
    show(error ?? l10n.loginResetSent(email));
  }

  /// Social sign-in isn't wired to a provider yet.
  void _socialSignIn(AppLocalizations l10n) => showAppSnackBar(
        ScaffoldMessenger.of(context),
        l10n.loginSocialUnavailable,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final auth = context.watch<AuthController>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Dark status bar icons on the light illustration.
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _LoginHero()),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
                    child: ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) => Form(
                        key: _formKey,
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // No visible title in this design; screen
                              // readers still announce the page.
                              Semantics(
                                header: true,
                                label: l10n.loginWelcomeBack,
                                child: const SizedBox(height: 12),
                              ),
                              TextFormField(
                                controller: _emailController,
                                decoration: authPillInputDecoration(
                                  l10n.loginEmailHint,
                                  icon: Icons.mail_outline,
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
                                decoration: authPillInputDecoration(
                                  l10n.loginPasswordHint,
                                  icon: Icons.lock_outline,
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
                                      alignment:
                                          AlignmentDirectional.centerEnd,
                                      child: TextButton(
                                        onPressed: () =>
                                            _forgotPassword(l10n, auth),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.deepGreen,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          textStyle: textTheme.bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
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
                              const SizedBox(height: 16),
                              PillButton(
                                label: l10n.loginSignIn,
                                isLoading: auth.isLoading,
                                onPressed: () => _submit(auth),
                              ),
                              const SizedBox(height: 20),
                              AuthOrDivider(label: l10n.loginOrContinueWith),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: AuthSocialTile(
                                      asset: AuthSocialTile.googleIcon,
                                      provider: 'Google',
                                      semanticsLabel: l10n.loginWithGoogle,
                                      onPressed: () => _socialSignIn(l10n),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AuthSocialTile(
                                      asset: AuthSocialTile.facebookIcon,
                                      provider: 'Facebook',
                                      semanticsLabel: l10n.loginWithFacebook,
                                      onPressed: () => _socialSignIn(l10n),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const SizedBox(height: 20),
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
      ),
    );
  }
}

/// Full-width illustration with the form's sheet rising over its bottom
/// edge: rounded top corners, a soft shadow and a small handle.
class _LoginHero extends StatelessWidget {
  const _LoginHero();

  static const String _asset = 'assets/images/login_hero.jpg';
  static const double _height = 340;
  static const double _sheetOverlap = 28;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    // Phones: the illustration fills the header edge to edge. Wide windows
    // (web, tablets) show it whole instead of cropping to a thin band.
    final fill = MediaQuery.sizeOf(context).width <= 600;
    return SizedBox(
      height: _height + topInset,
      child: Stack(
        children: [
          // The illustration's own background, so its edges never show.
          const Positioned.fill(
            child: ColoredBox(color: AppColors.introBackground),
          ),
          Positioned.fill(
            bottom: fill ? 0 : _sheetOverlap - 6,
            child: ExcludeSemantics(
              child: Image(
                image: const AssetImage(_asset),
                fit: fill ? BoxFit.cover : BoxFit.contain,
                alignment: const Alignment(0, 0.35),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _sheetOverlap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(_sheetOverlap),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Align(
                alignment: const Alignment(0, -0.1),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
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
