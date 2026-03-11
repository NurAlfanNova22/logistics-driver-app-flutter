import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {

  static const String tokenKey = "token";

  // SIMPAN TOKEN
  static Future<void> saveToken(String token) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(tokenKey, token);

  }

  // AMBIL TOKEN
  static Future<String?> getToken() async {

    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(tokenKey);

  }

  // LOGOUT
  static Future<void> logout() async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();

  }

}