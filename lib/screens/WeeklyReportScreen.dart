import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

import '../services/WeeklyReportDB.dart'; // مسیر دیتابیس
import '../models/current_user.dart'; // کلاس CurrentUser

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({Key? key}) : super(key: key);

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final String receiverName = 'مدیر عامل';
  final String receiverEmail = 'masadi@tavabojan.ir';

  final TextEditingController _subjectController = TextEditingController(
    text: 'گزارش هفتگی فعالیت‌ها',
  );
  final TextEditingController _bodyController = TextEditingController(
    text: 'با سلام،\n\n فرستنده:                           \n\n \n\nبا تشکر',
  );

  File? _pickedFile;
  bool _isSending = false;
  bool _isPickingFile = false;

  List<Map<String, dynamic>> _reportsFromDB = [];

  @override
  void initState() {
    super.initState();
    _loadReportsFromDB();
  }

  Future<void> _loadReportsFromDB() async {
    final reports = await WeeklyReportDB.instance.getReports();
    setState(() {
      _reportsFromDB = reports;
    });
  }

  Future<void> _pickFile() async {
    setState(() => _isPickingFile = true);
    try {
      final params = OpenFileDialogParams();
      final filePath = await FlutterFileDialog.pickFile(params: params);
      if (filePath != null) setState(() => _pickedFile = File(filePath));
    } catch (e) {
      _showSnackBar('خطا در انتخاب فایل: $e', isError: true);
    } finally {
      setState(() => _isPickingFile = false);
    }
  }

  void _clearPickedFile() => setState(() => _pickedFile = null);

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('لطفاً فرم را به درستی پر کنید.', isError: true);
      return;
    }

    setState(() => _isSending = true);

    try {
      String senderEmail = 'tavabojansend@gmail.com';
      String senderPassword = 'ypkf wxyj ptct wbzt'; // رمز اپلیکیشن

      final smtpServer = gmail(senderEmail, senderPassword);

      final message = Message()
        ..from = Address(senderEmail, 'تیم شما')
        ..recipients.add(receiverEmail)
        ..subject = _subjectController.text.trim()
        ..text = _bodyController.text.trim();

      if (_pickedFile != null) {
        message.attachments = [FileAttachment(_pickedFile!)];
      }

      await send(message, smtpServer);

      // ذخیره گزارش بعد از ارسال
      final report = {
        'senderEmail': senderEmail,
        'receiverEmail': receiverEmail,
        'subject': _subjectController.text.trim(),
        'body': _bodyController.text.trim(),
        'filePath': _pickedFile?.path ?? '',
        'timestamp': DateTime.now().toIso8601String(),
      };

      await WeeklyReportDB.instance.insertReport(report);

      _loadReportsFromDB();
    } on MailerException catch (e) {
      _showSnackBar('خطا در ارسال ایمیل: $e', isError: true);
    } finally {
      setState(() => _isSending = false);
    }
  }

  // حذف گزارش (بدون سطل زباله)
  Future<void> _deleteReport(int reportId) async {
    await WeeklyReportDB.instance.deleteReport(reportId);
    _showSnackBar('گزارش حذف شد');
    _loadReportsFromDB();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  String _getFileSizeString(int bytes) {
    const suffixes = ['بایت', 'کیلوبایت', 'مگابایت', 'گیگابایت'];
    double size = bytes.toDouble();
    int i = 0;
    while (size > 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final fileName = _pickedFile?.path.split(Platform.pathSeparator).last ?? '';
    final fileSize = _pickedFile != null ? _pickedFile!.lengthSync() : 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('گزارش هفتگی')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: CurrentUser.email,
                      decoration: const InputDecoration(
                        labelText: 'فرستنده',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: receiverName,
                      decoration: const InputDecoration(
                        labelText: 'گیرنده',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'موضوع',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bodyController,
                      decoration: const InputDecoration(
                        labelText: 'متن گزارش',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 10,
                      validator: (val) => val == null || val.isEmpty
                          ? 'متن گزارش را وارد کنید'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    if (_pickedFile == null)
                      ElevatedButton.icon(
                        onPressed: _isPickingFile ? null : _pickFile,
                        icon: _isPickingFile
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                MaterialCommunityIcons.file_document_outline,
                              ),
                        label: const Text('انتخاب فایل برای ارسال'),
                      )
                    else
                      Card(
                        color: const Color(0xFF2A2A2A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: const Icon(
                            MaterialCommunityIcons.file_document,
                            color: Colors.white,
                          ),
                          title: Text(
                            fileName,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            'حجم: ${_getFileSizeString(fileSize)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                            ),
                            onPressed: _clearPickedFile,
                            tooltip: 'حذف فایل انتخاب شده',
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isSending ? null : _sendEmail,
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(MaterialCommunityIcons.send),
                      label: Text(
                        _isSending ? 'در حال ارسال...' : 'ارسال ایمیل',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'گزارش‌های هفتگی ارسال‌شده',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 12),
              if (_reportsFromDB.isEmpty)
                const Center(child: Text('گزارشی موجود نیست')),
              ..._reportsFromDB.map(
                (report) => Card(
                  child: ListTile(
                    leading: const Icon(
                      MaterialCommunityIcons.file_document_outline,
                    ),
                    title: const Text('گزارش هفتگی'),
                    subtitle: Text(
                      'تاریخ: ${report['timestamp'].toString().substring(0, 10)}',
                      textAlign: TextAlign.right,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      tooltip: 'حذف گزارش',
                      onPressed: () => _deleteReport(report['id']),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text(
                            'جزئیات گزارش',
                            textAlign: TextAlign.right,
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'فرستنده: ${report['senderEmail']}',
                                textAlign: TextAlign.right,
                              ),
                              Text(
                                'گیرنده: $receiverName',
                                textAlign: TextAlign.right,
                              ),
                              Text(
                                'موضوع: ${report['subject']}',
                                textAlign: TextAlign.right,
                              ),
                              Text(
                                'متن: ${report['body']}',
                                textAlign: TextAlign.right,
                              ),
                              if (report['filePath'] != null &&
                                  report['filePath'].isNotEmpty)
                                Image.file(
                                  File(report['filePath']),
                                  height: 150,
                                ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('بستن'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
