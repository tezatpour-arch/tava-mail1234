import 'package:shared_preferences/shared_preferences.dart';

class CurrentUser {
  static String? username;

  static Future<void> saveToPrefs(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  static Future<void> loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    username = prefs.getString('username');
  }

  static Future<void> clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
