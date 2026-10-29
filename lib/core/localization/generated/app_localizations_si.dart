// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Sinhala Sinhalese (`si`).
class AppLocalizationsSi extends AppLocalizations {
  AppLocalizationsSi([String locale = 'si']) : super(locale);

  @override
  String get appTitle => 'ShareLoop';

  @override
  String get tagline => 'ඔබට අවශ්‍ය නැති දේ දෙන්න. ඔබට අවශ්‍ය දේ ලබා ගන්න.';

  @override
  String get home => 'මුල් පිටුව';

  @override
  String get profile => 'පැතිකඩ';

  @override
  String get settings => 'සැකසුම්';

  @override
  String get giveAway => 'පරිත්‍යාග කරන්න';

  @override
  String get requests => 'ඉල්ලීම්';

  @override
  String get login => 'ඇතුල් වන්න';

  @override
  String get register => 'ලියාපදිංචි වන්න';

  @override
  String get logout => 'ඉවත් වන්න';

  @override
  String get email => 'විද්‍යුත් තැපෑල';

  @override
  String get password => 'මුරපදය';

  @override
  String get fullName => 'සම්පූර්ණ නම';

  @override
  String get phoneNumber => 'දුරකථන අංකය';

  @override
  String get district => 'දිස්ත්‍රික්කය';

  @override
  String get cityTown => 'නගරය';

  @override
  String get search => 'අයිතම සොයන්න...';

  @override
  String get noItemsAvailable => 'දැනට ලබාගත හැකි අයිතම නැත.';

  @override
  String get noOpenRequests => 'දැනට විවෘත ඉල්ලීම් නැත.';

  @override
  String get myPosts => 'මගේ පළකිරීම්';

  @override
  String get myRequests => 'මගේ ඉල්ලීම්';

  @override
  String get reviewsReceived => 'ලැබුණු විචාර';

  @override
  String get donations => 'පරිත්‍යාග';

  @override
  String get requestThisItem => 'මෙම අයිතමය ඉල්ලන්න';

  @override
  String get viewIncomingRequests => 'ලැබෙන ඉල්ලීම් බලන්න';

  @override
  String get submitRequest => 'ඉල්ලීම ඉදිරිපත් කරන්න';

  @override
  String get publishPost => 'පළ කරන්න';

  @override
  String get language => 'භාෂාව';

  @override
  String get onboardingDescription =>
      'ඔබට තවදුරටත් අවශ්‍ය නැති දේ දෙන්න. ඔබට අවශ්‍ය දේ සොයා ගන්න. ශ්‍රී ලංකාව පුරා ඔබේ ප්‍රජාව සමඟ භාණ්ඩ නොමිලේ බෙදා ගන්න.';

  @override
  String get onboardingGetStarted => 'අරඹමු';

  @override
  String get introSkip => 'මඟ හරින්න';

  @override
  String get introNext => 'ඊළඟ';

  @override
  String get introGiveTitle => 'ඔබට අවශ්‍ය නැති දේ දෙන්න';

  @override
  String get introGiveBody =>
      'පොත්, ඇඳුම්, ගෘහ භාණ්ඩ සහ තවත් දේ. ඒවා ඉවත නොදමා ළඟ සිටින කෙනෙකුට දෙන්න.';

  @override
  String get introShareTitle => 'ඔබට අවශ්‍ය දේ ලබාගන්න';

  @override
  String get introShareBody =>
      'ඔබේ ප්‍රජාව බෙදාගන්නා නොමිලේ භාණ්ඩ සොයාගෙන ප්‍රයෝජනවත් දේ අපතේ යාම වළක්වන්න.';

  @override
  String introPageLabel(int current, int total) {
    return '$total න් $current වන පිටුව';
  }

  @override
  String get loginWelcomeBack => 'නැවත සාදරයෙන් පිළිගනිමු';

  @override
  String get loginSubtitle =>
      'ඔබේ විස්තර ඇතුළත් කරන්න හෝ සමාජ මාධ්‍ය හරහා ඉදිරියට යන්න';

  @override
  String get loginEmailHint => 'ඔබේ ඊමේල් ලිපිනය ඇතුළත් කරන්න';

  @override
  String get loginPasswordHint => 'මුරපදය ඇතුළත් කරන්න';

  @override
  String get loginEmailRequired => 'ඊමේල් ලිපිනය අවශ්‍යයි';

  @override
  String get loginPasswordRequired => 'මුරපදය අවශ්‍යයි';

