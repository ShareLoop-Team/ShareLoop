// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'ShareLoop';

  @override
  String get tagline =>
      'உங்களுக்குத் தேவையற்றதைக் கொடுங்கள். உங்களுக்குத் தேவையானதைப் பெறுங்கள்.';

  @override
  String get home => 'முகப்பு';

  @override
  String get profile => 'சுயவிவரம்';

  @override
  String get settings => 'அமைப்புகள்';

  @override
  String get giveAway => 'கொடுங்கள்';

  @override
  String get requests => 'கோரிக்கைகள்';

  @override
  String get login => 'உள்நுழைய';

  @override
  String get register => 'பதிவு செய்ய';

  @override
  String get logout => 'வெளியேறு';

  @override
  String get email => 'மின்னஞ்சல்';

  @override
  String get password => 'கடவுச்சொல்';

  @override
  String get fullName => 'முழு பெயர்';

  @override
  String get phoneNumber => 'தொலைபேசி எண்';

  @override
  String get district => 'மாவட்டம்';

  @override
  String get cityTown => 'நகரம்';

  @override
  String get search => 'பொருட்களைத் தேடு...';

  @override
  String get noItemsAvailable => 'தற்போது பொருட்கள் எதுவும் இல்லை.';

  @override
  String get noOpenRequests => 'தற்போது திறந்த கோரிக்கைகள் இல்லை.';

  @override
  String get myPosts => 'எனது இடுகைகள்';

  @override
  String get myRequests => 'எனது கோரிக்கைகள்';

  @override
  String get reviewsReceived => 'பெறப்பட்ட மதிப்பீடுகள்';

  @override
  String get donations => 'நன்கொடைகள்';

  @override
  String get requestThisItem => 'இந்த பொருளை கோருங்கள்';

  @override
  String get viewIncomingRequests => 'வரும் கோரிக்கைகளைக் காண்க';

  @override
  String get submitRequest => 'கோரிக்கையை சமர்ப்பிக்க';

  @override
  String get publishPost => 'வெளியிடு';

  @override
  String get language => 'மொழி';

  @override
  String get onboardingDescription =>
      'உங்களுக்குத் தேவையில்லாததைக் கொடுங்கள். உங்களுக்குத் தேவையானதைக் கண்டறியுங்கள். இலங்கை முழுவதும் உள்ள உங்கள் சமூகத்துடன் பொருட்களை இலவசமாகப் பகிருங்கள்.';

  @override
  String get onboardingGetStarted => 'தொடங்குவோம்';

  @override
  String get introSkip => 'தவிர்';

  @override
  String get introNext => 'அடுத்து';

  @override
  String get introGiveTitle => 'தேவையில்லாததைக் கொடுங்கள்';

  @override
  String get introGiveBody =>
      'புத்தகங்கள், உடைகள், தளபாடங்கள் மற்றும் பல. அவற்றை வீசாமல் அருகிலுள்ள ஒருவருக்குக் கொடுங்கள்.';

  @override
  String get introShareTitle => 'தேவையானதைப் பெறுங்கள்';

  @override
  String get introShareBody =>
      'உங்கள் சமூகம் பகிரும் இலவசப் பொருட்களைக் கண்டறிந்து, பயனுள்ள பொருட்கள் வீணாவதைத் தடுங்கள்.';

  @override
  String introPageLabel(int current, int total) {
    return '$total இல் பக்கம் $current';
  }

  @override
  String get loginWelcomeBack => 'மீண்டும் வருக';

  @override
  String get loginSubtitle =>
      'உங்கள் விவரங்களை நிரப்புங்கள் அல்லது சமூக ஊடகம் மூலம் தொடருங்கள்';

  @override
  String get loginEmailHint => 'உங்கள் மின்னஞ்சலை உள்ளிடுங்கள்';

  @override
  String get loginPasswordHint => 'கடவுச்சொல்லை உள்ளிடுங்கள்';

  @override
  String get loginEmailRequired => 'மின்னஞ்சல் தேவை';

  @override
  String get loginPasswordRequired => 'கடவுச்சொல் தேவை';

  @override
  String get loginShowPassword => 'கடவுச்சொல்லைக் காட்டு';

  @override
  String get loginHidePassword => 'கடவுச்சொல்லை மறை';

  @override
  String get loginRememberMe => 'என்னை நினைவில் கொள்';

  @override
  String get loginForgotPassword => 'கடவுச்சொல் மறந்துவிட்டதா?';

  @override
  String get loginForgotPasswordUnavailable =>
      'கடவுச்சொல் மீட்டமைப்பு இன்னும் கிடைக்கவில்லை.';

  @override
  String get loginResetEnterEmail =>
      'கடவுச்சொல்லை மீட்டமைக்க மேலே உங்கள் மின்னஞ்சலை உள்ளிடுங்கள்.';

  @override
  String loginResetSent(String email) {
    return '$email க்கு கணக்கு இருந்தால், கடவுச்சொல் மீட்டமைப்பு இணைப்பு அனுப்பப்படும்.';
  }

  @override
  String get loginSignIn => 'உள்நுழைய';

  @override
  String get loginOr => 'அல்லது';

  @override
  String get loginNoAccount => 'புதிய பயனரா?';

  @override
  String get loginCreateAccount => 'கணக்கை உருவாக்கு';

  @override
  String get loginEmailLabel => 'மின்னஞ்சல்';

  @override
  String get loginPasswordLabel => 'கடவுச்சொல்';

  @override
  String get loginOrContinueWith => 'அல்லது இதன் மூலம் தொடருங்கள்';

  @override
  String get loginWithGoogle => 'Google மூலம் உள்நுழை';

  @override
  String get loginWithFacebook => 'Facebook மூலம் உள்நுழை';

  @override
  String get loginSocialUnavailable =>
      'சமூக ஊடக உள்நுழைவு இன்னும் கிடைக்கவில்லை.';

  @override
  String get registerTitle => 'கணக்கை உருவாக்கு';

  @override
  String get registerSubtitle => 'சமூகத்தில் இணைந்து பகிரத் தொடங்குங்கள்';

  @override
  String get registerNameHint => 'உங்கள் முழுப் பெயரை உள்ளிடுங்கள்';

  @override
  String get registerPhoneHint => '07X XXX XXXX';

  @override
  String get registerDistrictHint => 'உங்கள் மாவட்டத்தைத் தேர்ந்தெடுங்கள்';

  @override
  String get registerCityHint => 'எ.கா. நீர்கொழும்பு';

  @override
  String get registerConfirmPasswordHint =>
      'கடவுச்சொல்லை மீண்டும் உள்ளிடுங்கள்';

  @override
  String get registerNameRequired => 'பெயர் தேவை';

  @override
  String get registerPhoneRequired => 'தொலைபேசி எண் தேவை';

  @override
  String get registerDistrictRequired => 'உங்கள் மாவட்டத்தைத் தேர்ந்தெடுங்கள்';

  @override
  String get registerCityRequired => 'நகரம் தேவை';

  @override
  String registerPasswordTooShort(int min) {
    return 'கடவுச்சொல்லில் குறைந்தது $min எழுத்துகள் இருக்க வேண்டும்';
  }

  @override
  String get registerPasswordMismatch => 'கடவுச்சொற்கள் பொருந்தவில்லை';

  @override
  String get registerButton => 'கணக்கை உருவாக்கு';

  @override
  String get registerHaveAccount => 'ஏற்கனவே கணக்கு உள்ளதா?';

  @override
  String get registerSignIn => 'உள்நுழைய';

  @override
  String get registerNameLabel => 'முழுப் பெயர்';

  @override
  String get registerPasswordHint => 'கடவுச்சொல்லை உருவாக்குங்கள்';

  @override
  String get registerConfirmPasswordLabel => 'கடவுச்சொல்லை உறுதிப்படுத்துங்கள்';

  @override
  String get registerPhoneLabel => 'தொலைபேசி எண்';

  @override
  String get registerDistrictLabel => 'மாவட்டம்';

  @override
  String get registerCityLabel => 'நகரம்';

  @override
  String registerAgreeTerms(String terms, String privacy) {
    return '$terms மற்றும் $privacy ஆகியவற்றை ஏற்கிறேன்';
  }

  @override
  String get registerTerms => 'விதிமுறைகள்';

  @override
  String get registerPrivacyPolicy => 'தனியுரிமைக் கொள்கை';

  @override
  String get registerTermsRequired =>
      'விதிமுறைகள் மற்றும் தனியுரிமைக் கொள்கையை ஏற்கவும்';

  @override
  String get registerOrSignUpWith => 'அல்லது இதன் மூலம் பதிவு செய்யுங்கள்';

  @override
  String get registerWithGoogle => 'Google மூலம் பதிவு செய்';

  @override
  String get registerWithFacebook => 'Facebook மூலம் பதிவு செய்';

  @override
  String homeGreeting(String name) {
    return 'வணக்கம், $name. இன்று என்ன பகிர்கிறீர்கள்?';
  }

  @override
  String get homeGreetingGuest => 'வணக்கம்! இன்று என்ன பகிர்கிறீர்கள்?';

  @override
  String get homeSearchHint => 'உங்களுக்குத் தேவையான பொருட்களைத் தேடுங்கள்...';

  @override
  String get homeGiveItemTitle => 'ஒரு பொருளைக் கொடுங்கள்';

  @override
  String get homeGiveItemSubtitle =>
      'உங்களுக்குத் தேவையில்லாததை இலவசமாகக் கொடுங்கள்';

  @override
  String get homeRequestItemTitle => 'ஒரு பொருளைக் கோருங்கள்';

  @override
  String get homeRequestItemSubtitle =>
      'உங்களுக்கு என்ன தேவை என்று சமூகத்திடம் சொல்லுங்கள்';

  @override
  String get homeAllCategories => 'அனைத்தும்';

  @override
  String get homeAvailableNearYou => 'உங்கள் அருகில் கிடைப்பவை';

  @override
  String get homeOpenRequests => 'திறந்த கோரிக்கைகள்';

  @override
  String get homeAllDistricts => 'அனைத்து மாவட்டங்கள்';

  @override
  String get homeChooseDistrict => 'மாவட்டத்தைத் தேர்ந்தெடுங்கள்';

  @override
  String get homeGive => 'கொடு';

  @override
  String homeDonorBadge(String badge) {
    return '$badge நன்கொடையாளர்';
  }

  @override
  String get homeNewDonor => 'புதிய நன்கொடையாளர்';

  @override
  String homeRequestedBy(String name) {
    return 'கோரியவர் $name';
  }

  @override
  String get giveTitle => 'ஒரு பொருளைக் கொடுங்கள்';

  @override
  String get giveSubtitle => 'உங்கள் சமூகத்துடன் பயனுள்ள ஒன்றைப் பகிருங்கள்';

  @override
  String get givePhotos => 'புகைப்படங்கள்';

  @override
  String get giveAddPhotos => 'உங்கள் பொருளின் புகைப்படங்களைச் சேர்க்கவும்';

  @override
  String get giveAddPhotosHint =>
      'தெளிவான புகைப்படங்கள் மற்றவர்கள் விரைவாக முடிவெடுக்க உதவும்';

  @override
  String get giveAddPhoto => 'புகைப்படம் சேர்';

  @override
  String get giveRemovePhoto => 'புகைப்படத்தை நீக்கு';

  @override
  String get giveCover => 'முதன்மை';

  @override
  String get giveTakePhoto => 'புகைப்படம் எடு';

  @override
  String get giveChooseFromGallery => 'கேலரியிலிருந்து தேர்ந்தெடு';

  @override
  String get cameraCapture => 'புகைப்படம் எடு';

  @override
  String get cameraSwitch => 'கேமராவை மாற்று';

  @override
  String get cameraRetake => 'மீண்டும் எடு';

  @override
  String get cameraUsePhoto => 'படத்தைப் பயன்படுத்து';

  @override
  String get cameraNotFound => 'இந்தச் சாதனத்தில் கேமரா இல்லை.';

  @override
  String get cameraPermissionDenied =>
      'கேமரா அணுகல் தடுக்கப்பட்டுள்ளது. உங்கள் உலாவி அல்லது கணினி அமைப்புகளில் அனுமதித்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get cameraFailed =>
      'கேமராவைத் தொடங்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get giveItemTitle => 'பொருளின் தலைப்பு';

  @override
  String get giveItemTitleHint => 'எ.கா. தரம் 10 அறிவியல் பாடநூல்';

  @override
  String get giveItemTitleRequired => 'தலைப்பை உள்ளிடுங்கள்';

  @override
  String get giveDescription => 'விவரம்';

  @override
  String get giveDescriptionHint =>
      'பொருள், அதன் அளவு மற்றும் தேய்மானம் பற்றிச் சொல்லுங்கள்';

  @override
  String get giveDescriptionRequired => 'சிறு விவரத்தைச் சேர்க்கவும்';

  @override
  String get giveCategory => 'வகை';

  @override
  String get giveCategoryHint => 'வகையைத் தேர்ந்தெடுங்கள்';

  @override
  String get giveCategoryRequired => 'வகையைத் தேர்ந்தெடுங்கள்';

  @override
  String get giveCondition => 'நிலை';

  @override
  String get giveDistrictHint => 'தேர்ந்தெடு';

  @override
  String get giveDistrictRequired => 'மாவட்டத்தைத் தேர்ந்தெடுங்கள்';

  @override
  String get giveCityHint => 'எ.கா. நீர்கொழும்பு';

  @override
  String get giveCityRequired => 'நகரம் தேவை';

  @override
  String get givePublish => 'பொருளை வெளியிடு';

  @override
  String get givePublished => 'உங்கள் பொருள் இப்போது வெளியிடப்பட்டது!';

  @override
  String get requestsSubtitle => 'உங்கள் அருகில் பொருள் தேவைப்படுபவர்கள்';

  @override
  String get requestsNew => 'புதிய';

  @override
  String get requestsAll => 'அனைத்து கோரிக்கைகள்';

  @override
  String get requestsMine => 'எனது கோரிக்கைகள்';

  @override
  String get requestsICanHelp => 'நான் உதவுகிறேன்';

  @override
  String get requestsDelete => 'கோரிக்கையை நீக்கு';

  @override
  String get requestsDeleteConfirm => 'இந்தக் கோரிக்கையை நீக்கவா?';

  @override
  String get requestsDeleteMessage =>
      'நன்கொடையாளர்களுக்கு இது இனி தெரியாது. இதைச் செயல்தவிர்க்க முடியாது.';

  @override
  String get requestsDeleteAction => 'நீக்கு';

  @override
  String get requestsDeleted => 'கோரிக்கை நீக்கப்பட்டது.';

  @override
  String get postDelete => 'இடுகையை நீக்கு';

  @override
  String get postDeleteConfirm => 'இந்த இடுகையை நீக்கவா?';

  @override
  String get postDeleteMessage =>
      'இது பட்டியலிலிருந்து அகற்றப்படும், இதற்கான கோரிக்கைகள் ரத்து செய்யப்படும். இதைச் செயல்தவிர்க்க முடியாது.';

  @override
  String get postDeleted => 'இடுகை நீக்கப்பட்டது.';

  @override
  String get statusOpen => 'திறந்துள்ளது';

  @override
  String get statusDonorReviewing => 'நன்கொடையாளர் பரிசீலிக்கிறார்';

  @override
  String get requestTitle => 'ஒரு பொருளைக் கோருங்கள்';

  @override
  String get requestSubtitle =>
      'உங்களுக்குத் தேவையானதை உங்கள் சமூகத்திடம் கேளுங்கள்';

  @override
  String get requestInfoTitle => 'உங்கள் சமூகம் உதவத் தயாராக உள்ளது.';

  @override
  String get requestInfoBody =>
      'நன்கொடையாளர்கள் தேர்வு செய்வதற்கு முன் உங்கள் காரணத்தைப் படிப்பார்கள், எனவே தெளிவாகவும் நேர்மையாகவும் எழுதுங்கள்.';

  @override
  String get requestYouAreRequesting => 'நீங்கள் கோருவது';

  @override
  String get requestItemName => 'பொருளின் பெயர்';

  @override
  String get requestItemNameHint => 'எ.கா. தரம் 10 அறிவியல் பாடநூல்';

  @override
  String get requestItemNameRequired => 'பொருளின் பெயரை உள்ளிடுங்கள்';

  @override
  String get requestDescriptionHint =>
      'உங்களுக்கு சரியாக என்ன தேவை? அளவு, பதிப்பு அல்லது பிற விவரங்கள்';

  @override
  String get requestReason => 'இது ஏன் தேவை?';

  @override
  String get requestReasonHint =>
      'சுருக்கமான காரணம் நன்கொடையாளர்கள் நியாயமாகத் தேர்வு செய்ய உதவும்';

  @override
  String get requestReasonHelper =>
      'கோரிக்கைகளை மதிப்பாய்வு செய்யும்போது நன்கொடையாளர்களுக்குக் காட்டப்படும்';

  @override
  String get requestReasonRequired =>
      'இது ஏன் தேவை என்று நன்கொடையாளர்களிடம் சொல்லுங்கள்';

  @override
  String get requestNotes => 'கூடுதல் குறிப்புகள்';

  @override
  String get requestOptional => '(விருப்பத்தேர்வு)';

  @override
  String get requestNotesHint => 'நன்கொடையாளர்கள் அறிய வேண்டிய வேறு ஏதேனும்';

  @override
  String get requestSubmitted => 'உங்கள் கோரிக்கை சமர்ப்பிக்கப்பட்டது.';

  @override
  String get profileTitle => 'எனது சுயவிவரம்';

  @override
  String get profileEditProfile => 'சுயவிவரத்தைத் திருத்து';

  @override
  String get profileItemsGiven => 'கொடுத்தவை';

  @override
  String get profileRating => 'மதிப்பீடு';

  @override
  String profileNextBadge(String badge) {
    return 'அடுத்த பதக்கம்: $badge';
  }

  @override
  String profileBadgeProgress(int count, int total) {
    return '$total இல் $count பொருட்கள்';
  }

  @override
  String get profileAllBadgesEarned =>
      'அனைத்து பதக்கங்களும் பெறப்பட்டன. நன்றி!';

  @override
  String get profileMyActivity => 'எனது செயல்பாடு';

  @override
  String get profileMyDonations => 'எனது நன்கொடைகள்';

  @override
  String get profileReviews => 'மதிப்புரைகள்';

  @override
  String get profileNotifications => 'அறிவிப்புகள்';

  @override
  String get profileNotificationsUnavailable =>
      'அறிவிப்புகள் இன்னும் கிடைக்கவில்லை.';

  @override
  String get profileAdmin => 'நிர்வாகம்';

  @override
  String get profileManageUsers => 'பயனர்களை நிர்வகி';

  @override
  String get profileModeratePosts => 'இடுகைகளை மதிப்பாய்வு செய்';

  @override
  String get profileManageCategories => 'வகைகளை நிர்வகி';

  @override
  String get profileSignOut => 'வெளியேறு';

  @override
  String get profileSignOutConfirm => 'ShareLoop இலிருந்து வெளியேறவா?';

  @override
  String get profileSignOutMessage =>
      'பொருட்களைக் கொடுக்க அல்லது கோர மீண்டும் உள்நுழைய வேண்டும்.';

  @override
  String get profileNoRequests =>
      'நீங்கள் இன்னும் எந்தப் பொருளையும் கோரவில்லை.';

  @override
  String get statusAvailable => 'கிடைக்கிறது';

  @override
  String get statusHandoverPending => 'ஒப்படைப்பு நிலுவையில்';

  @override
  String get statusGiven => 'கொடுக்கப்பட்டது';

  @override
  String get statusPending => 'நிலுவையில்';

  @override
  String get statusApproved => 'அங்கீகரிக்கப்பட்டது';

  @override
  String get statusNotSelected => 'தேர்ந்தெடுக்கப்படவில்லை';

  @override
  String get timeJustNow => 'இப்போது';

  @override
  String timeMinutesAgo(int count) {
    return '$count நிமி. முன்';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count மணி. முன்';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count நாள் முன்';
  }

  @override
  String get itemDetailsTitle => 'பொருள் விவரங்கள்';

  @override
  String get itemDetailsAvailable => 'கிடைக்கிறது';

  @override
  String get itemDetailsPendingHandover => 'ஒப்படைப்பு நிலுவையில்';

  @override
  String get itemDetailsGivenAway => 'கொடுக்கப்பட்டது';

  @override
  String itemDetailsPosted(String time) {
    return '$time பதிவிடப்பட்டது';
  }

  @override
  String itemDetailsItemsGiven(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count பொருட்கள் கொடுக்கப்பட்டன',
      one: '1 பொருள் கொடுக்கப்பட்டது',
    );
    return '$_temp0';
  }

  @override
  String get itemDetailsPrivacyNote =>
      'தொடர்பு விவரங்கள் தனிப்பட்டவையாக இருக்கும். நன்கொடையாளர் அனைத்து கோரிக்கையாளர்களின் காரணங்களையும் படித்து, தாம் தேர்ந்தெடுக்கும் ஒருவருடன் மட்டுமே தொடர்பு விவரங்களைப் பகிர்வார்.';

  @override
  String get itemDetailsRequest => 'இந்தப் பொருளைக் கோருங்கள்';

  @override
  String get itemDetailsViewRequests => 'வந்த கோரிக்கைகளைப் பார்';

  @override
  String get itemDetailsArrangeHandover => 'ஒப்படைப்பை ஏற்பாடு செய்';

  @override
  String get itemDetailsUnavailable => 'இந்தப் பொருள் இனி கிடைக்காது.';

  @override
  String get itemDetailsClosed =>
      'இந்தப் பொருளுக்கு இனி கோரிக்கைகள் ஏற்கப்படாது.';

  @override
  String get itemDetailsShare => 'பகிர்';

  @override
  String get itemDetailsViewPhoto => 'புகைப்படத்தை முழுத் திரையில் பார்';

  @override
  String itemDetailsShareText(
    String title,
    String district,
    String description,
  ) {
    return '$title ShareLoop இல் இலவசமாகக் கிடைக்கிறது ($district). $description';
  }

  @override
  String get editProfileChangePhoto => 'புகைப்படத்தை மாற்று';

  @override
  String get editProfileEmailLocked => 'உங்கள் மின்னஞ்சலை மாற்ற முடியாது';

  @override
  String get editProfilePhoneNote =>
      'நன்கொடையாளர் கோரிக்கையாளரைத் தேர்ந்தெடுத்த பிறகு, உங்கள் தொலைபேசி எண் உங்களுடன் பொருந்திய நபருடன் மட்டுமே பகிரப்படும்.';

  @override
  String get editProfilePhoneInvalid => 'சரியான தொலைபேசி எண்ணை உள்ளிடுங்கள்';

  @override
  String get editProfileSave => 'மாற்றங்களைச் சேமி';

  @override
  String get editProfileSaved => 'சுயவிவரம் புதுப்பிக்கப்பட்டது.';

  @override
  String get editProfileFailed =>
      'உங்கள் சுயவிவரத்தைச் சேமிக்க முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String get myRequestsSubtitle => 'நீங்கள் கேட்ட பொருட்கள்';

  @override
  String get myRequestsEmptyTitle => 'இதுவரை கோரிக்கைகள் இல்லை';

  @override
  String get myRequestsEmptyBody =>
      'ஏதாவது தேவையா? உங்கள் சமூகத்திடம் கேளுங்கள். நன்கொடையாளர்கள் தேர்ந்தெடுக்கும் முன் உங்கள் காரணத்தைப் படிப்பார்கள்.';

  @override
  String get myRequestsTipLabel => 'குறிப்பு:';

  @override
  String get myRequestsTip =>
      'சுருக்கமான, நேர்மையான காரணம் நன்கொடையாளர்கள் நியாயமாகத் தேர்ந்தெடுக்க உதவும்.';

  @override
  String get myRequestsAction => 'ஒரு பொருளைக் கோருங்கள்';

  @override
  String get myDonationsSubtitle => 'நீங்கள் கொடுத்த பொருட்கள்';

  @override
  String get myDonationsEmptyTitle => 'இதுவரை நன்கொடைகள் இல்லை';

  @override
  String get myDonationsEmptyBody =>
      'நீங்கள் கொடுக்கும் பொருட்கள் இங்கே தோன்றும். உங்கள் முதல் நன்கொடையுடன் பதக்கப் பயணம் தொடங்கும்.';

  @override
  String myDonationsBadgeTitle(String badge) {
    return '$badge பதக்கம்';
  }

  @override
  String myDonationsBadgeHint(int count, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$level ஆக $count பொருட்களைக் கொடுங்கள்',
      one: '$level ஆக இன்னும் 1 பொருளைக் கொடுங்கள்',
    );
    return '$_temp0';
  }

  @override
  String get myDonationsFirstAction => 'உங்கள் முதல் பொருளைக் கொடுங்கள்';

  @override
  String get myDonationsAction => 'ஒரு பொருளைக் கொடுங்கள்';

  @override
  String get myReviewsSubtitle => 'மற்றவர்கள் உங்களைப் பற்றிச் சொல்வது';

  @override
  String get myReviewsEmptyTitle => 'இதுவரை மதிப்புரைகள் இல்லை';

  @override
  String get myReviewsEmptyBody =>
      'ஒவ்வொரு பரிமாற்றத்திற்குப் பிறகும், நீங்களும் மற்றவரும் ஒருவரை ஒருவர் மதிப்பிடலாம். நல்ல மதிப்புரைகள் நம்பிக்கையை வளர்க்கும்.';

  @override
  String get myReviewsFirstTitle => 'உங்கள் முதல் மதிப்புரையைப் பெறுங்கள்';

  @override
  String get myReviewsFirstBody =>
      'மதிப்பீடுகளைத் திறக்க, ஒரு பொருளைக் கொடுத்து அல்லது பெற்று ஒப்படைப்பை முடிக்கவும்.';

  @override
  String get myReviewsAction => 'பொருட்களைப் பாருங்கள்';

  @override
  String myReviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count மதிப்புரைகள்',
      one: '1 மதிப்புரை',
    );
    return '$_temp0';
  }
}
