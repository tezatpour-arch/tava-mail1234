import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/NoteDatabase.dart';

import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../models/note.dart';

import 'note_board_screen.dart';
import 'WeeklyReportScreen.dart';
import 'invoice_screen.dart';

import 'compose_email_screen.dart';
import 'trash_screen.dart';
import 'sent_emails_screen.dart';
import 'inbox_screen.dart';
import 'AboutUsScreen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user; // اطلاعات کامل کاربر (شامل ایمیل، نقش و نام)

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _checklistController = TextEditingController();

  String? userEmail;
  String? userName;
  String? userRole; // نقش یا مسئولیت کاربر

  final TextStyle subtitleTextStyle = const TextStyle(
    color: Color.fromARGB(153, 8, 8, 8),
  );
  final TextStyle titleTextStyle = const TextStyle(
    color: Color.fromARGB(255, 12, 12, 12),
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    setState(() {
      userEmail = widget.user['email'] ?? 'ایمیل موجود نیست';
      userName = widget.user['name'] ?? 'نام کاربر';
      userRole = widget.user['role'] ?? 'مسئولیت نامشخص';
    });
  }

  @override
  void dispose() {
    _checklistController.dispose();
    NoteDatabase.instance.close();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final text = _checklistController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً متن یادداشت را وارد کنید')),
      );
      return;
    }

    final newNote = Note(
      subject: 'چک لیست روزانه',
      text: text,
      date: DateTime.now(),
      noteType: 'یادداشت',
      sender: userEmail ?? 'ناشناس',
    );

    await NoteDatabase.instance.insertNote(newNote);

    _checklistController.clear();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('یادداشت ثبت شد')));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 250, 248, 248),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 249, 250, 250),
          title: const Text(''),
          leading: Builder(
            builder: (context) {
              return IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: SizedBox(
                  width: 24,
                  height: 24,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(3, (index) {
                      return Container(
                        height: 3,
                        width: 24,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 10, 10, 10),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      );
                    }),
                  ),
                ),
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(
                MaterialCommunityIcons.pencil,
                color: Color.fromARGB(255, 15, 15, 15),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ComposeEmailScreen(
                      currentUserName: userName ?? 'نام کاربری شما',
                      currentUserEmail: userEmail ?? 'ایمیل شما',
                      currentUserFirstName: '',
                      currentUserLastName: '',
                      currentUserToken: null,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: Colors.grey[850],
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF0F0F0F)),
                accountName: Text(userName ?? 'نام کاربر'),
                accountEmail: userEmail != null
                    ? Text(userEmail!, style: const TextStyle(fontSize: 14))
                    : const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          color: Color.fromARGB(179, 8, 8, 8),
                          strokeWidth: 2,
                        ),
                      ),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Color(0xFF070707),
                  child: Icon(
                    MaterialCommunityIcons.account,
                    size: 40,
                    color: Color.fromARGB(255, 10, 10, 10),
                  ),
                ),
              ),

              _buildDrawerItem(
                context,
                icon: MaterialCommunityIcons.send,
                title: 'ایمیل‌های ارسال شده',
                page: const SentEmailsScreen(),
              ),

              _buildDrawerItem(
                context,
                icon: MaterialCommunityIcons.inbox,
                title: 'ایمیل‌های دریافتی',
                page: InboxScreen(
                  userEmail: widget.user['email'] ?? '',
                  userToken: widget.user['token'] ?? '',
                  username: '',
                  password: '',
                ),
              ),

              _buildDrawerItem(
                context,
                icon: MaterialCommunityIcons.note_outline,
                title: 'یادداشت ها',
                page: const NoteBoardScreen(),
              ),
              _buildDrawerItem(
                context,
                icon: MaterialCommunityIcons.delete_outline,
                title: 'حذف شده‌ها',
                page: const TrashScreen(),
              ),
              _buildDrawerItem(
                context,
                icon: MaterialCommunityIcons.receipt,
                title: 'فاکتورها',
                page: const InvoiceScreen(),
              ),
              _buildDrawerItem(
                context,
                icon: MaterialCommunityIcons.chart_box_outline,
                title: 'گزارش هفتگی',
                page: const WeeklyReportScreen(),
              ),
              const Divider(color: Color.fromARGB(60, 68, 67, 67)),

              _buildDrawerItem(
                context,
                icon: MaterialCommunityIcons.information_outline,
                title: 'درباره ما',
                page: const AboutUsScreen(),
              ),
            ],
          ),
        ),

        body: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xFF070707),
                      child: Icon(
                        MaterialCommunityIcons.account,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName ?? 'نام کاربر', style: titleTextStyle),
                        const SizedBox(height: 5),
                        Text(
                          userRole ?? 'مسئولیت نامشخص',
                          style: subtitleTextStyle,
                        ),
                        const SizedBox(height: 5),
                        userEmail != null
                            ? Text(
                                userEmail!,
                                style: const TextStyle(
                                  color: Color.fromARGB(179, 19, 19, 19),
                                ),
                              )
                            : const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  color: Color.fromARGB(179, 12, 12, 12),
                                  strokeWidth: 2,
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'فعالیت های روزانه',
                  style: titleTextStyle,
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 10),
                // ایمیل‌های فوری
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 3),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 253, 253, 253),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 8, 8, 8),
                      minimumSize: const Size(double.infinity, 80),
                      foregroundColor: const Color.fromARGB(255, 252, 251, 251),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),

                    // ایمیل‌های خوانده نشده
                    icon: const Icon(Icons.mark_email_unread),
                    label: const Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [Text('ایمیل‌های خوانده‌نشده')],
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InboxScreen(
                            userEmail: widget.user['email'] ?? '',
                            userToken: widget.user['token'] ?? '',
                            username: '',
                            password: '',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // ثبت ایمیل جدید
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 3),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 7, 7, 7),
                      minimumSize: const Size(double.infinity, 80),
                      foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ComposeEmailScreen(
                            currentUserName: userName ?? 'نام کاربری شما',
                            currentUserEmail: userEmail ?? 'ایمیل شما',
                            currentUserFirstName: '',
                            currentUserLastName: '',
                            currentUserToken: null,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [Text('ثبت ایمیل')],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _checklistController,
                  maxLines: 4,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 243, 243, 243),
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color.fromARGB(255, 10, 10, 10),
                    hintText: 'متن یادداشت خود را وارد کنید',
                    hintStyle: const TextStyle(
                      color: Color.fromARGB(134, 255, 255, 255),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _saveNote,
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text(
                    'ثبت',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildDrawerItem(
  BuildContext context, {
  required IconData icon,
  required String title,
  required Widget page,
}) {
  return ListTile(
    leading: Icon(icon, color: Colors.white),
    title: Text(title, style: const TextStyle(color: Colors.white)),
    onTap: () {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    },
  );
}
