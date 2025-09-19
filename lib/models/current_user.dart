import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';

class CurrentUser {
  static String email = '';
  static String username = '';
  static String fullName = '';
  static String? profileImagePath;

  static var name;

  static var token;

  static var firstName;

  static var lastName;

  /// لود اطلاعات از SharedPreferences (در زمان اجرای برنامه)
  static Future<void> loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    username = prefs.getString('username') ?? '';
    email = prefs.getString('email') ?? '';
    fullName = prefs.getString('fullName') ?? '';
    profileImagePath = prefs.getString('profileImagePath');
  }

  /// ذخیره اطلاعات در SharedPreferences
  static Future<void> saveUserToPrefs({
    required String username,
    required String email,
    String? fullName,
    String? profileImagePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('email', email);
    if (fullName != null) await prefs.setString('fullName', fullName);
    if (profileImagePath != null) {
      await prefs.setString('profileImagePath', profileImagePath);
    }
  }

  /// بارگذاری از دیتابیس و ذخیره در حافظه و SharedPreferences
  static Future<void> loadUserFromDatabase(String usernameInput) async {
    final userMap = await DatabaseHelper.instance.getUser(usernameInput);
    if (userMap != null) {
      username = userMap['username'] ?? '';
      email = userMap['email'] ?? '';
      fullName = userMap['full_name'] ?? '';
      profileImagePath = userMap['profile_image'];

      // ذخیره در SharedPreferences
      await saveUserToPrefs(
        username: username,
        email: email,
        fullName: fullName,
        profileImagePath: profileImagePath,
      );
    } else {
      // در صورت نبود کاربر
      username = '';
      email = '';
      fullName = '';
      profileImagePath = null;
    }
  }

  /// پاکسازی اطلاعات کاربر (مثلاً هنگام خروج از حساب)
  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('email');
    await prefs.remove('fullName');
    await prefs.remove('profileImagePath');

    username = '';
    email = '';
    fullName = '';
    profileImagePath = null;
  }
}