  @override
  String get loginShowPassword => 'මුරපදය පෙන්වන්න';

  @override
  String get loginHidePassword => 'මුරපදය සඟවන්න';

  @override
  String get loginRememberMe => 'මාව මතක තබා ගන්න';

  @override
  String get loginForgotPassword => 'මුරපදය අමතකද?';

  @override
  String get loginForgotPasswordUnavailable =>
      'මුරපදය යළි සැකසීම තවම ලබා ගත නොහැක.';

  @override
  String get loginResetEnterEmail =>
      'මුරපදය යළි සැකසීමට ඉහත ඔබේ ඊමේල් ලිපිනය ඇතුළත් කරන්න.';

  @override
  String loginResetSent(String email) {
    return '$email සඳහා ගිණුමක් තිබේ නම්, මුරපදය යළි සැකසීමේ සබැඳියක් එවනු ලැබේ.';
  }

  @override
  String get loginSignIn => 'ඇතුල් වන්න';

  @override
  String get loginOr => 'හෝ';

  @override
  String get loginNoAccount => 'නව පරිශීලකයෙක්ද?';

  @override
  String get loginCreateAccount => 'ගිණුමක් සාදන්න';

  @override
  String get loginEmailLabel => 'ඊමේල්';

  @override
  String get loginPasswordLabel => 'මුරපදය';

  @override
  String get loginOrContinueWith => 'හෝ මෙයින් ඉදිරියට යන්න';

  @override
  String get loginWithGoogle => 'Google සමඟ ඇතුල් වන්න';

  @override
  String get loginWithFacebook => 'Facebook සමඟ ඇතුල් වන්න';

  @override
  String get loginSocialUnavailable =>
      'සමාජ මාධ්‍ය හරහා ඇතුල් වීම තවම ලබා ගත නොහැක.';

  @override
  String get registerTitle => 'ගිණුමක් සාදන්න';

  @override
  String get registerSubtitle => 'ප්‍රජාවට එක්වී බෙදාගැනීම අරඹන්න';

  @override
  String get registerNameHint => 'ඔබේ සම්පූර්ණ නම ඇතුළත් කරන්න';

  @override
  String get registerPhoneHint => '07X XXX XXXX';

  @override
  String get registerDistrictHint => 'ඔබේ දිස්ත්‍රික්කය තෝරන්න';

  @override
  String get registerCityHint => 'උදා. මීගමුව';

  @override
  String get registerConfirmPasswordHint => 'මුරපදය නැවත ඇතුළත් කරන්න';

  @override
  String get registerNameRequired => 'නම අවශ්‍යයි';

  @override
  String get registerPhoneRequired => 'දුරකථන අංකය අවශ්‍යයි';

  @override
  String get registerDistrictRequired => 'කරුණාකර ඔබේ දිස්ත්‍රික්කය තෝරන්න';

  @override
  String get registerCityRequired => 'නගරය අවශ්‍යයි';

  @override
  String registerPasswordTooShort(int min) {
    return 'මුරපදයේ අවම වශයෙන් අක්ෂර $minක් තිබිය යුතුයි';
  }

  @override
  String get registerPasswordMismatch => 'මුරපද නොගැළපේ';

  @override
  String get registerButton => 'ගිණුම සාදන්න';

  @override
  String get registerHaveAccount => 'දැනටමත් ගිණුමක් තිබේද?';

  @override
  String get registerSignIn => 'ඇතුල් වන්න';

  @override
  String get registerNameLabel => 'සම්පූර්ණ නම';

  @override
  String get registerPasswordHint => 'මුරපදයක් සාදන්න';

  @override
  String get registerConfirmPasswordLabel => 'මුරපදය තහවුරු කරන්න';

  @override
  String get registerPhoneLabel => 'දුරකථන අංකය';

  @override
  String get registerDistrictLabel => 'දිස්ත්‍රික්කය';

  @override
  String get registerCityLabel => 'නගරය';

  @override
  String registerAgreeTerms(String terms, String privacy) {
    return 'මම $terms සහ $privacy වලට එකඟ වෙමි';
  }

  @override
  String get registerTerms => 'නියමයන්';

  @override
  String get registerPrivacyPolicy => 'පෞද්ගලිකත්ව ප්‍රතිපත්තිය';

  @override
  String get registerTermsRequired =>
      'කරුණාකර නියමයන් සහ පෞද්ගලිකත්ව ප්‍රතිපත්තිය පිළිගන්න';

  @override
  String get registerOrSignUpWith => 'හෝ මෙයින් ලියාපදිංචි වන්න';

