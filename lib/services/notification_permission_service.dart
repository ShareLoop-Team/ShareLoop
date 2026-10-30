import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The OS notification permission, as the app needs to act on it.
enum NotificationPermission {
  granted,

  /// Not granted, but the app may ask again.
  denied,

  /// Only the system settings can change it now (e.g. denied twice on
  /// Android, or denied once on iOS).
  permanentlyDenied,

  /// This platform has no permission to ask for (web, desktop).
  unsupported,
}

/// Service: asks for the OS permission to show notifications and remembers,
/// on this device, that the sign-in prompt was answered so it isn't shown
/// again on every launch.
///
/// Granting the permission only allows notifications; nothing sends any
/// until push delivery (e.g. Firebase Cloud Messaging) is implemented.
class NotificationPermissionService {
  static const String _answeredKey = 'notification_prompt_answered';

  /// Android, iOS and browsers have a notification permission to ask for.
  /// Windows desktop apps don't (permission_handler always reports them as
  /// granted), so there is nothing to prompt for there.
  bool get isSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  /// In a browser, "blocked" is changed from the site settings next to the
  /// address bar rather than an app settings page.
  bool get isBrowser => kIsWeb;

  Future<NotificationPermission> status() async {
    if (!isSupported) return NotificationPermission.unsupported;
    return _fromStatus(await Permission.notification.status);
  }

  /// Whether to show the prompt after sign-in: never answered here before,
  /// and the OS would still show its permission dialog. In debug builds the
  /// log says why it was skipped.
  Future<bool> shouldPrompt() async {
    if (!isSupported) {
      debugPrint('Notification prompt skipped: no notification permission '
          'on $defaultTargetPlatform.');
      return false;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_answeredKey) ?? false) {
        debugPrint('Notification prompt skipped: already answered on this '
            'device (run with --dart-define=RESET_NOTIFICATION_PROMPT=true '
            'to reset it in a debug build).');
        return false;
      }
      final current = await status();
      if (current != NotificationPermission.denied) {
        debugPrint('Notification prompt skipped: permission is $current.');
        return false;
      }
      return true;
    } on PlatformException catch (error) {
      // A broken plugin must never get in the way of reaching Home.
      debugPrint('Notification prompt skipped: $error');
      return false;
    } on MissingPluginException catch (error) {
      debugPrint('Notification prompt skipped: $error');
      return false;
    }
  }

  /// Shows the OS permission dialog and returns what the OS reports.
  Future<NotificationPermission> request() async {
    await _markAnswered();
    if (!isSupported) return NotificationPermission.unsupported;
    final result = _fromStatus(await Permission.notification.request());
    if (kIsWeb && result != NotificationPermission.granted) {
      // The web plugin reports any refusal as permanent, even just closing
      // the browser's bar, which still lets the site ask again. Re-check.
      return status();
    }
    return result;
  }

  /// "Maybe Later": don't prompt again after sign-in on this device.
  Future<void> dismiss() => _markAnswered();

  /// Forgets that the prompt was answered, so the next sign-in shows it
  /// again. For development only (see main.dart); the OS permission itself
  /// is untouched.
  Future<void> resetPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_answeredKey);
  }

  /// Opens this app's page in the system settings.
  Future<bool> openSettings() => openAppSettings();

  Future<void> _markAnswered() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_answeredKey, true);
  }

  static NotificationPermission _fromStatus(PermissionStatus status) {
    return switch (status) {
      PermissionStatus.granted ||
      PermissionStatus.limited ||
      PermissionStatus.provisional =>
        NotificationPermission.granted,
      PermissionStatus.permanentlyDenied ||
      PermissionStatus.restricted =>
        NotificationPermission.permanentlyDenied,
      PermissionStatus.denied => NotificationPermission.denied,
    };
  }
}
