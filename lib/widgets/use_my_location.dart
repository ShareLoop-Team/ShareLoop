import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/localization/generated/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../services/location_service.dart';
import 'pill_button.dart';

/// "Use my location": explains why before the system prompt, asks for
/// foreground location only, then finds the user's district and city.
///
/// Returns the match (its city is null when only the district could be
/// named), or null after telling the user why in a snack bar — so the
/// caller simply leaves the manual district/city choice in place.
Future<PlaceMatch?> detectMyLocation(BuildContext context) async {
  final service = context.read<LocationService?>() ?? LocationService();
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  // showDialog pushes onto the root navigator.
  final navigator = Navigator.of(context, rootNavigator: true);

  if (!service.isSupported) {
    _show(messenger, l10n.locationErrorUnsupported);
    return null;
  }

  LocationAccess access;
  try {
    access = await service.checkAccess();
    if (access == LocationAccess.askable) {
      if (!context.mounted) return null;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (_) => const _LocationExplainDialog(),
      );
      if (proceed != true) return null;
      access = await service.requestAccess();
    }
  } catch (e) {
    debugPrint('Location permission request failed: $e');
    _show(messenger, l10n.locationErrorFailed);
    return null;
  }
  switch (access) {
    case LocationAccess.granted:
      break;
    case LocationAccess.askable:
      _show(messenger, l10n.locationErrorDenied);
      return null;
    case LocationAccess.blocked:
      _show(
        messenger,
        l10n.locationErrorBlocked,
        action: SnackBarAction(
          label: l10n.locationOpenSettings,
          onPressed: service.openAppSettings,
        ),
      );
      return null;
  }

  if (!context.mounted) return null;
  // Blocks the screen until the lookup ends; it times out by itself.
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _DetectingDialog(),
  );
  final LocationResult result;
  try {
    result = await service.detect();
  } finally {
    navigator.pop();
  }

  switch (result) {
    case LocationFound(:final match):
      return match;
    case LocationNotFound(:final failure):
      _show(
        messenger,
        _failureMessage(l10n, failure),
        action: switch (failure) {
          LocationFailure.serviceDisabled => SnackBarAction(
            label: l10n.locationOpenSettings,
            onPressed: service.openLocationSettings,
          ),
          LocationFailure.permissionBlocked => SnackBarAction(
            label: l10n.locationOpenSettings,
            onPressed: service.openAppSettings,
          ),
          _ => null,
        },
      );
      return null;
  }
}

String _failureMessage(AppLocalizations l10n, LocationFailure failure) =>
    switch (failure) {
      LocationFailure.unsupported => l10n.locationErrorUnsupported,
      LocationFailure.serviceDisabled => l10n.locationErrorServiceDisabled,
      LocationFailure.permissionDenied => l10n.locationErrorDenied,
      LocationFailure.permissionBlocked => l10n.locationErrorBlocked,
      LocationFailure.timeout => l10n.locationErrorTimeout,
      LocationFailure.inaccurate => l10n.locationErrorInaccurate,
      LocationFailure.outsideSriLanka => l10n.locationErrorOutside,
      LocationFailure.notMatched => l10n.locationErrorNotMatched,
      LocationFailure.positionFailed => l10n.locationErrorFailed,
      LocationFailure.geocodingFailed => l10n.locationErrorLookup,
    };

void _show(
  ScaffoldMessengerState messenger,
  String message, {
  SnackBarAction? action,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), action: action));
}

/// Why ShareLoop wants the location, shown before the system prompt. Pops
/// true for Continue.
class _LocationExplainDialog extends StatelessWidget {
  const _LocationExplainDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Theme(
      data: AppTheme.lightTheme,
      child: Builder(
        builder: (context) {
          final textTheme = Theme.of(context).textTheme;
          return Dialog(
            backgroundColor: AppColors.white,
            surfaceTintColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                          color: AppColors.paleMint,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.my_location_rounded,
                          size: 34,
                          color: AppColors.deepGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.locationExplainTitle,
                      textAlign: TextAlign.center,
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.locationExplainBody,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    PillButton(
                      label: l10n.locationExplainContinue,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.deepGreen,
                        minimumSize: const Size.fromHeight(48),
                        shape: const StadiumBorder(),
                        textStyle: textTheme.titleSmall,
                      ),
                      child: Text(l10n.locationNotNow),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DetectingDialog extends StatelessWidget {
  const _DetectingDialog();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Theme(
        data: AppTheme.lightTheme,
        child: Dialog(
          backgroundColor: AppColors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.deepGreen,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    AppLocalizations.of(context).locationDetecting,
                    style: const TextStyle(color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
