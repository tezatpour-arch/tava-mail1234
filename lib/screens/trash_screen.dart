import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import '../services/db_service.dart'; // مسیر درست رو جایگزین کن

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  List<Map<String, dynamic>> deletedEmails = [];

  @override
  void initState() {
    super.initState();
    _loadDeletedEmails();
  }

  Future<void> _loadDeletedEmails() async {
    final emails = await DBService().getAllDeletedEmails();
    setState(() {
      deletedEmails = emails;
    });
  }

  Future<void> _restoreEmail(int id) async {
    await DBService().restoreDeletedEmail(id);
    await _loadDeletedEmails();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ایمیل بازگردانی شد')));
  }

  Future<void> _deleteForever(int id) async {
    await DBService().deleteDeletedEmail(id);
    await _loadDeletedEmails();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ایمیل برای همیشه حذف شد')));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Theme(
        data: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color.fromARGB(255, 253, 253, 253),
          cardColor: const Color(0xFF1E1E1E),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF080808),
            foregroundColor: Colors.white,
          ),
        ),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('ایمیل‌های حذف‌شده'),
            leading: IconButton(
              icon: const Icon(MaterialCommunityIcons.menu),
              onPressed: () {},
            ),
          ),
          body: deletedEmails.isEmpty
              ? const Center(
                  child: Text(
                    'هیچ ایمیل حذف‌شده‌ای وجود ندارد.',
                    style: TextStyle(fontSize: 16, color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  itemCount: deletedEmails.length,
                  itemBuilder: (context, index) {
                    final email = deletedEmails[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: const Color(0xFF2A2A2A),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: const Icon(
                          MaterialCommunityIcons.trash_can_outline,
                          color: Colors.redAccent,
                          size: 28,
                        ),
                        title: Text(
                          email['subject'] ?? 'بدون موضوع',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          '${email['senderEmail']} - ${(email['deletedDate'] ?? '').toString().padRight(10).substring(0, 10)}',

                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              tooltip: 'بازگردانی',
                              icon: const Icon(
                                MaterialCommunityIcons.restore,
                                color: Colors.greenAccent,
                                size: 24,
                              ),
                              onPressed: () => _restoreEmail(email['id']),
                            ),
                            IconButton(
                              tooltip: 'حذف کامل',
                              icon: const Icon(
                                MaterialCommunityIcons.delete_forever,
                                color: Colors.redAccent,
                                size: 24,
                              ),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('تأیید حذف'),
                                    content: const Text(
                                      'آیا مطمئن هستید که می‌خواهید این ایمیل را برای همیشه حذف کنید؟',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('خیر'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text('بله'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _deleteForever(email['id']);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
