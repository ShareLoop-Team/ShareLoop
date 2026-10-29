import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:shareloop/controllers/auth_controller.dart';
import 'package:shareloop/controllers/badge_controller.dart';
import 'package:shareloop/controllers/item_controller.dart';
import 'package:shareloop/controllers/language_controller.dart';
import 'package:shareloop/controllers/profile_controller.dart';
import 'package:shareloop/controllers/request_controller.dart';
import 'package:shareloop/core/localization/generated/app_localizations.dart';
import 'package:shareloop/core/routes/app_routes.dart';
import 'package:shareloop/views/auth/login_screen.dart';
import 'package:shareloop/services/notification_permission_service.dart';
import 'package:shareloop/views/home/home_screen.dart';
import 'package:shareloop/widgets/app_icon.dart';
import 'package:shareloop/widgets/notification_prompt.dart';

/// Stands in for the OS permission and the device's saved answer.
class _FakePermissions implements NotificationPermissionService {
  _FakePermissions({
    this.prompt = true,
    this.answer = NotificationPermission.granted,
  });

  bool prompt;
  NotificationPermission current = NotificationPermission.denied;

  /// What the OS dialog returns when asked.
  NotificationPermission answer;

  int promptChecks = 0;
  int requests = 0;
  int dismissals = 0;
  int settingsOpened = 0;

  @override
  bool get isSupported => true;

  @override
  bool isBrowser = false;

  int resets = 0;

  @override
  Future<void> resetPrompt() async {
    resets++;
    prompt = true;
  }

  @override
  Future<NotificationPermission> status() async => current;

  @override
  Future<bool> shouldPrompt() async {
    promptChecks++;
    return prompt;
  }

  @override
  Future<NotificationPermission> request() async {
    requests++;
    prompt = false;
    current = answer;
    return answer;
  }

  @override
  Future<void> dismiss() async {
    dismissals++;
    prompt = false;
  }

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return true;
  }
}

/// Signs Nimal in and shows Home. [restoredSession] makes it look like an
/// app launch with a saved session instead of a fresh sign-in.
Future<void> _pumpHome(
  WidgetTester tester,
  _FakePermissions permissions, {
  bool restoredSession = false,
  Size size = const Size(390, 844),
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final auth = AuthController();
  await tester.runAsync(() => auth.login('nimal@example.com', 'x'));
  if (restoredSession) auth.takeJustSignedIn();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => ItemController()),
        ChangeNotifierProvider(create: (_) => RequestController()),
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => BadgeController()),
        ChangeNotifierProvider(create: (_) => LanguageController()),
        Provider<NotificationPermissionService>.value(value: permissions),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('si'), Locale('ta')],
        home: const HomeScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openTab(WidgetTester tester, AppGlyph glyph) async {
  await tester.tap(
    find.byWidgetPredicate((w) => w is AppIcon && w.glyph == glyph),
  );
  await tester.pumpAndSettle();
}

const _title = 'Allow ShareLoop to send you notifications?';

/// The real Login screen, with Home behind the app's home route, so the
/// whole Email + Password flow runs as in the app.
Future<AuthController> _pumpLogin(
  WidgetTester tester,
  _FakePermissions permissions,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final auth = AuthController();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => ItemController()),
        ChangeNotifierProvider(create: (_) => RequestController()),
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => BadgeController()),
        ChangeNotifierProvider(create: (_) => LanguageController()),
        Provider<NotificationPermissionService>.value(value: permissions),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('si'), Locale('ta')],
        home: const LoginScreen(),
        onGenerateRoute: (settings) => switch (settings.name) {
          AppRoutes.home => MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
          _ => null,
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return auth;
}

