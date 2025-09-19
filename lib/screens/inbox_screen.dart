import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:http/http.dart' as http;

/// مدل ایمیل
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
      sender: json['sender'] ?? '',
      subject: json['subject'] ?? '',
      body: json['body'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    );
  }
}

/// سرویس ایمیل بدون پارامتر اضافی
class EmailService {
  final String baseUrl;
  final String authToken;

  EmailService({required this.baseUrl, required this.authToken});

  Future<List<EmailReceived>> fetchEmails() async {
    final url = Uri.parse('$baseUrl/api/emails/'); // فقط URL ویو
    final response = await http.get(
      url,
      headers: {'Authorization': 'Token $authToken'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((json) => EmailReceived.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('توکن معتبر نیست یا منقضی شده است');
    } else if (response.statusCode == 400) {
      throw Exception('درخواست ناقص یا نامعتبر');
    } else {
      throw Exception('خطا در دریافت ایمیل‌ها: ${response.statusCode}');
    }
  }
}

/// صفحه Inbox
class InboxScreen extends StatefulWidget {
  final String userToken;

  const InboxScreen({
    Key? key,
    required this.userToken,
    required userEmail,
    required String username,
    required String password,
  }) : super(key: key);

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  late EmailService emailService;
  List<EmailReceived> emails = [];
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();

    // URL API اصلاح شد، از آی‌پی و پورت Django استفاده کن
    emailService = EmailService(
      baseUrl: 'https://taha13801.pythonanywhere.com',
      authToken: widget.userToken,
    );

    _fetchEmails(); // فراخوانی ایمیل‌ها
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
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _refreshEmails() async {
    await _fetchEmails();
  }

  void _showEmailDialog(EmailReceived email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(email.subject, style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'فرستنده: ${email.sender}',
                style: const TextStyle(color: Colors.tealAccent),
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
      data: ThemeData.dark(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('صندوق ایمیل'),
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
            : RefreshIndicator(
                onRefresh: _refreshEmails,
                child: emails.isEmpty
                    ? const Center(child: Text('ایمیلی وجود ندارد'))
                    : ListView.builder(
                        itemCount: emails.length,
                        itemBuilder: (context, index) {
                          final email = emails[index];
                          return Card(
                            margin: const EdgeInsets.all(8),
                            child: ListTile(
                              title: Text(email.subject),
                              subtitle: Text('فرستنده: ${email.sender}'),
                              onTap: () => _showEmailDialog(email),
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}
