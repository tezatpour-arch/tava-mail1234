import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// مدل ایمیل دریافتی
class EmailReceived {
  final String sender;
  final String subject;
  final String body;
  final DateTime date;

  EmailReceived({
    required this.sender,
    required this.subject,
    required this.body,
    required this.date,
  });

  factory EmailReceived.fromJson(Map<String, dynamic> json) {
    return EmailReceived(
      sender: json['from'] ?? '',
      subject: json['subject'] ?? '',
      body: json['body'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': sender,
      'subject': subject,
      'body': body,
      'date': date.toIso8601String(),
    };
  }
}

/// سرویس ایمیل برای ارتباط با API
class EmailService {
  final String baseUrl;
  final String authToken;
  final String authHeaderType; // "Bearer" یا "Token"

  EmailService({
    required this.baseUrl,
    required this.authToken,
    this.authHeaderType = "Bearer",
  });

  /// دریافت ایمیل‌ها
  Future<List<EmailReceived>> fetchEmails() async {
    final url = Uri.parse('$baseUrl/emails');
    final response = await http.get(
      url,
      headers: {'Authorization': '$authHeaderType $authToken'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((json) => EmailReceived.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('توکن معتبر نیست یا منقضی شده است');
    } else {
      throw Exception('خطا در دریافت ایمیل‌ها: ${response.statusCode}');
    }
  }

  /// ارسال ایمیل با پیوست اختیاری
  Future<void> sendEmail({
    required String subject,
    required String body,
    required List<String> recipients,
    required String accountKey,
    required String senderEmail,
    File? attachment,
  }) async {
    final uri = Uri.parse('$baseUrl/send/');
    final request = http.MultipartRequest('POST', uri);

    request.fields['subject'] = subject;
    request.fields['body'] = body;
    request.fields['recipients'] = jsonEncode(recipients);
    request.fields['account'] = accountKey;
    request.fields['sender'] = senderEmail;

    if (attachment != null && await attachment.exists()) {
      request.files.add(
        await http.MultipartFile.fromPath('attachment', attachment.path),
      );
    }

    request.headers['Authorization'] = '$authHeaderType $authToken';

    final streamedResponse = await request.send();
    final respStr = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode != 200) {
      throw Exception(
        'خطا در ارسال ایمیل: ${streamedResponse.statusCode} - $respStr',
      );
    }
  }
}

/// صفحه صندوق دریافتی
class InboxScreen extends StatefulWidget {
  final String userToken;
  final String userEmail;

  const InboxScreen({
    required this.userToken,
    required this.userEmail,
    Key? key,
  }) : super(key: key);

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<EmailReceived> emails = [];
  bool isLoading = false;
  String errorMessage = '';
  late EmailService emailService;

  @override
  void initState() {
    super.initState();
    emailService = EmailService(
      baseUrl: "http://10.0.2.2:8000", // آدرس API شما
      authToken: widget.userToken,
    );
    _fetchEmails();
  }

  Future<void> _fetchEmails() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final fetchedEmails = await emailService.fetchEmails();
      if (!mounted) return;
      setState(() => emails = fetchedEmails);
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showEmailContentDialog(EmailReceived email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Feather.mail, color: Colors.teal),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                email.subject,
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'فرستنده: ${email.sender}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                email.body,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'تاریخ: ${email.date}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بستن', style: TextStyle(color: Colors.teal)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.white,
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black87),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('صندوق دریافتی'),
            leading: const Icon(MaterialCommunityIcons.inbox_arrow_down),
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    'خطا: $errorMessage',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                )
              : emails.isEmpty
              ? const Center(
                  child: Text(
                    'ایمیلی وجود ندارد',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchEmails,
                  child: ListView.builder(
                    itemCount: emails.length,
                    itemBuilder: (context, index) {
                      final email = emails[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showEmailContentDialog(email),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  email.subject,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'فرستنده: ${email.sender}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.tealAccent,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  email.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}
