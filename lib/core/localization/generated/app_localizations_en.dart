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
  String get tagline => 'Give What You Don\'t Need. Get What You Do.';

  @override
  String get home => 'Home';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get giveAway => 'Give Away';

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
  String get fullName => 'Full Name';

  @override
  String get phoneNumber => 'Phone Number';

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
  String get reviewsReceived => 'Reviews Received';

  @override
  String get donations => 'Donations';

  @override
  String get requestThisItem => 'Request this item';

  @override
  String get viewIncomingRequests => 'View Incoming Requests';

  @override
  String get submitRequest => 'Submit Request';

  @override
  String get publishPost => 'Publish Post';

  @override
  String get language => 'Language';

  @override
  String get onboardingDescription =>
      'Give what you no longer need. Find what you do. Share items for free with your community across Sri Lanka.';

  @override
  String get onboardingLogIn => 'Log in';

  @override
  String get onboardingRegister => 'Register';

  @override
  String get loginWelcomeBack => 'Welcome back!';

  @override
  String get loginSubtitle => 'Fill your details or continue with social media';

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
  String get loginRememberMe => 'Remember me';

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
  String get loginOr => 'or';

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
  String get registerCityHint => 'e.g. Negombo';

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
  String homeGreeting(String name) {
    return 'Hello, $name. What are you sharing today?';
  }

  @override
  String get homeGreetingGuest => 'Hello! What are you sharing today?';

  @override
  String get homeSearchHint => 'Find items you need...';

  @override
  String get homeGiveItemTitle => 'Give an Item';

  @override
  String get homeGiveItemSubtitle => 'Pass on what you no longer need, free';

  @override
  String get homeRequestItemTitle => 'Request an Item';

  @override
  String get homeRequestItemSubtitle => 'Tell the community what you need';

  @override
  String get homeAllCategories => 'All';

  @override
  String get homeAvailableNearYou => 'Available near you';

  @override
  String get homeOpenRequests => 'Open requests';

  @override
  String get homeAllDistricts => 'All districts';

  @override
  String get homeChooseDistrict => 'Choose a district';

  @override
  String get homeGive => 'Give';

  @override
  String homeDonorBadge(String badge) {
    return '$badge donor';
  }

  @override
  String get homeNewDonor => 'New donor';

  @override
  String homeRequestedBy(String name) {
    return 'Requested by $name';
  }

  @override
  String get giveTitle => 'Give an Item';

  @override
  String get giveSubtitle => 'Share something useful with your community';

  @override
  String get givePhotos => 'Photos';

  @override
  String get giveAddPhotos => 'Add photos of your item';

  @override
  String get giveAddPhotosHint => 'Clear photos help others decide faster';

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
  String get profileNoDonations => 'You haven\'t given any items yet.';

  @override
  String get profileNoRequests => 'You haven\'t requested any items yet.';

  @override
  String get profileNoReviews => 'No reviews yet.';

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
}
