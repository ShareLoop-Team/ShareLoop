import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/login_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../models/email_code.dart';
import '../../widgets/auth_form_widgets.dart';
import '../../widgets/facebook/facebook_sign_in_button.dart';
import '../../widgets/google/google_sign_in_button.dart';

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

  /// Emails a sign-in or reset code to the address typed in the email
  /// field and opens the code screen.
  void _requestCode(
    AppLocalizations l10n,
    AuthController auth,
    EmailCodePurpose purpose,
  ) {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(purpose == EmailCodePurpose.reset
              ? l10n.loginResetEnterEmail
              : l10n.loginCodeEnterEmail),
        ));
      return;
    }
    _controller.requestCode(
      auth: auth,
      navigator: Navigator.of(context),
      email: email,
      purpose: purpose,
    );
  }

  /// Social sign-in isn't wired to a provider yet.
  void _socialSignIn(AppLocalizations l10n) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.loginSocialUnavailable)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final auth = context.watch<AuthController>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AuthHeader(
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Semantics(
                    label: l10n.appTitle,
                    child: const Icon(
                      Icons.eco_outlined,
                      color: AppColors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
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
                              AuthAccentTitle(text: l10n.loginWelcomeBack),
                              const SizedBox(height: 6),
                              Text(
                                l10n.loginSubtitle,
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              AuthFieldLabel(l10n.loginEmailLabel),
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
                              const SizedBox(height: 16),
                              AuthFieldLabel(l10n.loginPasswordLabel),
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
                                      alignment:
                                          AlignmentDirectional.centerEnd,
                                      child: TextButton(
                                        onPressed: () => _requestCode(
                                          l10n,
                                          auth,
                                          EmailCodePurpose.reset,
                                        ),
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
                              const SizedBox(height: 20),
                              AuthSubmitButton(
                                label: l10n.loginSignIn,
                                isLoading: auth.isLoading,
                                onPressed: () => _submit(auth),
                              ),
                              const SizedBox(height: 4),
                              TextButton(
                                onPressed: auth.isLoading
                                    ? null
                                    : () => _requestCode(
                                          l10n,
                                          auth,
                                          EmailCodePurpose.login,
                                        ),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.deepGreen,
                                ),
                                child: Text(l10n.loginWithEmailCode),
                              ),
                              const SizedBox(height: 8),
                              AuthOrDivider(label: l10n.loginOrContinueWith),
                              const SizedBox(height: 16),
                              GoogleSignInButton(
                                label: l10n.loginWithGoogle,
                                onUnavailable: () => _socialSignIn(l10n),
                              ),
                              const SizedBox(height: 14),
                              FacebookSignInButton(
                                label: l10n.loginWithFacebook,
                                onUnavailable: () => _socialSignIn(l10n),
                              ),
                              const Spacer(),
                              const SizedBox(height: 24),
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
