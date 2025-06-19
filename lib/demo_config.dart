class DemoConfig {
  static String? _appKey;
  static String? _rtcAppId;
  static String? _serverUrl;
  static String? _verifyCodeSecret;
  static String? _verifyCodeURL;

  static setConfig({
    required String appKey,
    String? rtcAppId,
    String? serverUrl,
    String? verifyCodeSecret,
    String? verifyCodeURL,
  }) {
    DemoConfig._appKey = appKey;
    if (rtcAppId != null) {
      DemoConfig._rtcAppId = rtcAppId;
    }
    if (serverUrl != null) {
      DemoConfig._serverUrl = serverUrl;
    }
    if (verifyCodeSecret != null) {
      DemoConfig._verifyCodeSecret = verifyCodeSecret;
    }
    if (verifyCodeURL != null) {
      DemoConfig._verifyCodeURL = verifyCodeURL;
    }
  }

  static bool get isValid {
    return _rtcAppId != null && _serverUrl != null;
  }

  static String? get appKey => _appKey;
  static String? get rtcAppId => _rtcAppId;
  static String? get serverUrl => _serverUrl;
  static String? get verifyCodeSecret => _verifyCodeSecret;
  static String? get verifyCodeURL => _verifyCodeURL;
}
