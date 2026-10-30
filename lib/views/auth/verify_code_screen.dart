import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/register_controller.dart';
import '../../controllers/verify_code_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/email_code.dart';
import '../../widgets/auth_form_widgets.dart';

/// View: enter the 6-digit code we emailed, to finish registering, sign in
/// without a password, or set a new password.
class VerifyCodeScreen extends StatelessWidget {
  const VerifyCodeScreen({super.key, required this.args});

  final VerifyCodeArgs args;

  @override
  Widget build(BuildContext context) {
    return Theme(data: AppTheme.lightTheme, child: _VerifyCodeView(args: args));
  }
}

class _VerifyCodeView extends StatefulWidget {
  const _VerifyCodeView({required this.args});

  final VerifyCodeArgs args;

  @override
  State<_VerifyCodeView> createState() => _VerifyCodeViewState();
}

class _VerifyCodeViewState extends State<_VerifyCodeView> {
  static const int codeLength = 6;

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  late final VerifyCodeController _controller =
      VerifyCodeController(widget.args.ticket);

  EmailCodePurpose get _purpose => widget.args.ticket.purpose;

  @override
  void initState() {
    super.initState();
    // The previous screen's error doesn't belong here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthController>().clearError();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _title(AppLocalizations l10n) => switch (_purpose) {
        EmailCodePurpose.register => l10n.verifyTitleRegister,
        EmailCodePurpose.login => l10n.verifyTitleLogin,
        EmailCodePurpose.reset => l10n.verifyTitleReset,
      };

  String _buttonLabel(AppLocalizations l10n) => switch (_purpose) {
        EmailCodePurpose.register => l10n.registerButton,
        EmailCodePurpose.login => l10n.loginSignIn,
        EmailCodePurpose.reset => l10n.verifyChangePassword,
      };

  Future<void> _submit(AuthController auth, AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final email = _controller.ticket.email;
    final code = _codeController.text.trim();

    switch (_purpose) {
      case EmailCodePurpose.register:
        if (await auth.register(widget.args.registration!, code)) {
          navigator.pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
        }
      case EmailCodePurpose.login:
        if (await auth.loginWithCode(email, code)) {
          navigator.pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
        }
      case EmailCodePurpose.reset:
        final done = await auth.resetPassword(
          email: email,
          code: code,
          newPassword: _passwordController.text,
        );
        if (done) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.verifyPasswordChanged)),
          );
          navigator.pop();
        }
    }
  }

  Future<void> _resend(AuthController auth, AppLocalizations l10n) async {
    final messenger = ScaffoldMessenger.of(context);
    final sent = await _controller.resend(
      auth,
      registration: widget.args.registration,
    );
    if (sent) {
      _codeController.clear();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.verifyResent)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final auth = context.watch<AuthController>();
    final navigator = Navigator.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AuthHeader(
                leading: navigator.canPop()
                    ? AuthBackButton(onPressed: navigator.maybePop)
                    : null,
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                    child: ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) => Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AuthAccentTitle(text: _title(l10n)),
                            const SizedBox(height: 8),
                            Text(
                              l10n.verifySentTo(_controller.ticket.email),
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.verifyCheckSpam,
                              textAlign: TextAlign.center,
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (_controller.ticket.debugCode case final code?)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.brightGreen
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    l10n.verifyDebugCode(code),
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodySmall,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            AuthFieldLabel(l10n.verifyCodeLabel),
                            TextFormField(
                              key: const Key('verify-code-field'),
                              controller: _codeController,
                              autofocus: true,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: codeLength,
                              autofillHints: const [AutofillHints.oneTimeCode],
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: textTheme.headlineSmall?.copyWith(
                                letterSpacing: 8,
                                fontWeight: FontWeight.w700,
                              ),
                              textInputAction: _purpose == EmailCodePurpose.reset
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                              onFieldSubmitted: (_) {
                                if (_purpose != EmailCodePurpose.reset) {
                                  _submit(auth, l10n);
                                }
                              },
                              decoration: authInputDecoration(
                                l10n.verifyCodeHint,
                              ).copyWith(counterText: ''),
                              validator: (value) =>
                                  (value == null ||
                                          value.trim().length != codeLength)
                                      ? l10n.verifyCodeRequired
                                      : null,
                            ),
                            if (_purpose == EmailCodePurpose.reset) ...[
                              const SizedBox(height: 16),
                              AuthFieldLabel(l10n.verifyNewPasswordLabel),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _controller.obscurePassword,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                textInputAction: TextInputAction.next,
                                decoration: authInputDecoration(
                                  l10n.registerPasswordHint,
                                  suffixIcon: PasswordVisibilityButton(
                                    obscured: _controller.obscurePassword,
                                    onPressed:
                                        _controller.togglePasswordVisibility,
                                    showTooltip: l10n.loginShowPassword,
                                    hideTooltip: l10n.loginHidePassword,
                                  ),
                                ),
                                validator: (value) => (value == null ||
                                        value.length <
                                            RegisterController
                                                .minPasswordLength)
                                    ? l10n.registerPasswordTooShort(
                                        RegisterController.minPasswordLength,
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              AuthFieldLabel(
                                l10n.registerConfirmPasswordLabel,
                              ),
                              TextFormField(
                                controller: _confirmController,
                                obscureText: _controller.obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(auth, l10n),
                                decoration: authInputDecoration(
                                  l10n.registerConfirmPasswordHint,
                                ),
                                validator: (value) =>
                                    value != _passwordController.text
                                        ? l10n.registerPasswordMismatch
                                        : null,
                              ),
                            ],
                            if (auth.errorMessage != null) ...[
                              const SizedBox(height: 12),
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
                              label: _buttonLabel(l10n),
                              isLoading: auth.isLoading,
                              onPressed: () => _submit(auth, l10n),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed:
                                  _controller.canResend && !auth.isLoading
                                      ? () => _resend(auth, l10n)
                                      : null,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.deepGreen,
                              ),
                              child: Text(
                                _controller.canResend
                                    ? l10n.verifyResend
                                    : l10n.verifyResendIn(
                                        _controller.secondsUntilResend,
                                      ),
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
          ],
        ),
      ),
    );
  }
}
