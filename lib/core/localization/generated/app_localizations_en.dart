// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ShareLoop';

  @override
  String get home => 'Home';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get requests => 'Requests';

  @override
  String get login => 'Log In';

  @override
  String get register => 'Register';

  @override
  String get logout => 'Log Out';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get district => 'District';

  @override
  String get cityTown => 'City / Town';

  @override
  String get search => 'Search items...';

  @override
  String get noItemsAvailable => 'No items available right now.';

  @override
  String get noOpenRequests => 'No open requests right now.';

  @override
  String get myPosts => 'My Posts';

  @override
  String get myRequests => 'My Requests';

  @override
  String get submitRequest => 'Submit Request';

  @override
  String get language => 'Language';

  @override
  String get onboardingDescription =>
      'Give what you no longer need. Find what you do. Share items for free with your community across Sri Lanka.';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get introSkip => 'Skip';

  @override
  String get introNext => 'Next';

  @override
  String get introGiveTitle => 'Give what you don\'t need';

  @override
  String get introGiveBody =>
      'Books, clothes, furniture and more. Pass them on to someone nearby instead of throwing them away.';

  @override
  String get introShareTitle => 'Get what you do';

  @override
  String get introShareBody =>
      'Find free items shared by your community and help keep useful things out of landfill.';

  @override
  String introPageLabel(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get loginWelcomeBack => 'Welcome back!';

  @override
  String get loginEmailHint => 'Enter your Email';

  @override
  String get loginPasswordHint => 'Enter Password';

  @override
  String get loginEmailRequired => 'Email is required';

  @override
  String get loginPasswordRequired => 'Password is required';

  @override
  String get loginShowPassword => 'Show password';

  @override
  String get loginHidePassword => 'Hide password';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginForgotPasswordUnavailable =>
      'Password reset isn\'t available yet.';

  @override
  String get loginResetEnterEmail =>
      'Enter your email above to reset your password.';

  @override
  String loginResetSent(String email) {
    return 'If an account exists for $email, a password reset link is on its way.';
  }

  @override
  String get loginSignIn => 'Sign In';

  @override
  String get loginNoAccount => 'New user?';

  @override
  String get loginCreateAccount => 'Create Account';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginOrContinueWith => 'or continue with';

  @override
  String get loginWithGoogle => 'Sign in with Google';

  @override
  String get loginWithFacebook => 'Sign in with Facebook';

  @override
  String get loginSocialUnavailable => 'Social sign-in isn\'t available yet.';

  @override
  String get registerTitle => 'Create account';

  @override
  String get registerSubtitle => 'Join the community and start sharing';

  @override
  String get registerNameHint => 'Enter your full name';

  @override
  String get registerPhoneHint => '07X XXX XXXX';

  @override
  String get registerDistrictHint => 'Select your district';

  @override
  String get registerConfirmPasswordHint => 'Re-enter your password';

  @override
  String get registerNameRequired => 'Name is required';

  @override
  String get registerPhoneRequired => 'Phone number is required';

  @override
  String get registerDistrictRequired => 'Please select your district';

  @override
  String get registerCityRequired => 'City / town is required';

  @override
  String registerPasswordTooShort(int min) {
    return 'Password must be at least $min characters';
  }

  @override
  String get registerPasswordMismatch => 'Passwords do not match';

  @override
  String get registerButton => 'Create Account';

  @override
  String get registerHaveAccount => 'Already have an account?';

  @override
  String get registerSignIn => 'Sign In';

  @override
  String get registerNameLabel => 'Full name';

  @override
  String get registerPasswordHint => 'Create a password';

  @override
  String get registerConfirmPasswordLabel => 'Confirm password';

  @override
  String get registerPhoneLabel => 'Phone number';

  @override
  String get registerDistrictLabel => 'District';

  @override
  String get registerCityLabel => 'City / Town';

  @override
  String registerAgreeTerms(String terms, String privacy) {
    return 'I agree to the $terms and $privacy';
  }

  @override
  String get registerTerms => 'Terms';

  @override
  String get registerPrivacyPolicy => 'Privacy Policy';

  @override
  String get registerTermsRequired =>
      'Please accept the Terms and Privacy Policy';

  @override
  String get registerOrSignUpWith => 'or sign up with';

  @override
  String get registerWithGoogle => 'Sign up with Google';

  @override
  String get registerWithFacebook => 'Sign up with Facebook';

  @override
  String get homeSearchHint => 'Find items you need...';

  @override
  String get homeAllCategories => 'All';

  @override
  String get homeAvailableNearYou => 'Available near you';

  @override
  String get homeChooseDistrict => 'Choose a district';

  @override
  String get homeChooseCity => 'Choose your city';

  @override
  String get homeSelectCity => 'Select city';

  @override
  String get homeAllAreas => 'All areas';

  @override
  String get homeChangeDistrict => 'Change';

  @override
  String homeCityDistrict(String district) {
    return 'District: $district';
  }

  @override
  String get locationCityHint => 'Select your city or town';

  @override
  String get locationCityNeedsDistrict => 'Select a district first';

  @override
  String get locationUseMine => 'Use my location';

  @override
  String get locationDetecting => 'Finding your location…';

  @override
  String get locationExplainTitle => 'Use your location?';

  @override
  String get locationExplainBody =>
      'ShareLoop reads your location once to find your district and city. It isn\'t tracked in the background or shared with anyone.';

  @override
  String get locationExplainContinue => 'Continue';

  @override
  String get locationNotNow => 'Not now';

  @override
  String locationDetected(String city, String district) {
    return 'Location set to $city, $district.';
  }

  @override
  String locationFilled(String city, String district) {
    return 'Found $city, $district. Tap Save Changes to keep it.';
  }

  @override
  String locationDistrictOnly(String district) {
    return 'You\'re in $district district. Please choose your city.';
  }

  @override
  String get locationOpenSettings => 'Settings';

  @override
  String get locationErrorUnsupported =>
      'Finding your location works in the ShareLoop app on Android and iPhone. Please choose your district and city.';

  @override
  String get locationErrorServiceDisabled =>
      'Location services are turned off. Turn them on, or choose your city.';

  @override
  String get locationErrorDenied =>
      'Location permission wasn\'t given. You can choose your city instead.';

  @override
  String get locationErrorBlocked =>
      'Location access is blocked for ShareLoop. Allow it in Settings, or choose your city.';

  @override
  String get locationErrorTimeout =>
      'Finding your location took too long. Try again, or choose your city.';

  @override
  String get locationErrorInaccurate =>
      'Your location isn\'t precise enough. Turn on precise location, or choose your city.';

  @override
  String get locationErrorOutside =>
      'You seem to be outside Sri Lanka. Please choose your district and city.';

  @override
  String get locationErrorNotMatched =>
      'We couldn\'t match your location to a district. Please choose it yourself.';

  @override
  String get locationErrorFailed =>
      'Couldn\'t find your location. Try again, or choose your city.';

  @override
  String get locationErrorLookup =>
      'Couldn\'t look up your area. Check your internet connection, or choose your city.';

  @override
  String get homeGive => 'Give';

  @override
  String homeDonorBadge(String badge) {
    return '$badge donor';
  }

  @override
  String get homeNewDonor => 'New donor';

  @override
  String get categoryEducationalBooks => 'Educational Books';

  @override
  String get categorySchoolSupplies => 'School Supplies';

  @override
  String get categoryClothes => 'Clothes';

  @override
  String get categoryShoes => 'Shoes';

  @override
  String get categoryElectronics => 'Electronics';

  @override
  String get categoryHouseholdItems => 'Household Items';

  @override
  String get categoryOther => 'Other';

  @override
  String get conditionNew => 'New';

  @override
  String get conditionGood => 'Good';

  @override
  String get conditionUsed => 'Used';

  @override
  String get badgeBronze => 'Bronze';

  @override
  String get badgeSilver => 'Silver';

  @override
  String get badgeGold => 'Gold';

  @override
  String get badgePlatinum => 'Platinum';

  @override
  String get badgeLevelNew => 'New Contributor';

  @override
  String get badgeLevelActive => 'Active Contributor';

  @override
  String get badgeLevelTrusted => 'Trusted Contributor';

  @override
  String get badgeLevelChampion => 'Community Champion';

  @override
  String get navRequests => 'Requests';

  @override
  String get giveTitle => 'Give an Item';

  @override
  String get giveSubtitle => 'Share something useful with your community';

  @override
  String get givePhotos => 'Photos';

  @override
  String get giveAddPhotos => 'Add photos of your item';

  @override
  String get givePhotosItemOnly =>
      'Photograph the item only, with no people, hands or faces';

  @override
  String get photoChecking => 'Checking photo…';

  @override
  String get photoHasPerson =>
      'This photo contains a person or a visible body part. Please upload a photo of the item only.';

  @override
  String get photoCheckFailed =>
      'We couldn\'t check this photo, so it wasn\'t added. Please try again or choose another photo.';

  @override
  String get photoCheckUnsupported =>
      'Photos can\'t be checked on this device, so they can\'t be added here. Please use the phone app or a web browser.';

  @override
  String get giveAddPhoto => 'Add photo';

  @override
  String get giveRemovePhoto => 'Remove photo';

  @override
  String get giveCover => 'Cover';

  @override
  String get giveTakePhoto => 'Take a photo';

  @override
  String get giveChooseFromGallery => 'Choose from gallery';

  @override
  String get cameraCapture => 'Take photo';

  @override
  String get cameraSwitch => 'Switch camera';

  @override
  String get cameraRetake => 'Retake';

  @override
  String get cameraUsePhoto => 'Use photo';

  @override
  String get cameraNotFound => 'No camera found on this device.';

  @override
  String get cameraPermissionDenied =>
      'Camera access is blocked. Allow it in your browser or system settings, then try again.';

  @override
  String get cameraFailed => 'Couldn\'t start the camera. Please try again.';

  @override
  String get cropTitle => 'Adjust photo';

  @override
  String get cropHint =>
      'Drag to move. Pinch, scroll or use the slider to zoom.';

  @override
  String get cropZoom => 'Zoom';

  @override
  String get giveItemTitle => 'Item title';

  @override
  String get giveItemTitleHint => 'e.g. Grade 10 Science Textbook';

  @override
  String get giveItemTitleRequired => 'Please enter a title';

  @override
  String get giveDescription => 'Description';

  @override
  String get giveDescriptionHint =>
      'Tell others about the item, its size, and any wear';

  @override
  String get giveDescriptionRequired => 'Please add a short description';

  @override
  String get giveCategory => 'Category';

  @override
  String get giveCategoryHint => 'Select a category';

  @override
  String get giveCategoryRequired => 'Please select a category';

  @override
  String get giveCondition => 'Condition';

  @override
  String get giveDistrictHint => 'Select';

  @override
  String get giveDistrictRequired => 'Select a district';

  @override
  String get giveCityHint => 'e.g. Negombo';

  @override
  String get giveCityRequired => 'Enter a city';

  @override
  String get givePublish => 'Publish Item';

  @override
  String get givePublished => 'Your item is now live!';

  @override
  String get requestsSubtitle => 'People near you who need an item';

  @override
  String get requestsNew => 'New';

  @override
  String get requestsAll => 'All requests';

  @override
  String get requestsMine => 'My requests';

  @override
  String get requestsICanHelp => 'I can help';

  @override
  String get requestsDelete => 'Delete request';

  @override
  String get requestsEdit => 'Edit request';

  @override
  String get requestsDeleteConfirm => 'Delete this request?';

  @override
  String get requestsDeleteMessage =>
      'Donors will no longer see it. This can\'t be undone.';

  @override
  String get requestsDeleteAction => 'Delete';

  @override
  String get requestsDeleted => 'Request deleted.';

  @override
  String get postDelete => 'Delete post';

  @override
  String get postDeleteConfirm => 'Delete this post?';

  @override
  String get postDeleteMessage =>
      'It will be removed from the feed and any requests for it will be cancelled. This can\'t be undone.';

  @override
  String get postDeleted => 'Post deleted.';

  @override
  String get statusOpen => 'Open';

  @override
  String get statusDonorReviewing => 'Donor reviewing';

  @override
  String get requestTitle => 'Request an Item';

  @override
  String get requestSubtitle => 'Ask your community for what you need';

  @override
  String get requestInfoTitle => 'Your community is here to help.';

  @override
  String get requestInfoBody =>
      'Donors read your reason before choosing, so be clear and honest.';

  @override
  String get requestYouAreRequesting => 'You\'re requesting';

  @override
  String get requestItemName => 'Item name';

  @override
  String get requestItemNameHint => 'e.g. Grade 10 Science Textbook';

  @override
  String get requestItemNameRequired => 'Please enter the item name';

  @override
  String get requestDescriptionHint =>
      'What exactly do you need? Size, edition, or any details';

  @override
  String get requestReason => 'Why do you need it?';

  @override
  String get requestReasonHint => 'A short reason helps donors choose fairly';

  @override
  String get requestReasonHelper => 'Shown to donors when they review requests';

  @override
  String get requestReasonRequired => 'Please tell donors why you need it';

  @override
  String get requestNotes => 'Additional notes';

  @override
  String get requestOptional => '(optional)';

  @override
  String get requestNotesHint => 'Anything else donors should know';

  @override
  String get requestSubmitted => 'Your request has been submitted.';

  @override
  String get requestUpdated => 'Your request has been updated.';

  @override
  String get requestEditTitle => 'Edit Request';

  @override
  String get requestEditSubtitle => 'Update what donors see about your request';

  @override
  String get profileTitle => 'My Profile';

  @override
  String get profileEditProfile => 'Edit Profile';

  @override
  String get profileItemsGiven => 'Items given';

  @override
  String get profileRating => 'Rating';

  @override
  String profileNextBadge(String badge) {
    return 'Next badge: $badge';
  }

  @override
  String profileBadgeProgress(int count, int total) {
    return '$count of $total items';
  }

  @override
  String get profileAllBadgesEarned => 'Every badge earned. Thank you!';

  @override
  String get profileMyActivity => 'My activity';

  @override
  String get profileMyDonations => 'My Donations';

  @override
  String get profileReviews => 'Reviews';

  @override
  String get profileNotifications => 'Notifications';

  @override
  String get profileNotificationsUnavailable =>
      'Notifications aren\'t available yet.';

  @override
  String get notifPromptTitle => 'Allow ShareLoop to send you notifications?';

  @override
  String get notifPromptBody =>
      'Stay updated on item requests, responses, and exchange updates.';

  @override
  String get notifPromptAllow => 'Allow Notifications';

  @override
  String get notifPromptLater => 'Maybe Later';

  @override
  String get notifEnabled => 'Notifications are on.';

  @override
  String get notifDenied =>
      'Notifications are off. You can turn them on any time from Profile → Notifications.';

  @override
  String get notifBlocked =>
      'Notifications are blocked for ShareLoop. Turn them on in your phone\'s settings.';

  @override
  String get notifBlockedBrowser =>
      'Notifications are blocked for ShareLoop in this browser. Allow them from the site settings next to the address bar.';

  @override
  String get notifOpenSettings => 'Open settings';

  @override
  String get stateRetry => 'Try again';

  @override
  String get stateNoMatches => 'Nothing matches your search or filters.';

  @override
  String get stateClearFilters => 'Clear filters';

  @override
  String get searchClear => 'Clear search';

  @override
  String get discardTitle => 'Discard changes?';

  @override
  String get discardMessage => 'What you\'ve entered will be lost.';

  @override
  String get discardAction => 'Discard';

  @override
  String get profileAdmin => 'Admin';

  @override
  String get profileManageUsers => 'Manage users';

  @override
  String get profileModeratePosts => 'Moderate posts';

  @override
  String get profileManageCategories => 'Manage categories';

  @override
  String get profileSignOut => 'Sign Out';

  @override
  String get profileSignOutConfirm => 'Sign out of ShareLoop?';

  @override
  String get profileSignOutMessage =>
      'You\'ll need to log in again to give or request items.';

  @override
  String get profileNoRequests => 'You haven\'t requested any items yet.';

  @override
  String get statusAvailable => 'Available';

  @override
  String get statusHandoverPending => 'Handover pending';

  @override
  String get statusGiven => 'Given';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusNotSelected => 'Not selected';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get itemDetailsTitle => 'Item details';

  @override
  String get itemDetailsAvailable => 'Available';

  @override
  String get itemDetailsPendingHandover => 'Handover pending';

  @override
  String get itemDetailsGivenAway => 'Given away';

  @override
  String itemDetailsPosted(String time) {
    return 'Posted $time';
  }

  @override
  String itemDetailsItemsGiven(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items given',
      one: '1 item given',
    );
    return '$_temp0';
  }

  @override
  String get itemDetailsPrivacyNote =>
      'Contact details stay private. The donor reads the reasons of all requesters and shares contact details only with the one they select.';

  @override
  String get itemDetailsRequest => 'Request this item';

  @override
  String get itemDetailsViewRequests => 'View incoming requests';

  @override
  String get itemDetailsArrangeHandover => 'Arrange handover';

  @override
  String get itemDetailsUnavailable => 'This item is no longer available.';

  @override
  String get itemDetailsClosed =>
      'This item is no longer available for requests.';

  @override
  String get itemDetailsEdit => 'Edit item';

  @override
  String get itemDetailsViewPhoto => 'View photo full screen';

  @override
  String get giveEditTitle => 'Edit your item';

  @override
  String get giveEditSubtitle => 'Update what people see about this item';

  @override
  String get postUpdated => 'Item updated.';

  @override
  String get editProfileChangePhoto => 'Change photo';

  @override
  String get editProfileEmailLocked => 'Your email cannot be changed';

  @override
  String get editProfilePhoneNote =>
      'Your phone number is shared only with the person you are matched with, after the donor selects a requester.';

  @override
  String get editProfilePhoneInvalid => 'Enter a valid phone number';

  @override
  String get editProfileSave => 'Save Changes';

  @override
  String get editProfileSaved => 'Profile updated.';

  @override
  String get editProfileFailed =>
      'Couldn\'t save your profile. Please try again.';

  @override
  String get myRequestsSubtitle => 'Items you have asked for';

  @override
  String get myRequestsEmptyTitle => 'No requests yet';

  @override
  String get myRequestsEmptyBody =>
      'Need something? Ask your community. Donors read your reason before they choose.';

  @override
  String get myRequestsTipLabel => 'Tip:';

  @override
  String get myRequestsTip =>
      'a short, honest reason helps donors choose fairly.';

  @override
  String get myRequestsAction => 'Request an item';

  @override
  String get myDonationsSubtitle => 'Items you have given away';

  @override
  String get myDonationsEmptyTitle => 'No donations yet';

  @override
  String get myDonationsEmptyBody =>
      'Items you give away will show up here. Your first donation starts your badge journey.';

  @override
  String myDonationsBadgeTitle(String badge) {
    return '$badge badge';
  }

  @override
  String myDonationsBadgeHint(int count, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Give $count items to become a $level',
      one: 'Give 1 more item to become a $level',
    );
    return '$_temp0';
  }

  @override
  String get myDonationsFirstAction => 'Give your first item';

  @override
  String get myDonationsAction => 'Give an item';

  @override
  String get myReviewsSubtitle => 'What others say about you';

  @override
  String get myReviewsEmptyTitle => 'No reviews yet';

  @override
  String get myReviewsEmptyBody =>
      'After each exchange, you and the other person can rate each other. Good reviews build trust.';

  @override
  String get myReviewsFirstTitle => 'Get your first review';

  @override
  String get myReviewsFirstBody =>
      'Give or receive an item and complete the handover to unlock ratings.';

  @override
  String get myReviewsAction => 'Browse items';

  @override
  String get profileMyExchanges => 'My exchanges';

  @override
  String get myExchangesSubtitle => 'Handovers you are part of';

  @override
  String get myExchangesEmptyTitle => 'No exchanges yet';

  @override
  String get myExchangesEmptyBody =>
      'When a donor and requester are matched, the handover will appear here. It is marked complete only after both people confirm.';

  @override
  String get myExchangesUnknownItem => 'Shared item';

  @override
  String get myExchangesDonor => 'Donor';

  @override
  String get myExchangesRequester => 'Requester';

  @override
  String get myExchangesPending => 'Handover in progress';

  @override
  String get myExchangesCompleted => 'Completed';

  @override
  String get myExchangesCancelled => 'Cancelled';

  @override
  String get myExchangesDonorConfirmation => 'Donor confirmation';

  @override
  String get myExchangesRequesterConfirmation => 'Requester confirmation';

  @override
  String get myExchangesBothConfirmed => 'Both people confirmed this handover.';

  @override
  String myExchangesYouAnd(String name) {
    return 'You are the donor · requester: $name';
  }

  @override
  String myExchangesWith(String name) {
    return 'You are the requester · donor: $name';
  }

  @override
  String myReviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String get loginWithEmailCode => 'Sign in with an email code instead';

  @override
  String get loginCodeEnterEmail =>
      'Enter your email above to get a sign-in code.';

  @override
  String get verifyTitleRegister => 'Confirm your email';

  @override
  String get verifyTitleLogin => 'Sign in with a code';

  @override
  String get verifyTitleReset => 'Reset your password';

  @override
  String verifySentTo(String email) {
    return 'We emailed a 6-digit code to $email. It expires in 10 minutes.';
  }

  @override
  String verifySentToIfAccount(String email) {
    return 'If an account exists for $email, we\'ve emailed it a 6-digit code. It expires in 10 minutes.';
  }

  @override
  String get verifyCheckSpam => 'Can\'t find it? Check your spam folder.';

  @override
  String verifyDebugCode(String code) {
    return 'Test mode (no email set up): your code is $code';
  }

  @override
  String get verifyCodeLabel => 'Code';

  @override
  String get verifyCodeHint => '000000';

  @override
  String get verifyCodeRequired => 'Enter the 6-digit code';

  @override
  String get verifyNewPasswordLabel => 'New password';

  @override
  String get verifyChangePassword => 'Change Password';

  @override
  String get verifyPasswordChanged =>
      'Password changed. Sign in with your new password.';

  @override
  String get verifyResend => 'Send a new code';

  @override
  String verifyResendIn(int seconds) {
    return 'Send a new code in ${seconds}s';
  }

  @override
  String get verifyResent => 'A new code is on its way.';

  @override
  String get googleCompleteTitle => 'Almost there';

  @override
  String googleCompleteSubtitle(String email) {
    return 'You\'re signing up with Google as $email. Add your phone number and district to finish.';
  }

  @override
  String get googleCompleteButton => 'Finish Sign-up';

  @override
  String facebookCompleteSubtitle(String email) {
    return 'You\'re signing up with Facebook as $email. Add your phone number and district to finish.';
  }
}
