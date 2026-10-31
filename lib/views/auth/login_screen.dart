import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/login_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../models/email_code.dart';
import '../../core/theme/sl_tokens.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/auth_form_widgets.dart';
import '../../widgets/facebook/facebook_sign_in_button.dart';
import '../../widgets/google/google_sign_in_button.dart';
import '../../widgets/sl/sl_button.dart';
import '../../widgets/sl/sl_input.dart';

/// View: login form. Validation of empty fields happens in the form; the
/// login action and navigation are delegated to [LoginController].
///
/// Follows the app's light or dark theme and supports password, email-code,
/// Google, and Facebook sign-in.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) => const _LoginView();
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

  /// Emails a sign-in or reset code to the address typed in the email field.
  void _requestCode(
    AppLocalizations l10n,
    AuthController auth,
    EmailCodePurpose purpose,
  ) {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              purpose == EmailCodePurpose.reset
                  ? l10n.loginResetEnterEmail
                  : l10n.loginCodeEnterEmail,
            ),
          ),
        );
      return;
    }
    _controller.requestCode(
      auth: auth,
      navigator: Navigator.of(context),
      email: email,
      purpose: purpose,
    );
  }

  /// Shown when a social provider isn't configured.
  void _socialUnavailable(AppLocalizations l10n) => showAppSnackBar(
    ScaffoldMessenger.of(context),
    l10n.loginSocialUnavailable,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sl = context.sl;
    final type = context.slType;
    final auth = context.watch<AuthController>();
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Status bar icons that contrast with the page.
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: sl.ground,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        SLSpace.screen,
                        SLSpace.m,
                        SLSpace.screen,
                        SLSpace.l,
                      ),
                      child: ListenableBuilder(
                        listenable: _controller,
                        builder: (context, _) => Form(
                          key: _formKey,
                          child: AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const AuthHeroImage(
                                  asset: 'assets/images/login_hero.jpg',
                                  background: AppColors.introBackground,
                                ),
                                const SizedBox(height: SLSpace.section),
                                Semantics(
                                  header: true,
                                  child: Text(
                                    l10n.loginWelcomeBack,
                                    style: type.title,
                                  ),
                                ),
                                const SizedBox(height: SLSpace.xl),
                                SLFieldLabel(l10n.loginEmailLabel),
                                TextFormField(
                                  controller: _emailController,
                                  style: type.body,
                                  decoration: slInputDecoration(
                                    context,
                                    hint: l10n.loginEmailHint,
                                    prefixIcon: Icons.mail_outline,
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  validator: (value) =>
                                      (value == null || value.trim().isEmpty)
                                      ? l10n.loginEmailRequired
                                      : null,
                                ),
                                const SizedBox(height: SLSpace.l),
                                SLFieldLabel(l10n.loginPasswordLabel),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _controller.obscurePassword,
                                  style: type.body,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                  onFieldSubmitted: (_) => _submit(auth),
                                  decoration: slInputDecoration(
                                    context,
                                    hint: l10n.loginPasswordHint,
                                    prefixIcon: Icons.lock_outline,
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
                                Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: TextButton(
                                    onPressed: () => _requestCode(
                                      l10n,
                                      auth,
                                      EmailCodePurpose.reset,
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: sl.accentText,
                                      minimumSize: const Size(0, 44),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: SLSpace.xs,
                                      ),
                                      textStyle: type.small.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    child: Text(
                                      l10n.loginForgotPassword,
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ),
                                if (auth.errorMessage != null) ...[
                                  const SizedBox(height: SLSpace.s),
                                  AuthErrorText(auth.errorMessage!),
                                ],
                                const SizedBox(height: SLSpace.l),
                                SLButton(
                                  label: l10n.loginSignIn,
                                  expand: true,
                                  isLoading: auth.isLoading,
                                  onPressed: () => _submit(auth),
                                ),
                                const SizedBox(height: SLSpace.s),
                                TextButton(
                                  onPressed: auth.isLoading
                                      ? null
                                      : () => _requestCode(
                                          l10n,
                                          auth,
                                          EmailCodePurpose.login,
                                        ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: sl.accentText,
                                  ),
                                  child: Text(l10n.loginWithEmailCode),
                                ),
                                const SizedBox(height: SLSpace.xl),
                                AuthOrDivider(label: l10n.loginOrContinueWith),
                                const SizedBox(height: SLSpace.l),
                                GoogleSignInButton(
                                  label: l10n.loginWithGoogle,
                                  visualLabel: 'Google',
                                  onUnavailable: () => _socialUnavailable(l10n),
                                ),
                                const SizedBox(height: SLSpace.s),
                                FacebookSignInButton(
                                  label: l10n.loginWithFacebook,
                                  visualLabel: 'Facebook',
                                  onUnavailable: () => _socialUnavailable(l10n),
                                ),
                                const Spacer(),
                                const SizedBox(height: SLSpace.xl),
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
      ),
    );
  }
}
