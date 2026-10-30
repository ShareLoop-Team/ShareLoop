import 'dart:js_interop';

/// Web: talks to the helpers in web/facebook_sdk.js.
@JS('shareloopFacebookInit')
external JSPromise<JSAny?> _shareloopFacebookInit(JSString appId);

@JS('shareloopFacebookLogin')
external JSPromise<JSString> _shareloopFacebookLogin();

bool get facebookSdkSupported => true;

Future<void> initFacebookSdk(String appId) async {
  await _shareloopFacebookInit(appId.toJS).toDart;
}

/// The user access token, or '' when the person closed the popup.
Future<String> loginWithFacebookSdk() async {
  final token = await _shareloopFacebookLogin().toDart;
  return token.toDart;
}
