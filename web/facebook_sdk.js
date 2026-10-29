// "Continue with Facebook" for the ShareLoop web app. Loads Facebook's
// JavaScript SDK on demand and exposes two helpers that Dart calls
// (lib/services/facebook_web_sdk_web.dart):
//   shareloopFacebookInit(appId) -> Promise, resolves once FB.init ran
//   shareloopFacebookLogin()     -> Promise<string>, the user access token,
//                                   or "" when the person closed the popup
(function () {
  var ready = null;

  window.shareloopFacebookInit = function (appId) {
    if (ready) return ready;
    ready = new Promise(function (resolve, reject) {
      window.fbAsyncInit = function () {
        FB.init({ appId: appId, cookie: false, xfbml: false, version: 'v21.0' });
        resolve();
      };
      var script = document.createElement('script');
      script.src = 'https://connect.facebook.net/en_US/sdk.js';
      script.async = true;
      script.defer = true;
      script.crossOrigin = 'anonymous';
      script.onerror = function () {
        ready = null;
        reject(new Error('Facebook SDK failed to load'));
      };
      document.head.appendChild(script);
    });
    return ready;
  };

  // Must be called straight from a click so the browser allows the popup.
  window.shareloopFacebookLogin = function () {
    return new Promise(function (resolve, reject) {
      if (typeof FB === 'undefined') {
        reject(new Error('Facebook SDK not loaded'));
        return;
      }
      FB.login(function (response) {
        var auth = response && response.authResponse;
        resolve(auth && auth.accessToken ? auth.accessToken : '');
      }, { scope: 'public_profile,email', auth_type: 'rerequest' });
    });
  };
})();