  @override
  String get registerWithGoogle => 'Google සමඟ ලියාපදිංචි වන්න';

  @override
  String get registerWithFacebook => 'Facebook සමඟ ලියාපදිංචි වන්න';

  @override
  String homeGreeting(String name) {
    return 'ආයුබෝවන්, $name. අද ඔබ බෙදා ගන්නේ කුමක්ද?';
  }

  @override
  String get homeGreetingGuest => 'ආයුබෝවන්! අද ඔබ බෙදා ගන්නේ කුමක්ද?';

  @override
  String get homeSearchHint => 'ඔබට අවශ්‍ය අයිතම සොයන්න...';

  @override
  String get homeGiveItemTitle => 'අයිතමයක් දෙන්න';

  @override
  String get homeGiveItemSubtitle => 'ඔබට තවදුරටත් අවශ්‍ය නැති දේ නොමිලේ දෙන්න';

  @override
  String get homeRequestItemTitle => 'අයිතමයක් ඉල්ලන්න';

  @override
  String get homeRequestItemSubtitle => 'ඔබට අවශ්‍ය දේ ප්‍රජාවට කියන්න';

  @override
  String get homeAllCategories => 'සියල්ල';

  @override
  String get homeAvailableNearYou => 'ඔබ අසල ලබාගත හැකි';

  @override
  String get homeOpenRequests => 'විවෘත ඉල්ලීම්';

  @override
  String get homeAllDistricts => 'සියලු දිස්ත්‍රික්ක';

  @override
  String get homeChooseDistrict => 'දිස්ත්‍රික්කයක් තෝරන්න';

  @override
  String get homeGive => 'දෙන්න';

  @override
  String homeDonorBadge(String badge) {
    return '$badge පරිත්‍යාගශීලී';
  }

  @override
  String get homeNewDonor => 'නව පරිත්‍යාගශීලී';

  @override
  String homeRequestedBy(String name) {
    return 'ඉල්ලුවේ $name';
  }

  @override
  String get giveTitle => 'අයිතමයක් දෙන්න';

  @override
  String get giveSubtitle => 'ඔබේ ප්‍රජාවට ප්‍රයෝජනවත් දෙයක් බෙදා දෙන්න';

  @override
  String get givePhotos => 'ඡායාරූප';

  @override
  String get giveAddPhotos => 'ඔබේ අයිතමයේ ඡායාරූප එක් කරන්න';

  @override
  String get giveAddPhotosHint =>
      'පැහැදිලි ඡායාරූප අනෙක් අයට ඉක්මනින් තීරණය කිරීමට උදව් වේ';

  @override
  String get giveAddPhoto => 'ඡායාරූපයක් එක් කරන්න';

  @override
  String get giveRemovePhoto => 'ඡායාරූපය ඉවත් කරන්න';

  @override
  String get giveCover => 'ප්‍රධාන';

  @override
  String get giveTakePhoto => 'ඡායාරූපයක් ගන්න';

  @override
  String get giveChooseFromGallery => 'ගැලරියෙන් තෝරන්න';

  @override
  String get giveItemTitle => 'අයිතමයේ නම';

  @override
  String get giveItemTitleHint => 'උදා: 10 ශ්‍රේණියේ විද්‍යා පෙළපොත';

  @override
  String get giveItemTitleRequired => 'කරුණාකර නමක් ඇතුළත් කරන්න';

  @override
  String get giveDescription => 'විස්තරය';

  @override
  String get giveDescriptionHint =>
      'අයිතමය, එහි ප්‍රමාණය සහ තත්ත්වය ගැන කියන්න';

  @override
  String get giveDescriptionRequired => 'කරුණාකර කෙටි විස්තරයක් එක් කරන්න';

  @override
  String get giveCategory => 'කාණ්ඩය';

  @override
  String get giveCategoryHint => 'කාණ්ඩයක් තෝරන්න';

  @override
  String get giveCategoryRequired => 'කරුණාකර කාණ්ඩයක් තෝරන්න';

  @override
  String get giveCondition => 'තත්ත්වය';

  @override
  String get giveDistrictHint => 'තෝරන්න';

  @override
  String get giveDistrictRequired => 'දිස්ත්‍රික්කයක් තෝරන්න';

  @override
  String get giveCityHint => 'උදා: මීගමුව';

  @override
  String get giveCityRequired => 'නගරය අවශ්‍යයි';

  @override
  String get givePublish => 'අයිතමය පළ කරන්න';

