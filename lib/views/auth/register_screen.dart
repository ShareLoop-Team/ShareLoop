import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/register_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/theme/sl_tokens.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/auth_form_widgets.dart';
import '../../widgets/city_dropdown_field.dart';
import '../../widgets/post_form_widgets.dart';
import '../../widgets/sl/sl_button.dart';
import '../../widgets/sl/sl_input.dart';

/// View: single-account registration form (a user may act as both donor
/// and requester, so there is no role selector). Field checks happen in the
/// form; creating the account and navigation go through
/// [RegisterController].
///
/// Follows the app's light or dark theme. Only email and password sign-up
/// works: Google and Facebook aren't set up in Firebase Authentication, so
/// their buttons say they aren't available yet.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) => const _RegisterView();
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  /// Between fields of one group, and between groups.
  static const double _fieldGap = SLSpace.l;
  static const double _groupGap = SLSpace.xl;

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

  /// Google and Facebook aren't set up in Firebase yet: say so plainly
  /// rather than starting a sign-up that can't finish.
  void _socialUnavailable(AppLocalizations l10n) => showAppSnackBar(
    ScaffoldMessenger.of(context),
    l10n.loginSocialUnavailable,
  );

  String? Function(String?) _required(String message) =>
      (value) => (value == null || value.trim().isEmpty) ? message : null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sl = context.sl;
    final type = context.slType;
    final auth = context.watch<AuthController>();
    final navigator = Navigator.of(context);
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
                                AuthHeroImage(
                                  asset: 'assets/images/register_hero.jpg',
                                  background: AppColors.registerHeroBackground,
                                  // Smaller than login's: the form is longer.
                                  maxHeight: 220,
                                  minHeight: 130,
                                  screenFraction: 0.24,
                                  leading: navigator.canPop()
                                      ? AuthBackButton(
                                          onPressed: navigator.maybePop,
                                        )
                                      : null,
                                ),
                                const SizedBox(height: SLSpace.section),
                                Semantics(
                                  header: true,
                                  child: Text(
                                    l10n.registerTitle,
                                    style: type.title,
                                  ),
                                ),
                                const SizedBox(height: SLSpace.xs),
                                Text(
                                  l10n.registerSubtitle,
                                  style: type.body.copyWith(
                                    color: sl.inkMuted,
                                  ),
                                ),
                                const SizedBox(height: SLSpace.xl),
                                SLFieldLabel(l10n.registerNameLabel),
                                TextFormField(
                                  controller: _nameController,
                                  style: type.body,
                                  decoration: slInputDecoration(
                                    context,
                                    hint: l10n.registerNameHint,
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.name],
                                  validator: _required(
                                    l10n.registerNameRequired,
                                  ),
                                ),
                                const SizedBox(height: _fieldGap),
                                SLFieldLabel(l10n.loginEmailLabel),
                                TextFormField(
                                  controller: _emailController,
                                  style: type.body,
                                  decoration: slInputDecoration(
                                    context,
                                    hint: l10n.loginEmailHint,
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  validator: _required(
                                    l10n.loginEmailRequired,
                                  ),
                                ),
                                const SizedBox(height: _fieldGap),
                                SLFieldLabel(l10n.registerPhoneLabel),
                                TextFormField(
                                  controller: _phoneController,
                                  style: type.body,
                                  decoration: slInputDecoration(
                                    context,
                                    hint: l10n.registerPhoneHint,
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
                                const SizedBox(height: _groupGap),
                                SLFieldLabel(l10n.loginPasswordLabel),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _controller.obscurePassword,
                                  style: type.body,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  decoration: slInputDecoration(
                                    context,
                                    hint: l10n.registerPasswordHint,
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
                                SLFieldLabel(
                                  l10n.registerConfirmPasswordLabel,
                                ),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _controller.obscurePassword,
                                  style: type.body,
                                  textInputAction: TextInputAction.next,
                                  decoration: slInputDecoration(
                                    context,
                                    hint: l10n.registerConfirmPasswordHint,
                                    suffixIcon: _visibilityButton(l10n),
                                  ),
                                  validator: (value) =>
                                      value != _passwordController.text
                                      ? l10n.registerPasswordMismatch
                                      : null,
                                ),
                                const SizedBox(height: _groupGap),
                                SLFieldLabel(l10n.registerDistrictLabel),
                                PostDropdownField(
                                  value: _controller.district,
                                  hint: l10n.registerDistrictHint,
                                  options: AppConstants.sriLankanDistricts,
                                  menuMaxHeight: 320,
                                  onChanged: _controller.selectDistrict,
                                  validator: (value) => value == null
                                      ? l10n.registerDistrictRequired
                                      : null,
                                ),
                                const SizedBox(height: _fieldGap),
                                SLFieldLabel(l10n.registerCityLabel),
                                CityDropdownField(
                                  district: _controller.district,
                                  value: _controller.city,
                                  decoration: slInputDecoration(context),
                                  textStyle: type.body,
                                  onChanged: _controller.selectCity,
                                ),
                                const SizedBox(height: _groupGap),
                                _TermsAgreement(
                                  value: _controller.agreedToTerms,
                                  onChanged: _controller.setAgreedToTerms,
                                ),
                                if (auth.errorMessage != null) ...[
                                  const SizedBox(height: SLSpace.m),
                                  AuthErrorText(auth.errorMessage!),
                                ],
                                const SizedBox(height: SLSpace.l),
                                SLButton(
                                  label: l10n.registerButton,
                                  expand: true,
                                  isLoading: auth.isLoading,
                                  onPressed: () => _submit(auth),
                                ),
                                const SizedBox(height: SLSpace.xl),
                                AuthSocialButtons(
                                  dividerLabel: l10n.registerOrSignUpWith,
                                  googleLabel: l10n.registerWithGoogle,
                                  facebookLabel: l10n.registerWithFacebook,
                                  onPressed: () => _socialUnavailable(l10n),
                                ),
                                const Spacer(),
                                const SizedBox(height: SLSpace.xl),
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
  List<InlineSpan> _sentence(AppLocalizations l10n, Color linkColor) {
    final link = TextStyle(color: linkColor, fontWeight: FontWeight.w600);
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
    final sl = context.sl;
    final type = context.slType;
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
              borderRadius: BorderRadius.circular(SLSpace.s),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: SLSpace.s),
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
                        activeColor: sl.action,
                        checkColor: sl.onAction,
                        side: BorderSide(
                          color: field.hasError ? sl.danger : sl.inkMuted,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: SLSpace.m),
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: _sentence(l10n, sl.accentText)),
                        style: type.body,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (field.hasError)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 34),
              child: Text(
                field.errorText!,
                style: type.small.copyWith(color: sl.danger),
              ),
            ),
        ],
      ),
    );
  }
}
