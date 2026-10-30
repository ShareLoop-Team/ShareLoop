import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si'),
    Locale('ta'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ShareLoop'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Give What You Don\'t Need. Get What You Do.'**
  String get tagline;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @giveAway.
  ///
  /// In en, this message translates to:
  /// **'Give Away'**
  String get giveAway;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @cityTown.
  ///
  /// In en, this message translates to:
  /// **'City / Town'**
  String get cityTown;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search items...'**
  String get search;

  /// No description provided for @noItemsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No items available right now.'**
  String get noItemsAvailable;

  /// No description provided for @noOpenRequests.
  ///
  /// In en, this message translates to:
  /// **'No open requests right now.'**
  String get noOpenRequests;

  /// No description provided for @myPosts.
  ///
  /// In en, this message translates to:
  /// **'My Posts'**
  String get myPosts;

  /// No description provided for @myRequests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequests;

  /// No description provided for @reviewsReceived.
  ///
  /// In en, this message translates to:
  /// **'Reviews Received'**
  String get reviewsReceived;

  /// No description provided for @donations.
  ///
  /// In en, this message translates to:
  /// **'Donations'**
  String get donations;

  /// No description provided for @requestThisItem.
  ///
  /// In en, this message translates to:
  /// **'Request this item'**
  String get requestThisItem;

  /// No description provided for @viewIncomingRequests.
  ///
  /// In en, this message translates to:
  /// **'View Incoming Requests'**
  String get viewIncomingRequests;

  /// No description provided for @submitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get submitRequest;

  /// No description provided for @publishPost.
  ///
  /// In en, this message translates to:
  /// **'Publish Post'**
  String get publishPost;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @onboardingDescription.
  ///
  /// In en, this message translates to:
  /// **'Give what you no longer need. Find what you do. Share items for free with your community across Sri Lanka.'**
  String get onboardingDescription;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @introSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get introSkip;

  /// No description provided for @introNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get introNext;

  /// No description provided for @introGiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Give what you don\'t need'**
  String get introGiveTitle;

  /// No description provided for @introGiveBody.
  ///
  /// In en, this message translates to:
  /// **'Books, clothes, furniture and more. Pass them on to someone nearby instead of throwing them away.'**
  String get introGiveBody;

  /// No description provided for @introShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Get what you do'**
  String get introShareTitle;

  /// No description provided for @introShareBody.
  ///
  /// In en, this message translates to:
  /// **'Find free items shared by your community and help keep useful things out of landfill.'**
  String get introShareBody;

  /// No description provided for @introPageLabel.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String introPageLabel(int current, int total);

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get loginWelcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fill your details or continue with social media'**
  String get loginSubtitle;

  /// No description provided for @loginEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your Email'**
  String get loginEmailHint;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Password'**
  String get loginPasswordHint;

  /// No description provided for @loginEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get loginEmailRequired;

  /// No description provided for @loginPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get loginPasswordRequired;

  /// No description provided for @loginShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get loginShowPassword;

  /// No description provided for @loginHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get loginHidePassword;

  /// No description provided for @loginRememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get loginRememberMe;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// No description provided for @loginForgotPasswordUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Password reset isn\'t available yet.'**
  String get loginForgotPasswordUnavailable;

  /// No description provided for @loginResetEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email above to reset your password.'**
  String get loginResetEnterEmail;

  /// No description provided for @loginResetSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for {email}, a password reset link is on its way.'**
  String loginResetSent(String email);

  /// No description provided for @loginSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginSignIn;

  /// No description provided for @loginOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get loginOr;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'New user?'**
  String get loginNoAccount;

  /// No description provided for @loginCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get loginCreateAccount;

  /// No description provided for @loginEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmailLabel;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// No description provided for @loginOrContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get loginOrContinueWith;

  /// No description provided for @loginWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get loginWithGoogle;

  /// No description provided for @loginWithFacebook.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Facebook'**
  String get loginWithFacebook;

  /// No description provided for @loginSocialUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Social sign-in isn\'t available yet.'**
  String get loginSocialUnavailable;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join the community and start sharing'**
  String get registerSubtitle;

  /// No description provided for @registerNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get registerNameHint;

  /// No description provided for @registerPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'07X XXX XXXX'**
  String get registerPhoneHint;

  /// No description provided for @registerDistrictHint.
  ///
  /// In en, this message translates to:
  /// **'Select your district'**
  String get registerDistrictHint;

  /// No description provided for @registerCityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Negombo'**
  String get registerCityHint;

  /// No description provided for @registerConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get registerConfirmPasswordHint;

  /// No description provided for @registerNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get registerNameRequired;

  /// No description provided for @registerPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get registerPhoneRequired;

  /// No description provided for @registerDistrictRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select your district'**
  String get registerDistrictRequired;

  /// No description provided for @registerCityRequired.
  ///
  /// In en, this message translates to:
  /// **'City / town is required'**
  String get registerCityRequired;

  /// No description provided for @registerPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least {min} characters'**
  String registerPasswordTooShort(int min);

  /// No description provided for @registerPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get registerPasswordMismatch;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerButton;

  /// No description provided for @registerHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get registerHaveAccount;

  /// No description provided for @registerSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get registerSignIn;

  /// No description provided for @registerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get registerNameLabel;

  /// No description provided for @registerPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get registerPasswordHint;

  /// No description provided for @registerConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get registerConfirmPasswordLabel;

  /// No description provided for @registerPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get registerPhoneLabel;

  /// No description provided for @registerDistrictLabel.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get registerDistrictLabel;

  /// No description provided for @registerCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City / Town'**
  String get registerCityLabel;

  /// No description provided for @registerAgreeTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the {terms} and {privacy}'**
  String registerAgreeTerms(String terms, String privacy);

  /// No description provided for @registerTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get registerTerms;

  /// No description provided for @registerPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get registerPrivacyPolicy;

  /// No description provided for @registerTermsRequired.
  ///
  /// In en, this message translates to:
  /// **'Please accept the Terms and Privacy Policy'**
  String get registerTermsRequired;

  /// No description provided for @registerOrSignUpWith.
  ///
  /// In en, this message translates to:
  /// **'or sign up with'**
  String get registerOrSignUpWith;

  /// No description provided for @registerWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign up with Google'**
  String get registerWithGoogle;

  /// No description provided for @registerWithFacebook.
  ///
  /// In en, this message translates to:
  /// **'Sign up with Facebook'**
  String get registerWithFacebook;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}. What are you sharing today?'**
  String homeGreeting(String name);

  /// No description provided for @homeGreetingGuest.
  ///
  /// In en, this message translates to:
  /// **'Hello! What are you sharing today?'**
  String get homeGreetingGuest;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Find items you need...'**
  String get homeSearchHint;

  /// No description provided for @homeGiveItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Give an Item'**
  String get homeGiveItemTitle;

  /// No description provided for @homeGiveItemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pass on what you no longer need, free'**
  String get homeGiveItemSubtitle;

  /// No description provided for @homeRequestItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Request an Item'**
  String get homeRequestItemTitle;

  /// No description provided for @homeRequestItemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell the community what you need'**
  String get homeRequestItemSubtitle;

  /// No description provided for @homeAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get homeAllCategories;

  /// No description provided for @homeCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get homeCategories;

  /// No description provided for @homeAvailableNearYou.
  ///
  /// In en, this message translates to:
  /// **'Available near you'**
  String get homeAvailableNearYou;

  /// No description provided for @homeOpenRequests.
  ///
  /// In en, this message translates to:
  /// **'Open requests'**
  String get homeOpenRequests;

  /// No description provided for @homeAllDistricts.
  ///
  /// In en, this message translates to:
  /// **'All districts'**
  String get homeAllDistricts;

  /// No description provided for @homeChooseDistrict.
  ///
  /// In en, this message translates to:
  /// **'Choose a district'**
  String get homeChooseDistrict;

  /// No description provided for @homeChooseCity.
  ///
  /// In en, this message translates to:
  /// **'Choose your city'**
  String get homeChooseCity;

  /// No description provided for @homeSelectCity.
  ///
  /// In en, this message translates to:
  /// **'Select city'**
  String get homeSelectCity;

  /// No description provided for @homeAllAreas.
  ///
  /// In en, this message translates to:
  /// **'All areas'**
  String get homeAllAreas;

  /// No description provided for @homeChangeDistrict.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get homeChangeDistrict;

  /// No description provided for @homeCityDistrict.
  ///
  /// In en, this message translates to:
  /// **'District: {district}'**
  String homeCityDistrict(String district);

  /// No description provided for @locationCityHint.
  ///
  /// In en, this message translates to:
  /// **'Select your city or town'**
  String get locationCityHint;

  /// No description provided for @locationCityNeedsDistrict.
  ///
  /// In en, this message translates to:
  /// **'Select a district first'**
  String get locationCityNeedsDistrict;

  /// No description provided for @locationUseMine.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get locationUseMine;

  /// No description provided for @locationDetecting.
  ///
  /// In en, this message translates to:
  /// **'Finding your location…'**
  String get locationDetecting;

  /// No description provided for @locationExplainTitle.
  ///
  /// In en, this message translates to:
  /// **'Use your location?'**
  String get locationExplainTitle;

  /// No description provided for @locationExplainBody.
  ///
  /// In en, this message translates to:
  /// **'ShareLoop reads your location once to find your district and city. It isn\'t tracked in the background or shared with anyone.'**
  String get locationExplainBody;

  /// No description provided for @locationExplainContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get locationExplainContinue;

  /// No description provided for @locationNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get locationNotNow;

  /// No description provided for @locationDetected.
  ///
  /// In en, this message translates to:
  /// **'Location set to {city}, {district}.'**
  String locationDetected(String city, String district);

  /// No description provided for @locationFilled.
  ///
  /// In en, this message translates to:
  /// **'Found {city}, {district}. Tap Save Changes to keep it.'**
  String locationFilled(String city, String district);

  /// No description provided for @locationDistrictOnly.
  ///
  /// In en, this message translates to:
  /// **'You\'re in {district} district. Please choose your city.'**
  String locationDistrictOnly(String district);

  /// No description provided for @locationOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get locationOpenSettings;

  /// No description provided for @locationErrorUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Finding your location works in the ShareLoop app on Android and iPhone. Please choose your district and city.'**
  String get locationErrorUnsupported;

  /// No description provided for @locationErrorServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are turned off. Turn them on, or choose your city.'**
  String get locationErrorServiceDisabled;

  /// No description provided for @locationErrorDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission wasn\'t given. You can choose your city instead.'**
  String get locationErrorDenied;

  /// No description provided for @locationErrorBlocked.
  ///
  /// In en, this message translates to:
  /// **'Location access is blocked for ShareLoop. Allow it in Settings, or choose your city.'**
  String get locationErrorBlocked;

  /// No description provided for @locationErrorTimeout.
  ///
  /// In en, this message translates to:
  /// **'Finding your location took too long. Try again, or choose your city.'**
  String get locationErrorTimeout;

  /// No description provided for @locationErrorInaccurate.
  ///
  /// In en, this message translates to:
  /// **'Your location isn\'t precise enough. Turn on precise location, or choose your city.'**
  String get locationErrorInaccurate;

  /// No description provided for @locationErrorOutside.
  ///
  /// In en, this message translates to:
  /// **'You seem to be outside Sri Lanka. Please choose your district and city.'**
  String get locationErrorOutside;

  /// No description provided for @locationErrorNotMatched.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t match your location to a district. Please choose it yourself.'**
  String get locationErrorNotMatched;

  /// No description provided for @locationErrorFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find your location. Try again, or choose your city.'**
  String get locationErrorFailed;

  /// No description provided for @locationErrorLookup.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t look up your area. Check your internet connection, or choose your city.'**
  String get locationErrorLookup;

  /// No description provided for @homeGive.
  ///
  /// In en, this message translates to:
  /// **'Give'**
  String get homeGive;

  /// No description provided for @homeDonorBadge.
  ///
  /// In en, this message translates to:
  /// **'{badge} donor'**
  String homeDonorBadge(String badge);

  /// No description provided for @homeNewDonor.
  ///
  /// In en, this message translates to:
  /// **'New donor'**
  String get homeNewDonor;

  /// No description provided for @homeRequestedBy.
  ///
  /// In en, this message translates to:
  /// **'Requested by {name}'**
  String homeRequestedBy(String name);

  /// No description provided for @giveTitle.
  ///
  /// In en, this message translates to:
  /// **'Give an Item'**
  String get giveTitle;

  /// No description provided for @giveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share something useful with your community'**
  String get giveSubtitle;

  /// No description provided for @givePhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get givePhotos;

  /// No description provided for @giveAddPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add photos of your item'**
  String get giveAddPhotos;

  /// No description provided for @giveAddPhotosHint.
  ///
  /// In en, this message translates to:
  /// **'Clear photos help others decide faster'**
  String get giveAddPhotosHint;

  /// No description provided for @givePhotosItemOnly.
  ///
  /// In en, this message translates to:
  /// **'Photograph the item only, with no people, hands or faces'**
  String get givePhotosItemOnly;

  /// No description provided for @photoChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking photo…'**
  String get photoChecking;

  /// No description provided for @photoHasPerson.
  ///
  /// In en, this message translates to:
  /// **'This photo contains a person or a visible body part. Please upload a photo of the item only.'**
  String get photoHasPerson;

  /// No description provided for @photoCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t check this photo, so it wasn\'t added. Please try again or choose another photo.'**
  String get photoCheckFailed;

  /// No description provided for @photoCheckUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Photos can\'t be checked on this device, so they can\'t be added here. Please use the phone app or a web browser.'**
  String get photoCheckUnsupported;

  /// No description provided for @giveAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get giveAddPhoto;

  /// No description provided for @giveRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get giveRemovePhoto;

  /// No description provided for @giveCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get giveCover;

  /// No description provided for @giveTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get giveTakePhoto;

  /// No description provided for @giveChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get giveChooseFromGallery;

  /// No description provided for @cameraCapture.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get cameraCapture;

  /// No description provided for @cameraSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch camera'**
  String get cameraSwitch;

  /// No description provided for @cameraRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get cameraRetake;

  /// No description provided for @cameraUsePhoto.
  ///
  /// In en, this message translates to:
  /// **'Use photo'**
  String get cameraUsePhoto;

  /// No description provided for @cameraNotFound.
  ///
  /// In en, this message translates to:
  /// **'No camera found on this device.'**
  String get cameraNotFound;

  /// No description provided for @cameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is blocked. Allow it in your browser or system settings, then try again.'**
  String get cameraPermissionDenied;

  /// No description provided for @cameraFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the camera. Please try again.'**
  String get cameraFailed;

  /// No description provided for @cropTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust photo'**
  String get cropTitle;

  /// No description provided for @cropHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to move. Pinch, scroll or use the slider to zoom.'**
  String get cropHint;

  /// No description provided for @cropZoom.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get cropZoom;

  /// No description provided for @giveItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Item title'**
  String get giveItemTitle;

  /// No description provided for @giveItemTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Grade 10 Science Textbook'**
  String get giveItemTitleHint;

  /// No description provided for @giveItemTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get giveItemTitleRequired;

  /// No description provided for @giveDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get giveDescription;

  /// No description provided for @giveDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Tell others about the item, its size, and any wear'**
  String get giveDescriptionHint;

  /// No description provided for @giveDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Please add a short description'**
  String get giveDescriptionRequired;

  /// No description provided for @giveCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get giveCategory;

  /// No description provided for @giveCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get giveCategoryHint;

  /// No description provided for @giveCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get giveCategoryRequired;

  /// No description provided for @giveCondition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get giveCondition;

  /// No description provided for @giveDistrictHint.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get giveDistrictHint;

  /// No description provided for @giveDistrictRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a district'**
  String get giveDistrictRequired;

  /// No description provided for @giveCityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Negombo'**
  String get giveCityHint;

  /// No description provided for @giveCityRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a city'**
  String get giveCityRequired;

  /// No description provided for @givePublish.
  ///
  /// In en, this message translates to:
  /// **'Publish Item'**
  String get givePublish;

  /// No description provided for @givePublished.
  ///
  /// In en, this message translates to:
  /// **'Your item is now live!'**
  String get givePublished;

  /// No description provided for @requestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'People near you who need an item'**
  String get requestsSubtitle;

  /// No description provided for @requestsNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get requestsNew;

  /// No description provided for @requestsAll.
  ///
  /// In en, this message translates to:
  /// **'All requests'**
  String get requestsAll;

  /// No description provided for @requestsMine.
  ///
  /// In en, this message translates to:
  /// **'My requests'**
  String get requestsMine;

  /// No description provided for @requestsICanHelp.
  ///
  /// In en, this message translates to:
  /// **'I can help'**
  String get requestsICanHelp;

  /// No description provided for @requestsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete request'**
  String get requestsDelete;

  /// No description provided for @requestsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit request'**
  String get requestsEdit;

  /// No description provided for @requestsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this request?'**
  String get requestsDeleteConfirm;

  /// No description provided for @requestsDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Donors will no longer see it. This can\'t be undone.'**
  String get requestsDeleteMessage;

  /// No description provided for @requestsDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get requestsDeleteAction;

  /// No description provided for @requestsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Request deleted.'**
  String get requestsDeleted;

  /// No description provided for @postDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete post'**
  String get postDelete;

  /// No description provided for @postDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this post?'**
  String get postDeleteConfirm;

  /// No description provided for @postDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'It will be removed from the feed and any requests for it will be cancelled. This can\'t be undone.'**
  String get postDeleteMessage;

  /// No description provided for @postDeleted.
  ///
  /// In en, this message translates to:
  /// **'Post deleted.'**
  String get postDeleted;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpen;

  /// No description provided for @statusDonorReviewing.
  ///
  /// In en, this message translates to:
  /// **'Donor reviewing'**
  String get statusDonorReviewing;

  /// No description provided for @requestTitle.
  ///
  /// In en, this message translates to:
  /// **'Request an Item'**
  String get requestTitle;

  /// No description provided for @requestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask your community for what you need'**
  String get requestSubtitle;

  /// No description provided for @requestInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Your community is here to help.'**
  String get requestInfoTitle;

  /// No description provided for @requestInfoBody.
  ///
  /// In en, this message translates to:
  /// **'Donors read your reason before choosing, so be clear and honest.'**
  String get requestInfoBody;

  /// No description provided for @requestYouAreRequesting.
  ///
  /// In en, this message translates to:
  /// **'You\'re requesting'**
  String get requestYouAreRequesting;

  /// No description provided for @requestItemName.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get requestItemName;

  /// No description provided for @requestItemNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Grade 10 Science Textbook'**
  String get requestItemNameHint;

  /// No description provided for @requestItemNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the item name'**
  String get requestItemNameRequired;

  /// No description provided for @requestDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What exactly do you need? Size, edition, or any details'**
  String get requestDescriptionHint;

  /// No description provided for @requestReason.
  ///
  /// In en, this message translates to:
  /// **'Why do you need it?'**
  String get requestReason;

  /// No description provided for @requestReasonHint.
  ///
  /// In en, this message translates to:
  /// **'A short reason helps donors choose fairly'**
  String get requestReasonHint;

  /// No description provided for @requestReasonHelper.
  ///
  /// In en, this message translates to:
  /// **'Shown to donors when they review requests'**
  String get requestReasonHelper;

  /// No description provided for @requestReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please tell donors why you need it'**
  String get requestReasonRequired;

  /// No description provided for @requestNotes.
  ///
  /// In en, this message translates to:
  /// **'Additional notes'**
  String get requestNotes;

  /// No description provided for @requestOptional.
  ///
  /// In en, this message translates to:
  /// **'(optional)'**
  String get requestOptional;

  /// No description provided for @requestNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Anything else donors should know'**
  String get requestNotesHint;

  /// No description provided for @requestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Your request has been submitted.'**
  String get requestSubmitted;

  /// No description provided for @requestUpdated.
  ///
  /// In en, this message translates to:
  /// **'Your request has been updated.'**
  String get requestUpdated;

  /// No description provided for @requestEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Request'**
  String get requestEditTitle;

  /// No description provided for @requestEditSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update what donors see about your request'**
  String get requestEditSubtitle;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profileTitle;

  /// No description provided for @profileEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEditProfile;

  /// No description provided for @profileItemsGiven.
  ///
  /// In en, this message translates to:
  /// **'Items given'**
  String get profileItemsGiven;

  /// No description provided for @profileRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get profileRating;

  /// No description provided for @profileNextBadge.
  ///
  /// In en, this message translates to:
  /// **'Next badge: {badge}'**
  String profileNextBadge(String badge);

  /// No description provided for @profileBadgeProgress.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} items'**
  String profileBadgeProgress(int count, int total);

  /// No description provided for @profileAllBadgesEarned.
  ///
  /// In en, this message translates to:
  /// **'Every badge earned. Thank you!'**
  String get profileAllBadgesEarned;

  /// No description provided for @profileMyActivity.
  ///
  /// In en, this message translates to:
  /// **'My activity'**
  String get profileMyActivity;

  /// No description provided for @profileMyDonations.
  ///
  /// In en, this message translates to:
  /// **'My Donations'**
  String get profileMyDonations;

  /// No description provided for @profileReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get profileReviews;

  /// No description provided for @profileNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileNotifications;

  /// No description provided for @profileNotificationsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Notifications aren\'t available yet.'**
  String get profileNotificationsUnavailable;

  /// No description provided for @notifPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow ShareLoop to send you notifications?'**
  String get notifPromptTitle;

  /// No description provided for @notifPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Stay updated on item requests, responses, and exchange updates.'**
  String get notifPromptBody;

  /// No description provided for @notifPromptAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow Notifications'**
  String get notifPromptAllow;

  /// No description provided for @notifPromptLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get notifPromptLater;

  /// No description provided for @notifEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications are on.'**
  String get notifEnabled;

  /// No description provided for @notifDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off. You can turn them on any time from Profile → Notifications.'**
  String get notifDenied;

  /// No description provided for @notifBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked for ShareLoop. Turn them on in your phone\'s settings.'**
  String get notifBlocked;

  /// No description provided for @notifBlockedBrowser.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked for ShareLoop in this browser. Allow them from the site settings next to the address bar.'**
  String get notifBlockedBrowser;

  /// No description provided for @notifOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get notifOpenSettings;

  /// No description provided for @stateLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this. Check your connection and try again.'**
  String get stateLoadFailed;

  /// No description provided for @stateRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get stateRetry;

  /// No description provided for @stateNoMatches.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches your search or filters.'**
  String get stateNoMatches;

  /// No description provided for @stateClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get stateClearFilters;

  /// No description provided for @searchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get searchClear;

  /// No description provided for @discardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardTitle;

  /// No description provided for @discardMessage.
  ///
  /// In en, this message translates to:
  /// **'What you\'ve entered will be lost.'**
  String get discardMessage;

  /// No description provided for @discardAction.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardAction;

  /// No description provided for @profileAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get profileAdmin;

  /// No description provided for @profileManageUsers.
  ///
  /// In en, this message translates to:
  /// **'Manage users'**
  String get profileManageUsers;

  /// No description provided for @profileModeratePosts.
  ///
  /// In en, this message translates to:
  /// **'Moderate posts'**
  String get profileModeratePosts;

  /// No description provided for @profileManageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage categories'**
  String get profileManageCategories;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get profileSignOut;

  /// No description provided for @profileSignOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out of ShareLoop?'**
  String get profileSignOutConfirm;

  /// No description provided for @profileSignOutMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to log in again to give or request items.'**
  String get profileSignOutMessage;

  /// No description provided for @profileNoRequests.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t requested any items yet.'**
  String get profileNoRequests;

  /// No description provided for @statusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get statusAvailable;

  /// No description provided for @statusHandoverPending.
  ///
  /// In en, this message translates to:
  /// **'Handover pending'**
  String get statusHandoverPending;

  /// No description provided for @statusGiven.
  ///
  /// In en, this message translates to:
  /// **'Given'**
  String get statusGiven;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get statusNotSelected;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String timeDaysAgo(int count);

  /// No description provided for @itemDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Item details'**
  String get itemDetailsTitle;

  /// No description provided for @itemDetailsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get itemDetailsAvailable;

  /// No description provided for @itemDetailsPendingHandover.
  ///
  /// In en, this message translates to:
  /// **'Handover pending'**
  String get itemDetailsPendingHandover;

  /// No description provided for @itemDetailsGivenAway.
  ///
  /// In en, this message translates to:
  /// **'Given away'**
  String get itemDetailsGivenAway;

  /// No description provided for @itemDetailsPosted.
  ///
  /// In en, this message translates to:
  /// **'Posted {time}'**
  String itemDetailsPosted(String time);

  /// No description provided for @itemDetailsItemsGiven.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item given} other{{count} items given}}'**
  String itemDetailsItemsGiven(int count);

  /// No description provided for @itemDetailsPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Contact details stay private. The donor reads the reasons of all requesters and shares contact details only with the one they select.'**
  String get itemDetailsPrivacyNote;

  /// No description provided for @itemDetailsRequest.
  ///
  /// In en, this message translates to:
  /// **'Request this item'**
  String get itemDetailsRequest;

  /// No description provided for @itemDetailsViewRequests.
  ///
  /// In en, this message translates to:
  /// **'View incoming requests'**
  String get itemDetailsViewRequests;

  /// No description provided for @itemDetailsArrangeHandover.
  ///
  /// In en, this message translates to:
  /// **'Arrange handover'**
  String get itemDetailsArrangeHandover;

  /// No description provided for @itemDetailsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This item is no longer available.'**
  String get itemDetailsUnavailable;

  /// No description provided for @itemDetailsClosed.
  ///
  /// In en, this message translates to:
  /// **'This item is no longer available for requests.'**
  String get itemDetailsClosed;

  /// No description provided for @itemDetailsShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get itemDetailsShare;

  /// No description provided for @itemDetailsViewPhoto.
  ///
  /// In en, this message translates to:
  /// **'View photo full screen'**
  String get itemDetailsViewPhoto;

  /// No description provided for @itemDetailsShareText.
  ///
  /// In en, this message translates to:
  /// **'{title} is free to a good home on ShareLoop ({district}). {description}'**
  String itemDetailsShareText(
    String title,
    String district,
    String description,
  );

  /// No description provided for @editProfileChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get editProfileChangePhoto;

  /// No description provided for @editProfileEmailLocked.
  ///
  /// In en, this message translates to:
  /// **'Your email cannot be changed'**
  String get editProfileEmailLocked;

  /// No description provided for @editProfilePhoneNote.
  ///
  /// In en, this message translates to:
  /// **'Your phone number is shared only with the person you are matched with, after the donor selects a requester.'**
  String get editProfilePhoneNote;

  /// No description provided for @editProfilePhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get editProfilePhoneInvalid;

  /// No description provided for @editProfileSave.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get editProfileSave;

  /// No description provided for @editProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile updated.'**
  String get editProfileSaved;

  /// No description provided for @editProfileFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your profile. Please try again.'**
  String get editProfileFailed;

  /// No description provided for @myRequestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Items you have asked for'**
  String get myRequestsSubtitle;

  /// No description provided for @myRequestsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get myRequestsEmptyTitle;

  /// No description provided for @myRequestsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Need something? Ask your community. Donors read your reason before they choose.'**
  String get myRequestsEmptyBody;

  /// No description provided for @myRequestsTipLabel.
  ///
  /// In en, this message translates to:
  /// **'Tip:'**
  String get myRequestsTipLabel;

  /// No description provided for @myRequestsTip.
  ///
  /// In en, this message translates to:
  /// **'a short, honest reason helps donors choose fairly.'**
  String get myRequestsTip;

  /// No description provided for @myRequestsAction.
  ///
  /// In en, this message translates to:
  /// **'Request an item'**
  String get myRequestsAction;

  /// No description provided for @myDonationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Items you have given away'**
  String get myDonationsSubtitle;

  /// No description provided for @myDonationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No donations yet'**
  String get myDonationsEmptyTitle;

  /// No description provided for @myDonationsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Items you give away will show up here. Your first donation starts your badge journey.'**
  String get myDonationsEmptyBody;

  /// No description provided for @myDonationsBadgeTitle.
  ///
  /// In en, this message translates to:
  /// **'{badge} badge'**
  String myDonationsBadgeTitle(String badge);

  /// No description provided for @myDonationsBadgeHint.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Give 1 more item to become a {level}} other{Give {count} items to become a {level}}}'**
  String myDonationsBadgeHint(int count, String level);

  /// No description provided for @myDonationsFirstAction.
  ///
  /// In en, this message translates to:
  /// **'Give your first item'**
  String get myDonationsFirstAction;

  /// No description provided for @myDonationsAction.
  ///
  /// In en, this message translates to:
  /// **'Give an item'**
  String get myDonationsAction;

  /// No description provided for @myReviewsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What others say about you'**
  String get myReviewsSubtitle;

  /// No description provided for @myReviewsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get myReviewsEmptyTitle;

  /// No description provided for @myReviewsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'After each exchange, you and the other person can rate each other. Good reviews build trust.'**
  String get myReviewsEmptyBody;

  /// No description provided for @myReviewsFirstTitle.
  ///
  /// In en, this message translates to:
  /// **'Get your first review'**
  String get myReviewsFirstTitle;

  /// No description provided for @myReviewsFirstBody.
  ///
  /// In en, this message translates to:
  /// **'Give or receive an item and complete the handover to unlock ratings.'**
  String get myReviewsFirstBody;

  /// No description provided for @myReviewsAction.
  ///
  /// In en, this message translates to:
  /// **'Browse items'**
  String get myReviewsAction;

  /// No description provided for @myReviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 review} other{{count} reviews}}'**
  String myReviewsCount(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
