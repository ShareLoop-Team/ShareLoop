import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'controllers/admin_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/badge_controller.dart';
import 'controllers/item_controller.dart';
import 'controllers/language_controller.dart';
import 'controllers/profile_controller.dart';
import 'controllers/rating_controller.dart';
import 'controllers/request_controller.dart';
import 'core/config/backend_config.dart';
import 'core/localization/generated/app_localizations.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'models/email_code.dart';
import 'models/item_request_model.dart';
import 'services/api_client.dart';
import 'views/admin/manage_categories_screen.dart';
import 'views/admin/manage_users_screen.dart';
import 'views/admin/moderate_posts_screen.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/complete_google_profile_screen.dart';
import 'views/auth/register_screen.dart';
import 'views/auth/verify_code_screen.dart';
import 'views/browse/category_browse_screen.dart';
import 'views/browse/search_filter_screen.dart';
import 'views/give_away/create_give_away_screen.dart';
import 'views/give_away/incoming_requests_screen.dart';
import 'views/give_away/item_details_screen.dart';
import 'views/handover/contact_shared_screen.dart';
import 'views/handover/handover_confirmation_screen.dart';
import 'views/handover/rating_review_screen.dart';
import 'views/home/home_screen.dart';
import 'views/onboarding/onboarding_screen.dart';
import 'views/profile/edit_profile_screen.dart';
import 'views/requests/create_request_screen.dart';
import 'views/settings/settings_screen.dart';
import 'views/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Without API_BASE_URL the app runs on mock data.
  if (BackendConfig.isConfigured) {
    await ApiClient.instance.initialize();
  }
  runApp(const ShareLoopApp());
}

/// Root widget: wires all Controllers (ChangeNotifier) into the widget tree
/// via Provider so any View below can read/watch them, and builds the
/// named route table used across the app.
class ShareLoopApp extends StatelessWidget {
  const ShareLoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ItemController()),
        ChangeNotifierProvider(create: (_) => RequestController()),
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => BadgeController()),
        ChangeNotifierProvider(create: (_) => RatingController()),
        ChangeNotifierProvider(create: (_) => AdminController()),
        ChangeNotifierProvider(create: (_) => LanguageController()),
      ],
      child: Consumer<LanguageController>(
        builder: (context, languageController, _) {
          return MaterialApp(
            title: 'ShareLoop',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            locale: languageController.locale,
            supportedLocales: const [Locale('en'), Locale('si'), Locale('ta')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: AppRoutes.splash,
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case AppRoutes.splash:
                  return MaterialPageRoute(
                    builder: (_) => const SplashScreen(),
                  );
                case AppRoutes.onboarding:
                  return MaterialPageRoute(
                    builder: (_) => const OnboardingScreen(),
                  );
                case AppRoutes.login:
                  return MaterialPageRoute(builder: (_) => const LoginScreen());
                case AppRoutes.register:
                  return MaterialPageRoute(
                    builder: (_) => const RegisterScreen(),
                  );
                case AppRoutes.verifyCode:
                  return MaterialPageRoute(
                    builder: (_) => VerifyCodeScreen(
                      args: settings.arguments as VerifyCodeArgs,
                    ),
                  );
                case AppRoutes.completeGoogleProfile:
                  return MaterialPageRoute(
                    builder: (_) => CompleteGoogleProfileScreen(
                      pending: settings.arguments as GoogleSignUpNeeded,
                    ),
                  );
                case AppRoutes.home:
                  return MaterialPageRoute(builder: (_) => const HomeScreen());
                case AppRoutes.editProfile:
                  return MaterialPageRoute(
                    builder: (_) => const EditProfileScreen(),
                  );
                case AppRoutes.categoryBrowse:
                  return MaterialPageRoute(
                    builder: (_) => CategoryBrowseScreen(
                      category: settings.arguments as String,
                    ),
                  );
                case AppRoutes.searchFilter:
                  return MaterialPageRoute(
                    builder: (_) => const SearchFilterScreen(),
                  );
                case AppRoutes.createGiveAway:
                  return MaterialPageRoute(
                    builder: (_) => CreateGiveAwayScreen(
                      forRequest: settings.arguments as ItemRequestModel?,
                    ),
                  );
                case AppRoutes.itemDetails:
                  return MaterialPageRoute(
                    builder: (_) =>
                        ItemDetailsScreen(postId: settings.arguments as String),
                  );
                case AppRoutes.incomingRequests:
                  return MaterialPageRoute(
                    builder: (_) => IncomingRequestsScreen(
                      postId: settings.arguments as String,
                    ),
                  );
                case AppRoutes.createRequest:
                  return MaterialPageRoute(
                    builder: (_) => CreateRequestScreen(
                      postId: settings.arguments as String?,
                    ),
                  );
                case AppRoutes.contactShared:
                  return MaterialPageRoute(
                    builder: (_) => ContactSharedScreen(
                      postId: settings.arguments as String,
                    ),
                  );
                case AppRoutes.handoverConfirmation:
                  return MaterialPageRoute(
                    builder: (_) => HandoverConfirmationScreen(
                      postId: settings.arguments as String,
                    ),
                  );
                case AppRoutes.ratingReview:
                  return MaterialPageRoute(
                    builder: (_) => RatingReviewScreen(
                      postId: settings.arguments as String,
                    ),
                  );
                case AppRoutes.adminUsers:
                  return MaterialPageRoute(
                    builder: (_) => const ManageUsersScreen(),
                  );
                case AppRoutes.adminPosts:
                  return MaterialPageRoute(
                    builder: (_) => const ModeratePostsScreen(),
                  );
                case AppRoutes.adminCategories:
                  return MaterialPageRoute(
                    builder: (_) => const ManageCategoriesScreen(),
                  );
                case AppRoutes.settings:
                  return MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  );
                default:
                  return MaterialPageRoute(
                    builder: (_) => const SplashScreen(),
                  );
              }
            },
          );
        },
      ),
    );
  }
}
