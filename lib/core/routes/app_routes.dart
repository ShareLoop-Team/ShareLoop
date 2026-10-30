/// Centralised route name constants. The actual Route<> map is built in
/// main.dart once the view widgets exist (kept here so controllers/views
/// can reference route names without importing every screen).
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String intro = '/intro';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyCode = '/verify-code';
  static const String completeGoogleProfile = '/google/complete-profile';
  static const String home = '/home';
  static const String editProfile = '/profile/edit';
  static const String myDonations = '/profile/donations';
  static const String myRequests = '/profile/requests';
  static const String myReviews = '/profile/reviews';
  static const String categoryBrowse = '/browse/category';
  static const String searchFilter = '/browse/search';
  static const String createGiveAway = '/give-away/create';
  static const String itemDetails = '/give-away/details';
  static const String incomingRequests = '/give-away/requests';
  static const String createRequest = '/requests/create';
  static const String contactShared = '/handover/contact';
  static const String handoverConfirmation = '/handover/confirmation';
  static const String ratingReview = '/handover/rating';
  static const String profile = '/profile';
  static const String adminUsers = '/admin/users';
  static const String adminPosts = '/admin/posts';
  static const String adminCategories = '/admin/categories';
  static const String settings = '/settings';
}
