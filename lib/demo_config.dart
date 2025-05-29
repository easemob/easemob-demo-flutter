class DemoConfig {
  static String? _appKey;
  static String? _rtcAppId;
  static String? _serverUrl;

  static setConfig({
    required String appKey,
    String? rtcAppId,
    String? serverUrl,
  }) {
    DemoConfig._appKey = appKey;
    if (rtcAppId != null) {
      DemoConfig._rtcAppId = rtcAppId;
    }
    if (serverUrl != null) {
      DemoConfig._serverUrl = serverUrl;
    }
  }

  static bool get isValid {
    return _rtcAppId != null && _serverUrl != null;
  }

  static String? get appKey => _appKey;
  static String? get rtcAppId => _rtcAppId;
  static String? get serverUrl => _serverUrl;
}