  @override
  String get givePublished => 'ඔබේ අයිතමය දැන් පළ වී ඇත!';

  @override
  String get requestsSubtitle => 'අයිතමයක් අවශ්‍ය ඔබ අසල සිටින අය';

  @override
  String get requestsNew => 'නව';

  @override
  String get requestsAll => 'සියලු ඉල්ලීම්';

  @override
  String get requestsMine => 'මගේ ඉල්ලීම්';

  @override
  String get requestsICanHelp => 'මට උදව් කළ හැක';

  @override
  String get requestsDelete => 'ඉල්ලීම මකන්න';

  @override
  String get requestsDeleteConfirm => 'මෙම ඉල්ලීම මකන්නද?';

  @override
  String get requestsDeleteMessage =>
      'පරිත්‍යාගශීලීන්ට එය තවදුරටත් නොපෙනේ. මෙය අහෝසි කළ නොහැක.';

  @override
  String get requestsDeleteAction => 'මකන්න';

  @override
  String get requestsDeleted => 'ඉල්ලීම මකා දමන ලදී.';

  @override
  String get postDelete => 'පළකිරීම මකන්න';

  @override
  String get postDeleteConfirm => 'මෙම පළකිරීම මකන්නද?';

  @override
  String get postDeleteMessage =>
      'එය ලැයිස්තුවෙන් ඉවත් කෙරෙන අතර ඒ සඳහා වූ ඉල්ලීම් අවලංගු වේ. මෙය අහෝසි කළ නොහැක.';

  @override
  String get postDeleted => 'පළකිරීම මකා දමන ලදී.';

  @override
  String get statusOpen => 'විවෘතයි';

  @override
  String get statusDonorReviewing => 'පරිත්‍යාගශීලී සලකා බලයි';

  @override
  String get requestTitle => 'අයිතමයක් ඉල්ලන්න';

  @override
  String get requestSubtitle => 'ඔබට අවශ්‍ය දේ ඔබේ ප්‍රජාවෙන් ඉල්ලන්න';

  @override
  String get requestInfoTitle => 'ඔබේ ප්‍රජාව උදව් කිරීමට සූදානම්.';

  @override
  String get requestInfoBody =>
      'පරිත්‍යාගශීලීන් තෝරා ගැනීමට පෙර ඔබේ හේතුව කියවයි, එබැවින් පැහැදිලිව සහ අවංකව ලියන්න.';

  @override
  String get requestYouAreRequesting => 'ඔබ ඉල්ලන්නේ';

  @override
  String get requestItemName => 'අයිතමයේ නම';

  @override
  String get requestItemNameHint => 'උදා: 10 ශ්‍රේණියේ විද්‍යා පෙළපොත';

  @override
  String get requestItemNameRequired => 'කරුණාකර අයිතමයේ නම ඇතුළත් කරන්න';

  @override
  String get requestDescriptionHint =>
      'ඔබට හරියටම අවශ්‍ය කුමක්ද? ප්‍රමාණය, සංස්කරණය හෝ වෙනත් විස්තර';

  @override
  String get requestReason => 'ඔබට එය අවශ්‍ය ඇයි?';

  @override
  String get requestReasonHint =>
      'කෙටි හේතුවක් පරිත්‍යාගශීලීන්ට සාධාරණව තෝරා ගැනීමට උදව් වේ';

  @override
  String get requestReasonHelper =>
      'පරිත්‍යාගශීලීන් ඉල්ලීම් සමාලෝචනය කරන විට පෙන්වයි';

  @override
  String get requestReasonRequired => 'කරුණාකර ඔබට එය අවශ්‍ය ඇයි දැයි කියන්න';

  @override
  String get requestNotes => 'අමතර සටහන්';

  @override
  String get requestOptional => '(අත්‍යවශ්‍ය නැත)';

  @override
  String get requestNotesHint => 'පරිත්‍යාගශීලීන් දැනගත යුතු වෙනත් ඕනෑම දෙයක්';

  @override
  String get requestSubmitted => 'ඔබේ ඉල්ලීම ඉදිරිපත් කර ඇත.';

  @override
  String get profileTitle => 'මගේ පැතිකඩ';

  @override
  String get profileEditProfile => 'පැතිකඩ සංස්කරණය';

  @override
  String get profileItemsGiven => 'දුන් අයිතම';

  @override
  String get profileRating => 'ශ්‍රේණිගත කිරීම';

  @override
  String profileNextBadge(String badge) {
    return 'ඊළඟ ලාංඡනය: $badge';
  }

