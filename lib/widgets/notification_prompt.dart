import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/localization/generated/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../services/notification_permission_service.dart';
import 'app_icon.dart';
import 'app_snack_bar.dart';
import 'pill_button.dart';

/// Shows the "Allow ShareLoop to send you notifications?" card. Allow asks
/// the OS and reports what it answered; Maybe Later (or tapping outside)
/// just closes it. Either way it won't be shown after sign-in again.
Future<void> showNotificationPrompt(
  BuildContext context,
  NotificationPermissionService service,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final allow = await showDialog<bool>(
    context: context,
    builder: (_) => const NotificationPromptDialog(),
  );
  if (allow != true) {
    await service.dismiss();
    return;
  }
  final result = await service.request();
  _reportResult(messenger, l10n, service, result);
}

/// Profile → Notifications: says how things stand, asks again when the OS
/// still allows it, or points to the system settings when it doesn't.
Future<void> manageNotifications(BuildContext context) async {
  final service = context.read<NotificationPermissionService?>();
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  if (service == null || !service.isSupported) {
    showAppSnackBar(messenger, l10n.profileNotificationsUnavailable);
    return;
  }
  final status = await service.status();
  if (status == NotificationPermission.denied && context.mounted) {
    await showNotificationPrompt(context, service);
    return;
  }
  _reportResult(messenger, l10n, service, status);
}

void _reportResult(
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
  NotificationPermissionService service,
  NotificationPermission result,
) {
  switch (result) {
    case NotificationPermission.granted:
      showAppSnackBar(messenger, l10n.notifEnabled);
    case NotificationPermission.denied:
      showAppSnackBar(messenger, l10n.notifDenied);
    case NotificationPermission.permanentlyDenied:
      // A browser has no app settings page to open.
      showAppSnackBar(
        messenger,
        service.isBrowser ? l10n.notifBlockedBrowser : l10n.notifBlocked,
        action: service.isBrowser
            ? null
            : SnackBarAction(
                label: l10n.notifOpenSettings,
                onPressed: service.openSettings,
              ),
      );
    case NotificationPermission.unsupported:
      showAppSnackBar(messenger, l10n.profileNotificationsUnavailable);
  }
}

/// The prompt card. Pops true for Allow Notifications, false for Maybe
/// Later.
class NotificationPromptDialog extends StatelessWidget {
  const NotificationPromptDialog({super.key});

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
                    const Center(child: _BellBadge()),
                    const SizedBox(height: 20),
                    Text(
                      l10n.notifPromptTitle,
                      textAlign: TextAlign.center,
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.notifPromptBody,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    PillButton(
                      label: l10n.notifPromptAllow,
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
                      child: Text(l10n.notifPromptLater),
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

/// Bell in a mint circle, with a brand-green dot like an unread badge.
class _BellBadge extends StatelessWidget {
  const _BellBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 76,
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: AppColors.paleMint,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const IconTheme(
              data: IconThemeData(size: 34, color: AppColors.deepGreen),
              child: AppIcon(AppGlyph.notifications),
            ),
          ),
          Positioned(
            top: 14,
            right: 16,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.brightGreen,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.paleMint, width: 2.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