Future<void> _signIn(
  WidgetTester tester,
  String email,
  String password,
) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Enter your Email'),
    email,
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Enter Password'),
    password,
  );
  final button = find.widgetWithText(ElevatedButton, 'Sign In');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  // The mock login is real async work.
  await tester.runAsync(() async {
    await tester.tap(button);
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  await tester.pumpAndSettle();
}

void main() {
  group('Email + Password login', () {
    testWidgets('reaches Home, then shows the prompt once', (tester) async {
      final permissions = _FakePermissions();
      await _pumpLogin(tester, permissions);
      expect(find.byType(NotificationPromptDialog), findsNothing);

      await _signIn(tester, 'nimal@example.com', 'secret1');

      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text(_title), findsOneWidget);
      expect(permissions.promptChecks, 1);
    });

    testWidgets('a failed login shows no prompt', (tester) async {
      final permissions = _FakePermissions();
      await _pumpLogin(tester, permissions);

      await _signIn(tester, 'nobody@example.com', 'secret1');

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(NotificationPromptDialog), findsNothing);
      expect(permissions.promptChecks, 0);
    });

    testWidgets('after Maybe Later, signing in again shows no prompt', (
      tester,
    ) async {
      final permissions = _FakePermissions();
      final auth = await _pumpLogin(tester, permissions);
      await _signIn(tester, 'nimal@example.com', 'secret1');
      await tester.tap(find.text('Maybe Later'));
      await tester.pumpAndSettle();
      expect(permissions.dismissals, 1);

      // Sign out and back in: the saved choice holds.
      await auth.logout();
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      await tester.pumpAndSettle();
      await _signIn(tester, 'nimal@example.com', 'secret1');

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(NotificationPromptDialog), findsNothing);
      expect(permissions.promptChecks, 2);
    });
  });

  testWidgets('in a browser, a blocked permission points to site settings', (
    tester,
  ) async {
    final permissions = _FakePermissions(
      answer: NotificationPermission.permanentlyDenied,
    )..isBrowser = true;
    await _pumpHome(tester, permissions);

    await tester.tap(find.text('Allow Notifications'));
    await tester.pumpAndSettle();

    expect(find.textContaining('next to the address bar'), findsOneWidget);
    // A browser has no app settings page, so no button pretends to open one.
    expect(find.text('Open settings'), findsNothing);
  });

  testWidgets('appears on Home right after sign-in, with both actions', (
    tester,
  ) async {
    await _pumpHome(tester, _FakePermissions());

    expect(find.byType(NotificationPromptDialog), findsOneWidget);
    expect(find.text(_title), findsOneWidget);
    expect(
      find.text(
        'Stay updated on item requests, responses, and exchange updates.',
      ),
      findsOneWidget,
    );
    expect(find.text('Allow Notifications'), findsOneWidget);
    expect(find.text('Maybe Later'), findsOneWidget);
    // Home is underneath, not replaced.
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Allow asks the OS and confirms only what it granted', (
    tester,
  ) async {
    final permissions = _FakePermissions();
    await _pumpHome(tester, permissions);

    await tester.tap(find.text('Allow Notifications'));
    await tester.pumpAndSettle();

    expect(permissions.requests, 1);
    expect(find.byType(NotificationPromptDialog), findsNothing);
    expect(find.text('Notifications are on.'), findsOneWidget);
  });

  testWidgets('a denied request says so instead of claiming success', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      _FakePermissions(answer: NotificationPermission.denied),
    );

    await tester.tap(find.text('Allow Notifications'));
    await tester.pumpAndSettle();

    expect(find.text('Notifications are on.'), findsNothing);
    expect(find.textContaining('Notifications are off.'), findsOneWidget);
  });

  testWidgets('a permanent denial offers the system settings', (
    tester,
  ) async {
    final permissions = _FakePermissions(
      answer: NotificationPermission.permanentlyDenied,
    );
    await _pumpHome(tester, permissions);

    await tester.tap(find.text('Allow Notifications'));
    await tester.pumpAndSettle();
    expect(find.textContaining('blocked for ShareLoop'), findsOneWidget);

    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(permissions.settingsOpened, 1);
  });

  testWidgets('Maybe Later closes it, remembers, and Home carries on', (
    tester,
  ) async {
    final permissions = _FakePermissions();
    await _pumpHome(tester, permissions);

    await tester.tap(find.text('Maybe Later'));
    await tester.pumpAndSettle();

    expect(permissions.dismissals, 1);
    expect(permissions.requests, 0);
    expect(find.byType(NotificationPromptDialog), findsNothing);
    expect(find.text('Available near you'), findsOneWidget);

    // Rebuilding Home (switching tabs) never shows it again.
    await _openTab(tester, AppGlyph.requests);
    await _openTab(tester, AppGlyph.home);
    expect(find.byType(NotificationPromptDialog), findsNothing);
    expect(permissions.promptChecks, 1);
  });

  testWidgets('not shown for a session restored at launch', (tester) async {
    final permissions = _FakePermissions();
    await _pumpHome(tester, permissions, restoredSession: true);

    expect(find.byType(NotificationPromptDialog), findsNothing);
    expect(permissions.promptChecks, 0);
  });

  testWidgets('not shown once this device has answered', (tester) async {
    await _pumpHome(tester, _FakePermissions(prompt: false));

    expect(find.byType(NotificationPromptDialog), findsNothing);
  });

  testWidgets('Profile → Notifications asks again when the OS allows it', (
    tester,
  ) async {
    final permissions = _FakePermissions(prompt: false);
    await _pumpHome(tester, permissions);
    await _openTab(tester, AppGlyph.profile);

    await tester.scrollUntilVisible(find.text('Notifications'), 200);
    await tester.ensureVisible(find.text('Notifications'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text(_title), findsOneWidget);

    await tester.tap(find.text('Allow Notifications'));
    await tester.pumpAndSettle();
    expect(permissions.requests, 1);

    // Once granted, the row just confirms it.
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationPromptDialog), findsNothing);
    expect(find.text('Notifications are on.'), findsOneWidget);
  });

  for (final locale in const [Locale('en'), Locale('si'), Locale('ta')]) {
    testWidgets('prompt fits 320px in ${locale.languageCode}', (tester) async {
      await _pumpHome(
        tester,
        _FakePermissions(),
        size: const Size(320, 568),
        locale: locale,
      );
      expect(find.byType(NotificationPromptDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