  @override
  String profileBadgeProgress(int count, int total) {
    return 'අයිතම $totalන් $count';
  }

  @override
  String get profileAllBadgesEarned => 'සියලු ලාංඡන ලැබී ඇත. ස්තූතියි!';

  @override
  String get profileMyActivity => 'මගේ ක්‍රියාකාරකම්';

  @override
  String get profileMyDonations => 'මගේ පරිත්‍යාග';

  @override
  String get profileReviews => 'විචාර';

  @override
  String get profileNotifications => 'දැනුම්දීම්';

  @override
  String get profileNotificationsUnavailable => 'දැනුම්දීම් තවම ලබා ගත නොහැක.';

  @override
  String get profileAdmin => 'පරිපාලක';

  @override
  String get profileManageUsers => 'පරිශීලකයින් කළමනාකරණය';

  @override
  String get profileModeratePosts => 'පළකිරීම් පරීක්ෂාව';

  @override
  String get profileManageCategories => 'කාණ්ඩ කළමනාකරණය';

  @override
  String get profileSignOut => 'ඉවත් වන්න';

  @override
  String get profileSignOutConfirm => 'ShareLoop වෙතින් ඉවත් වන්නද?';

  @override
  String get profileSignOutMessage =>
      'අයිතම දීමට හෝ ඉල්ලීමට නැවත ඇතුල් විය යුතුයි.';

  @override
  String get profileNoRequests => 'ඔබ තවම කිසිදු අයිතමයක් ඉල්ලා නැත.';

  @override
  String get statusAvailable => 'ලබාගත හැකි';

  @override
  String get statusHandoverPending => 'භාරදීම බලාපොරොත්තුවෙන්';

  @override
  String get statusGiven => 'දී ඇත';

  @override
  String get statusPending => 'බලාපොරොත්තුවෙන්';

  @override
  String get statusApproved => 'අනුමතයි';

  @override
  String get statusNotSelected => 'තෝරා නොගත්';

  @override
  String get timeJustNow => 'දැන්';

  @override
  String timeMinutesAgo(int count) {
    return 'මිනි. $countකට පෙර';
  }

  @override
  String timeHoursAgo(int count) {
    return 'පැය $countකට පෙර';
  }

  @override
  String timeDaysAgo(int count) {
    return 'දින $countකට පෙර';
  }

  @override
  String get itemDetailsTitle => 'භාණ්ඩයේ විස්තර';

  @override
  String get itemDetailsAvailable => 'ලබා ගත හැක';

  @override
  String get itemDetailsPendingHandover => 'භාරදීම බලාපොරොත්තුවෙන්';

  @override
  String get itemDetailsGivenAway => 'දී අවසන්';

  @override
  String itemDetailsPosted(String time) {
    return '$time පළ කළා';
  }

