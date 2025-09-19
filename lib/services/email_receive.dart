import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/email_received.dart';

class EmailService {
  final String baseUrl;

  EmailService({required this.baseUrl});

  Future<List<EmailReceived>> fetchEmails(
    String emailUser,
    String emailPass, {
    int limit = 10,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl/fetch-emails?email_user=$emailUser&email_pass=$emailPass&limit=$limit',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);

        // تبدیل لیست JSON به لیست EmailReceived
        return jsonData
            .map<EmailReceived>(
              (e) => EmailReceived.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception(
          'Failed to load emails with status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      // برای اشکال‌زدایی بهتر، ارور را چاپ یا پرتاب کن
      throw Exception('Error fetching emails: $e');
    }
  }
}
