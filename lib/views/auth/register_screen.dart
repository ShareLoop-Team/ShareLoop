import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/register_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/auth_form_widgets.dart';

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
  static const double _fieldGap = 14;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _controller = RegisterController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
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
      city: _cityController.text,
    );
  }

  String? Function(String?) _required(String message) =>
      (value) => (value == null || value.trim().isEmpty) ? message : null;

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
                padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
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
                              header: true,
                              child: Text(
                                l10n.registerTitle,
                                textAlign: TextAlign.center,
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.registerSubtitle,
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 40),
                            TextFormField(
                              controller: _nameController,
                              decoration: authInputDecoration(
                                l10n.registerNameHint,
                              ),
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              validator: _required(l10n.registerNameRequired),
                            ),
                            const SizedBox(height: _fieldGap),
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
                              validator: _required(l10n.registerPhoneRequired),
                            ),
                            const SizedBox(height: _fieldGap),
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
                            TextFormField(
                              controller: _cityController,
                              decoration: authInputDecoration(
                                l10n.registerCityHint,
                              ),
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.addressCity],
                              validator: _required(l10n.registerCityRequired),
                            ),
                            const SizedBox(height: _fieldGap),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _controller.obscurePassword,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newPassword],
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
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _controller.obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(auth),
                              decoration: authInputDecoration(
                                l10n.registerConfirmPasswordHint,
                              ),
                              validator: (value) =>
                                  value != _passwordController.text
                                  ? l10n.registerPasswordMismatch
                                  : null,
                            ),
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
                            const SizedBox(height: 40),
                            AuthPrimaryButton(
                              label: l10n.registerButton,
                              isLoading: auth.isLoading,
                              onPressed: () => _submit(auth),
                            ),
                            const SizedBox(height: 12),
                            AuthSwitchPrompt(
                              question: l10n.registerHaveAccount,
                              actionLabel: l10n.registerSignIn,
                              onPressed: () => _controller.openLogin(
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
