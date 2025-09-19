import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class UserService {
  // روی شبیه‌ساز اندروید، از 10.0.2.2 استفاده می‌کنیم
  static const String baseUrl = 'http://10.0.2.2:8000';

  static Future<List<User>> fetchRecipients() async {
    final response = await http.get(Uri.parse('$baseUrl/get_users.php'));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => User.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load recipients');
    }
  }
}
