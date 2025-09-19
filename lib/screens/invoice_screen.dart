import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import '../services/db_service.dart'; // مسیر فایل DBService شما

// ------------------------ تابع ارسال ایمیل ------------------------
Future<void> sendEmail({
  required String to,
  required String subject,
  required String body,
  required String attachmentPath,
  required senderEmail,
  required senderPassword,
  required List<dynamic> recipients,
}) async {
  String username = 'tavabojansend@gmail.com';
  String password = 'ypkf wxyj ptct wbzt'; // پسورد اپلیکیشن

  final smtpServer = gmail(username, password);

  final message = Message()
    ..from = Address(username, 'تیم تاوا')
    ..recipients.add(to)
    ..subject = subject
    ..text = body;

  if (attachmentPath.isNotEmpty) {
    final file = File(attachmentPath);
    if (await file.exists()) {
      message.attachments.add(FileAttachment(file));
    }
  }

  try {
    final sendReport = await send(message, smtpServer);
    print('ایمیل با موفقیت ارسال شد: $sendReport');
  } on MailerException catch (e) {
    print('خطا در ارسال ایمیل: $e');
  }
}

// ------------------------ کلاس صفحه فاکتور ------------------------
class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen>
    with TickerProviderStateMixin {
  File? _selectedImage;
  final TextEditingController _reportController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final DBService _dbService = DBService();
  List<Invoice> _invoicesFromDB = [];
  String? currentUserEmail;
  bool _isLoading = false;

  late AnimationController _buttonController;

  @override
  void initState() {
    super.initState();
    currentUserEmail = 'zfathkhani@tavabojan.ir';
    _loadInvoicesFromDB();

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      lowerBound: 0.95,
      upperBound: 1,
    )..forward();
  }

  @override
  void dispose() {
    _reportController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('خطا در انتخاب تصویر: $e');
    }
  }

  Future<void> _loadInvoicesFromDB() async {
    final invoices = await _dbService.getAllInvoices();
    setState(() {
      _invoicesFromDB = invoices
          .where((inv) => inv.status == 'ارسال شده')
          .toList();
    });
  }

  Future<void> _submitInvoice() async {
    if (_selectedImage == null || _reportController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً تصویر و گزارش را وارد کنید'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (currentUserEmail == null || currentUserEmail!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ایمیل کاربر لاگین شده یافت نشد'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final newInvoice = Invoice(
      description: _reportController.text,
      filePath: _selectedImage!.path,
      date: DateTime.now(),
      receiver: 'مدیر',
      status: 'ارسال شده',
      sender: 'طاها عزت‌پور', // نام فرستنده
    );

    try {
      await _dbService.insertInvoice(newInvoice);

      await sendEmail(
        to: currentUserEmail!,
        subject: 'فاکتور جدید از بخش مالی',
        body: newInvoice.description,
        attachmentPath: newInvoice.filePath,
        senderEmail: null,
        senderPassword: null,
        recipients: [],
      );

      await _loadInvoicesFromDB();

      setState(() {
        _selectedImage = null;
        _reportController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فاکتور با موفقیت ارسال شد'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در ارسال فاکتور: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteInvoice(Invoice invoice) async {
    try {
      await _dbService.deleteInvoice(invoice.id ?? 0);
      await _loadInvoicesFromDB();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فاکتور با موفقیت حذف شد'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در حذف فاکتور: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ScaleTransition(
      scale: _buttonController,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.deepPurpleAccent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
          shadowColor: Colors.grey.withOpacity(0.4),
        ),
        icon: Icon(icon, size: 22),
        label: Text(label, style: const TextStyle(fontSize: 16)),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        appBar: AppBar(
          title: const Text('ارسال فاکتور به مالی'),
          backgroundColor: const Color.fromARGB(255, 104, 103, 103),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.grey[100],
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'گیرنده: بخش مالی\nایمیل: ${currentUserEmail ?? 'تعریف نشده'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.camera_alt,
                    label: 'دوربین',
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  _buildActionButton(
                    icon: Icons.photo_library,
                    label: 'گالری',
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              if (_selectedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    _selectedImage!,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 20),

              Text(
                'گزارش فاکتور:',
                style: TextStyle(fontSize: 16, color: Colors.deepPurpleAccent),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reportController,
                maxLines: 6,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color.fromARGB(249, 255, 255, 255),
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color.fromARGB(255, 12, 12, 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  labelText: 'توضیح فاکتور',
                  hintText: '''با سلام،
فرستنده: طاها عزت‌پور
تاریخ: 
شرح فاکتور: ...''',
                  hintStyle: const TextStyle(
                    color: Color.fromARGB(96, 255, 254, 254),
                  ),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 20),
              Center(
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.deepPurpleAccent,
                      )
                    : _buildActionButton(
                        icon: MaterialCommunityIcons.send_circle,
                        label: 'ارسال فاکتور',
                        onPressed: _submitInvoice,
                      ),
              ),

              const SizedBox(height: 30),
              const Divider(
                color: Color.fromARGB(255, 37, 37, 37),
                thickness: 1,
              ),
              const SizedBox(height: 16),

              Text(
                'فاکتورهای ارسال شده',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.deepPurpleAccent,
                ),
              ),
              const SizedBox(height: 12),

              if (_invoicesFromDB.isEmpty)
                const Center(
                  child: Text(
                    'فاکتوری موجود نیست',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),

              ..._invoicesFromDB.map(
                (invoice) => Card(
                  color: Colors.grey[100],
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      MaterialCommunityIcons.file_document_outline,
                      color: Colors.deepPurpleAccent,
                    ),
                    title: Text(
                      'فاکتور',
                      style: const TextStyle(color: Colors.black87),
                    ),
                    subtitle: Text(
                      'تاریخ: ${invoice.date.toLocal().toString().substring(0, 10)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deleteInvoice(invoice),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: Colors.white,
                          title: const Text(
                            'جزئیات فاکتور',
                            textAlign: TextAlign.right,
                            style: TextStyle(color: Colors.deepPurpleAccent),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'توضیح: ${invoice.description}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(color: Colors.black87),
                              ),
                              Text(
                                'فرستنده: ${invoice.sender}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(color: Colors.black54),
                              ),
                              Text(
                                'تاریخ: ${invoice.date.toLocal()}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(color: Colors.black54),
                              ),
                              Text(
                                'وضعیت: ${invoice.status}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(color: Colors.green),
                              ),
                              if (invoice.filePath.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.file(
                                      File(invoice.filePath),
                                      height: 150,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'بستن',
                                style: TextStyle(
                                  color: Colors.deepPurpleAccent,
                                ),
                              ),
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
