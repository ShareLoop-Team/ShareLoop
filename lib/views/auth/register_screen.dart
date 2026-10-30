import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/register_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/auth_form_widgets.dart';
import '../../widgets/city_dropdown_field.dart';
import '../../widgets/facebook/facebook_sign_in_button.dart';
import '../../widgets/google/google_sign_in_button.dart';

/// View: single-account registration form (a user may act as both donor
/// and requester, so there is no role selector). Field checks happen in the
/// form; creating the account and navigation go through
/// [RegisterController].
///
/// Always uses the light brand theme, like the login and onboarding screens.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(data: AppTheme.lightTheme, child: const _RegisterView());
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  static const double _fieldGap = 16;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _controller = RegisterController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _submit(AuthController auth) {
    if (!_formKey.currentState!.validate()) return;
    _controller.submit(
      auth: auth,
      navigator: Navigator.of(context),
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      phone: _phoneController.text,
    );
  }

  /// Social sign-up isn't wired to a provider yet.
  void _socialSignUp(AppLocalizations l10n) => showAppSnackBar(
        ScaffoldMessenger.of(context),
        l10n.loginSocialUnavailable,
      );

  String? Function(String?) _required(String message) =>
      (value) => (value == null || value.trim().isEmpty) ? message : null;

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
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
                    child: ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) => Form(
                        key: _formKey,
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AuthAccentTitle(text: l10n.registerTitle),
                              const SizedBox(height: 6),
                              Text(
                                l10n.registerSubtitle,
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              AuthFieldLabel(l10n.registerNameLabel),
                              TextFormField(
                                controller: _nameController,
                                decoration: authInputDecoration(
                                  l10n.registerNameHint,
                                ),
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.name],
                                validator: _required(
                                  l10n.registerNameRequired,
                                ),
                              ),
                              const SizedBox(height: _fieldGap),
                              AuthFieldLabel(l10n.loginEmailLabel),
                              TextFormField(
                                controller: _emailController,
                                decoration: authInputDecoration(
                                  l10n.loginEmailHint,
                                ),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                validator: _required(l10n.loginEmailRequired),
                              ),
                              const SizedBox(height: _fieldGap),
                              AuthFieldLabel(l10n.loginPasswordLabel),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _controller.obscurePassword,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                decoration: authInputDecoration(
                                  l10n.registerPasswordHint,
                                  suffixIcon: _visibilityButton(l10n),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return l10n.loginPasswordRequired;
                                  }
                                  if (value.length <
                                      RegisterController.minPasswordLength) {
                                    return l10n.registerPasswordTooShort(
                                      RegisterController.minPasswordLength,
                                    );
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: _fieldGap),
                              AuthFieldLabel(l10n.registerConfirmPasswordLabel),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _controller.obscurePassword,
                                textInputAction: TextInputAction.next,
                                decoration: authInputDecoration(
                                  l10n.registerConfirmPasswordHint,
                                  suffixIcon: _visibilityButton(l10n),
                                ),
                                validator: (value) =>
                                    value != _passwordController.text
                                    ? l10n.registerPasswordMismatch
                                    : null,
                              ),
                              const SizedBox(height: _fieldGap),
                              AuthFieldLabel(l10n.registerPhoneLabel),
                              TextFormField(
                                controller: _phoneController,
                                decoration: authInputDecoration(
                                  l10n.registerPhoneHint,
                                ),
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.telephoneNumber,
                                ],
                                validator: _required(
                                  l10n.registerPhoneRequired,
                                ),
                              ),
                              const SizedBox(height: _fieldGap),
                              AuthFieldLabel(l10n.registerDistrictLabel),
                              DropdownButtonFormField<String>(
                                initialValue: _controller.district,
                                decoration: authInputDecoration(
                                  l10n.registerDistrictHint,
                                ),
                                isExpanded: true,
                                borderRadius: BorderRadius.circular(16),
                                dropdownColor: AppColors.white,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: AppColors.textSecondary,
                                ),
                                items: AppConstants.sriLankanDistricts
                                    .map(
                                      (d) => DropdownMenuItem(
                                        value: d,
                                        child: Text(d),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _controller.selectDistrict,
                                validator: (value) => value == null
                                    ? l10n.registerDistrictRequired
                                    : null,
                              ),
                              const SizedBox(height: _fieldGap),
                              AuthFieldLabel(l10n.registerCityLabel),
                              CityDropdownField(
                                district: _controller.district,
                                value: _controller.city,
                                decoration: authInputDecoration(''),
                                onChanged: _controller.selectCity,
                              ),
                              const SizedBox(height: 20),
                              _TermsAgreement(
                                value: _controller.agreedToTerms,
                                onChanged: _controller.setAgreedToTerms,
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
                              AuthSubmitButton(
                                label: l10n.registerButton,
                                isLoading: auth.isLoading,
                                onPressed: () => _submit(auth),
                              ),
                              const SizedBox(height: 16),
                              AuthOrDivider(label: l10n.registerOrSignUpWith),
                              const SizedBox(height: 16),
                              GoogleSignInButton(
                                label: l10n.registerWithGoogle,
                                onUnavailable: () => _socialSignUp(l10n),
                              ),
                              const SizedBox(height: 14),
                              FacebookSignInButton(
                                label: l10n.registerWithFacebook,
                                onUnavailable: () => _socialSignUp(l10n),
                              ),
                              const Spacer(),
                              const SizedBox(height: 24),
                              AuthSwitchPrompt(
                                question: l10n.registerHaveAccount,
                                actionLabel: l10n.registerSignIn,
                                onPressed: () =>
                                    _controller.openLogin(navigator),
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

  Widget _visibilityButton(AppLocalizations l10n) => PasswordVisibilityButton(
    obscured: _controller.obscurePassword,
    onPressed: _controller.togglePasswordVisibility,
    showTooltip: l10n.loginShowPassword,
    hideTooltip: l10n.loginHidePassword,
  );
}

/// "I agree to the Terms and Privacy Policy" checkbox. Validated with the
/// rest of the form, so submitting without ticking it shows an error.
class _TermsAgreement extends StatelessWidget {
  const _TermsAgreement({required this.value, required this.onChanged});

  // Stand-ins for the two link words while splitting the sentence.
  static const String _termsMark = '\u0001';
  static const String _privacyMark = '\u0002';

  final bool value;
  final ValueChanged<bool> onChanged;

  /// Builds the sentence with "Terms" and "Privacy Policy" in bold green,
  /// wherever the translation puts them.
  List<InlineSpan> _sentence(AppLocalizations l10n) {
    const link = TextStyle(
      color: AppColors.deepGreen,
      fontWeight: FontWeight.w700,
    );
    final spans = <InlineSpan>[];
    final buffer = StringBuffer();
    void flush() {
      if (buffer.isEmpty) return;
      spans.add(TextSpan(text: buffer.toString()));
      buffer.clear();
    }

    for (final char in l10n
        .registerAgreeTerms(_termsMark, _privacyMark)
        .split('')) {
      if (char == _termsMark || char == _privacyMark) {
        flush();
        spans.add(
          TextSpan(
            text: char == _termsMark
                ? l10n.registerTerms
                : l10n.registerPrivacyPolicy,
            style: link,
          ),
        );
      } else {
        buffer.write(char);
      }
    }
    flush();
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return FormField<bool>(
      validator: (_) => value ? null : l10n.registerTermsRequired,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MergeSemantics(
            child: InkWell(
              onTap: () {
                onChanged(!value);
                field.didChange(!value);
              },
              borderRadius: BorderRadius.circular(6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox.square(
                    dimension: 22,
                    child: Checkbox(
                      value: value,
                      onChanged: (checked) {
                        onChanged(checked ?? false);
                        field.didChange(checked ?? false);
                      },
                      activeColor: AppColors.deepGreen,
                      side: BorderSide(
                        color: field.hasError
                            ? AppColors.error
                            : AppColors.textSecondary,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: _sentence(l10n)),
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.ink,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (field.hasError)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 32, top: 4),
              child: Text(
                field.errorText!,
                style: textTheme.bodySmall?.copyWith(color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }
}
