import 'package:shared_preferences/shared_preferences.dart';

const String _loginUserIdKey = 'loginUserId';
const String _loginTokenKey = 'loginToken';

class LoginCredential {
  const LoginCredential({required this.userId, required this.token});

  final String userId;
  final String token;
}

class LoginDataStore {
  static Future<LoginCredential?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final userId = preferences.getString(_loginUserIdKey);
    final token = preferences.getString(_loginTokenKey);
    if (userId == null || userId.isEmpty || token == null || token.isEmpty) {
      return null;
    }
    return LoginCredential(userId: userId, token: token);
  }

  static Future<void> save({
    required String userId,
    required String token,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_loginUserIdKey, userId);
    await preferences.setString(_loginTokenKey, token);
  }

  static Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_loginUserIdKey);
    await preferences.remove(_loginTokenKey);
  }
}
