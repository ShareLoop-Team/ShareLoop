import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/sri_lanka_locations.dart';
import '../../core/localization/generated/app_localizations.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/email_code.dart';
import '../../widgets/auth_form_widgets.dart';
import '../../widgets/city_dropdown_field.dart';

/// View: the few details Google doesn't give us (phone, district, city),
/// asked once when someone signs up with Google.
class CompleteGoogleProfileScreen extends StatelessWidget {
  const CompleteGoogleProfileScreen({super.key, required this.pending});

  final GoogleSignUpNeeded pending;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: _CompleteProfileView(pending: pending),
    );
  }
}

class _CompleteProfileView extends StatefulWidget {
  const _CompleteProfileView({required this.pending});

  final GoogleSignUpNeeded pending;

  @override
  State<_CompleteProfileView> createState() => _CompleteProfileViewState();
}

class _CompleteProfileViewState extends State<_CompleteProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController =
      TextEditingController(text: widget.pending.name);
  final _phoneController = TextEditingController();
  String? _district;

  /// Always one of [_district]'s cities, or null.
  String? _city;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthController>().clearError();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthController auth) async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final done = await auth.completeGoogleSignUp(
      widget.pending,
      name: _nameController.text,
      phone: _phoneController.text,
      district: _district!,
      city: _city ?? '',
    );
    if (done) {
      navigator.pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
    }
  }

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
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AuthAccentTitle(text: l10n.googleCompleteTitle),
                          const SizedBox(height: 8),
                          Text(
                            widget.pending.provider == SocialProvider.facebook
                                ? l10n.facebookCompleteSubtitle(
                                    widget.pending.email)
                                : l10n.googleCompleteSubtitle(
                                    widget.pending.email),
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
                            decoration:
                                authInputDecoration(l10n.registerNameHint),
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            validator: _required(l10n.registerNameRequired),
                          ),
                          const SizedBox(height: 16),
                          AuthFieldLabel(l10n.registerPhoneLabel),
                          TextFormField(
                            controller: _phoneController,
                            decoration:
                                authInputDecoration(l10n.registerPhoneHint),
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
                            validator: _required(l10n.registerPhoneRequired),
                          ),
                          const SizedBox(height: 16),
                          AuthFieldLabel(l10n.registerDistrictLabel),
                          DropdownButtonFormField<String>(
                            initialValue: _district,
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
                            items: [
                              for (final d in AppConstants.sriLankanDistricts)
                                DropdownMenuItem(value: d, child: Text(d)),
                            ],
                            onChanged: (value) =>
                                setState(() {
                                  _district = value;
                                  _city = SriLankaLocations.validCity(
                                    value,
                                    _city,
                                  );
                                }),
                            validator: (value) => value == null
                                ? l10n.registerDistrictRequired
                                : null,
                          ),
                          const SizedBox(height: 16),
                          AuthFieldLabel(l10n.registerCityLabel),
                          CityDropdownField(
                            district: _district,
                            value: _city,
                            decoration: authInputDecoration(''),
                            onChanged: (value) => setState(
                              () => _city = SriLankaLocations.validCity(
                                _district,
                                value,
                              ),
                            ),
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
                          const SizedBox(height: 20),
                          AuthSubmitButton(
                            label: l10n.googleCompleteButton,
                            isLoading: auth.isLoading,
                            onPressed: () => _submit(auth),
                          ),
                        ],
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
