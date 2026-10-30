/// Non-web builds: "Continue with Facebook" currently runs through
/// Facebook's JavaScript SDK, so it is only available in the web app.
bool get facebookSdkSupported => false;

Future<void> initFacebookSdk(String appId) =>
    Future.error(UnsupportedError('Facebook sign-in needs the web app.'));

Future<String> loginWithFacebookSdk() =>
    Future.error(UnsupportedError('Facebook sign-in needs the web app.'));