  @override
  String itemDetailsItemsGiven(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'භාණ්ඩ $countක් දී ඇත',
      one: 'භාණ්ඩ 1ක් දී ඇත',
    );
    return '$_temp0';
  }

  @override
  String get itemDetailsPrivacyNote =>
      'සම්බන්ධතා විස්තර පෞද්ගලිකව පවතී. පරිත්‍යාගශීලියා සියලු ඉල්ලුම්කරුවන්ගේ හේතු කියවා, තමන් තෝරාගන්නා කෙනා සමඟ පමණක් සම්බන්ධතා විස්තර බෙදා ගනී.';

  @override
  String get itemDetailsRequest => 'මෙම භාණ්ඩය ඉල්ලන්න';

  @override
  String get itemDetailsViewRequests => 'ලැබුණු ඉල්ලීම් බලන්න';

  @override
  String get itemDetailsArrangeHandover => 'භාරදීම සකස් කරන්න';

  @override
  String get itemDetailsUnavailable => 'මෙම භාණ්ඩය තවදුරටත් ලබා ගත නොහැක.';

  @override
  String get itemDetailsClosed => 'මෙම භාණ්ඩය සඳහා තවදුරටත් ඉල්ලීම් කළ නොහැක.';

  @override
  String get itemDetailsShare => 'බෙදාගන්න';

  @override
  String get itemDetailsViewPhoto => 'ඡායාරූපය සම්පූර්ණ තිරයෙන් බලන්න';

  @override
  String itemDetailsShareText(
    String title,
    String district,
    String description,
  ) {
    return '$title ShareLoop හි නොමිලේ ලබා ගත හැක ($district). $description';
  }

  @override
  String get editProfileChangePhoto => 'ඡායාරූපය වෙනස් කරන්න';

  @override
  String get editProfileEmailLocked => 'ඔබේ ඊමේල් ලිපිනය වෙනස් කළ නොහැක';

  @override
  String get editProfilePhoneNote =>
      'පරිත්‍යාගශීලියා ඉල්ලුම්කරුවෙකු තෝරාගත් පසු, ඔබේ දුරකථන අංකය ඔබ හා ගැළපෙන පුද්ගලයා සමඟ පමණක් බෙදා ගනී.';

  @override
  String get editProfilePhoneInvalid => 'වලංගු දුරකථන අංකයක් ඇතුළත් කරන්න';

  @override
  String get editProfileSave => 'වෙනස්කම් සුරකින්න';

  @override
  String get editProfileSaved => 'පැතිකඩ යාවත්කාලීන කළා.';

  @override
  String get editProfileFailed =>
      'ඔබේ පැතිකඩ සුරැකීමට නොහැකි විය. කරුණාකර නැවත උත්සාහ කරන්න.';

  @override
  String get myRequestsSubtitle => 'ඔබ ඉල්ලූ භාණ්ඩ';

  @override
  String get myRequestsEmptyTitle => 'තවම ඉල්ලීම් නැත';

  @override
  String get myRequestsEmptyBody =>
      'යමක් අවශ්‍යද? ඔබේ ප්‍රජාවෙන් ඉල්ලන්න. පරිත්‍යාගශීලීන් තෝරා ගැනීමට පෙර ඔබේ හේතුව කියවයි.';

  @override
  String get myRequestsTipLabel => 'ඉඟිය:';

  @override
  String get myRequestsTip =>
      'කෙටි, අවංක හේතුවක් පරිත්‍යාගශීලීන්ට සාධාරණව තෝරා ගැනීමට උදව් වේ.';

  @override
  String get myRequestsAction => 'භාණ්ඩයක් ඉල්ලන්න';

  @override
  String get myDonationsSubtitle => 'ඔබ දුන් භාණ්ඩ';

  @override
  String get myDonationsEmptyTitle => 'තවම පරිත්‍යාග නැත';

  @override
  String get myDonationsEmptyBody =>
      'ඔබ දෙන භාණ්ඩ මෙහි පෙන්වයි. ඔබේ පළමු පරිත්‍යාගයෙන් ලාංඡන ගමන ආරම්භ වේ.';

  @override
  String myDonationsBadgeTitle(String badge) {
    return '$badge ලාංඡනය';
  }

  @override
  String myDonationsBadgeHint(int count, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$level වීමට භාණ්ඩ $countක් දෙන්න',
      one: '$level වීමට තව භාණ්ඩ 1ක් දෙන්න',
    );
    return '$_temp0';
  }

  @override
  String get myDonationsFirstAction => 'ඔබේ පළමු භාණ්ඩය දෙන්න';

  @override
  String get myDonationsAction => 'භාණ්ඩයක් දෙන්න';

  @override
  String get myReviewsSubtitle => 'අන් අය ඔබ ගැන කියන දේ';

  @override
  String get myReviewsEmptyTitle => 'තවම සමාලෝචන නැත';

  @override
  String get myReviewsEmptyBody =>
      'සෑම හුවමාරුවකටම පසු ඔබට සහ අනෙක් පුද්ගලයාට එකිනෙකා ශ්‍රේණිගත කළ හැක. හොඳ සමාලෝචන විශ්වාසය ගොඩනඟයි.';

  @override
  String get myReviewsFirstTitle => 'ඔබේ පළමු සමාලෝචනය ලබාගන්න';

  @override
  String get myReviewsFirstBody =>
      'ශ්‍රේණිගත කිරීම් විවෘත කිරීමට භාණ්ඩයක් දී හෝ ලබාගෙන භාරදීම සම්පූර්ණ කරන්න.';

  @override
  String get myReviewsAction => 'භාණ්ඩ බලන්න';

  @override
  String myReviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'සමාලෝචන $count',
      one: 'සමාලෝචන 1',
    );
    return '$_temp0';
  }

  @override
  String get onboardingLogIn => 'ඇතුල් වන්න';

  @override
  String get onboardingRegister => 'ලියාපදිංචි වන්න';

  @override
  String get profileNoDonations => 'ඔබ තවම කිසිදු අයිතමයක් දී නැත.';

  @override
  String get profileNoReviews => 'තවම විචාර නැත.';
}
