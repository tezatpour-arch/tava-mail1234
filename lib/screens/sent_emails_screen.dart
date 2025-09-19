import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import '../services/db_service.dart';

class SentEmailsScreen extends StatefulWidget {
  const SentEmailsScreen({super.key});

  @override
  _SentEmailsScreenState createState() => _SentEmailsScreenState();
}

class _SentEmailsScreenState extends State<SentEmailsScreen> {
  List<SentEmail> sentEmails = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSentEmails();
  }

  Future<void> _loadSentEmails() async {
    final emails = await DBService().getAllSentEmails();
    setState(() {
      sentEmails = emails;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 253, 253, 253),
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          title: const Text(
            'ایمیل‌های ارسال شده',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(
            color: Color.fromARGB(255, 238, 236, 236),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : sentEmails.isEmpty
            ? const Center(
                child: Text(
                  'ایمیلی ارسال نشده است',
                  style: TextStyle(
                    color: Color.fromARGB(179, 7, 7, 7),
                    fontSize: 16,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: sentEmails.length,
                itemBuilder: (context, index) {
                  final email = sentEmails[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white10.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      leading: const Icon(
                        Feather.send,
                        color: Color.fromARGB(255, 5, 5, 5),
                      ),
                      title: Text(
                        email.subject,
                        style: const TextStyle(
                          color: Color.fromARGB(255, 17, 17, 17),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        'به: ${email.recipient}',
                        style: const TextStyle(
                          color: Color.fromARGB(179, 7, 7, 7),
                          fontSize: 14,
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        color: const Color(0xFF1F1F1F),
                        icon: const Icon(
                          Feather.more_vertical,
                          color: Color.fromARGB(255, 8, 8, 8),
                        ),
                        onSelected: (value) {
                          if (value == 'view') {
                            _showEmailDialog(context, email);
                          } else if (value == 'delete') {
                            // حذف ایمیل از دیتابیس
                            _deleteEmail(email.id!);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(
                                  Feather.eye,
                                  size: 18,
                                  color: Color.fromARGB(255, 247, 247, 247),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'مشاهده',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 247, 244, 244),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Feather.trash_2,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'حذف',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showEmailDialog(BuildContext context, SentEmail email) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F1F1F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Feather.mail,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  email.subject,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'گیرنده: ${email.recipient}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(email.body, style: const TextStyle(color: Colors.white70)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'بستن',
                style: TextStyle(color: Colors.tealAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEmail(int id) async {
    await DBService().trashEmail(
      id,
    ); // به جای trashscreen از trashEmail استفاده کن
    await _loadSentEmails(); // بارگذاری مجدد ایمیل‌ها

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ایمیل به سطل زباله منتقل شد'),
          backgroundColor: Colors.orangeAccent,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}
