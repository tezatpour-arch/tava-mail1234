import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/sent_emails_screen.dart';
import 'package:flutter_application_1/services/db_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_application_1/services/db_service.dart' as db;

class ComposeEmailScreen extends StatefulWidget {
  final String currentUserFirstName;
  final String currentUserLastName;
  final String currentUserEmail;

  const ComposeEmailScreen({
    super.key,
    required this.currentUserFirstName,
    required this.currentUserLastName,
    required this.currentUserEmail,
    required String currentUserName,
    required currentUserToken,
  });

  @override
  State<ComposeEmailScreen> createState() => _ComposeEmailScreenState();
}

class SentEmail {
  final String subject;
  final String recipient;
  final String body;
  final String sender;
  final DateTime sentDate;
  final List<String> attachments;

  SentEmail({
    required this.subject,
    required this.recipient,
    required this.body,
    required this.sender,
    required this.sentDate,
    required this.attachments,
  });
}

class _ComposeEmailScreenState extends State<ComposeEmailScreen> {
  final TextEditingController bodyController = TextEditingController();
  String? selectedSubject;
  String? selectedSubCategory;
  Map<String, String>? selectedRecipientMap;
  List<XFile> attachedImages = [];
  List<String> subCategories = [];
  List<Map<String, String>> recipients = [];
  final ImagePicker _picker = ImagePicker();

  bool isSending = false;
  static const String senderEmail = 'tavabojansend@gmail.com';
  static const String senderPassword = 'ypkf wxyj ptct wbzt';

  final Map<String, Map<String, List<Map<String, String>>>> requestOptions = {
    // 1. درخواست مرخصی
    'درخواست مرخصی': {
      'روزانه': [
        {
          'name': 'مهدی اسدی',
          'email': 'masadi@tavabojan.ir',
          'defaultBody':
              'موضوع: درخواست مرخصی روزانه\nبا سلام،\nاینجانب [نام و نام خانوادگی] درخواست مرخصی روزانه برای تاریخ [تاریخ] دارم.\nبا تشکر.',
        },
      ],
      'ساعتی': [
        {
          'name': 'مهدی اسدی',
          'email': 'masadi@tavabojan.ir',
          'defaultBody':
              'موضوع: درخواست مرخصی ساعتی\nبا سلام،\nاینجانب [نام و نام خانوادگی] درخواست مرخصی ساعتی برای تاریخ [تاریخ] از ساعت [ساعت شروع] تا [ساعت پایان] دارم.\nبا تشکر.',
        },
      ],
      'استعلاجی': [
        {
          'name': 'مهدی اسدی',
          'email': 'masadi@tavabojan.ir',
          'defaultBody':
              'موضوع: درخواست مرخصی استعلاجی\nبا سلام،\nاینجانب [نام و نام خانوادگی] به دلیل بیماری درخواست مرخصی استعلاجی از تاریخ [تاریخ شروع] تا [تاریخ پایان] دارم.\nبا تشکر.',
        },
      ],
      'تشویقی': [
        {
          'name': 'مهدی اسدی',
          'email': 'masadi@tavabojan.ir',
          'defaultBody':
              'موضوع: درخواست مرخصی تشویقی\nبا سلام،\nاینجانب [نام و نام خانوادگی] درخواست مرخصی تشویقی برای تاریخ [تاریخ] دارم.\nبا تشکر.',
        },
      ],
    },

    // 2. مساعده / پیش‌پرداخت
    'درخواست مساعده / پیش‌پرداخت حقوق': {
      'گیرنده': [
        {
          'name': 'بخش حسابداری',
          'email': 'zfathkhani@tavabojan.ir',
          'defaultBody':
              'موضوع: درخواست مساعده / پیش‌پرداخت\nبا سلام،\nاینجانب [نام و نام خانوادگی] درخواست مساعده / پیش‌پرداخت حقوق به مبلغ [مبلغ] ریال برای تاریخ [تاریخ] دارم.\nبا تشکر.',
        },
      ],
    },

    // 3. پشتیبانی / آموزش
    'درخواست پشتیبانی / آموزش': {
      'پشتیبانی': [
        {
          'name': 'تیم تحقیق توسعه',
          'email': 'rdteam@tavabojan.ir',
          'defaultBody':
              'موضوع: درخواست پشتیبانی\nبا سلام،\nاینجانب [نام و نام خانوادگی] با مشکل [شرح مشکل] مواجه شده‌ام. لطفاً راهنمایی فرمایید.\nبا تشکر.',
        },
      ],
      'آموزش': [
        {
          'name': 'تیم آموزش',
          'email': 'rdteam@tavabojan.ir',
          'defaultBody':
              'موضوع: درخواست آموزش\nبا سلام،\nاینجانب [نام و نام خانوادگی] درخواست آموزش در زمینه [موضوع آموزش] برای تاریخ [تاریخ] دارم.\nبا تشکر.',
        },
      ],
    },

    // 4. درخواست جلسه
    'درخواست جلسه': {
      'گیرنده': [
        {
          'name': 'مسئول جلسات',
          'email': 'ashahkarami@tavabojan.ir',
          'defaultBody':
              'موضوع: درخواست جلسه\nبا سلام،\nاینجانب [نام و نام خانوادگی] درخواست جلسه با موضوع [موضوع جلسه] در تاریخ [تاریخ] ساعت [ساعت] دارم.\nبا تشکر.',
        },
      ],
    },

    // 5. گزارش مشکل
    'گزارش مشکل': {
      'تکنیکال': [
        {
          'name': 'تیم تحقیق توسعه',
          'email': 'rdteam@tavabojan.ir',
          'defaultBody':
              'موضوع: گزارش مشکل فنی\nبا سلام،\nاینجانب [نام و نام خانوادگی] گزارش مشکل [شرح مشکل] را ارسال می‌کنم.\nبا تشکر.',
        },
      ],
      'عملیاتی': [
        {
          'name': 'مهدی اسدی',
          'email': 'masadi@tavabojan.ir',
          'defaultBody':
              'موضوع: گزارش مشکل عملیاتی\nبا سلام،\nاینجانب [نام و نام خانوادگی] گزارش مشکل [شرح مشکل] در واحد [واحد] را ارسال می‌کنم.\nبا تشکر.',
        },
      ],
    },

    // 6. شارژ کارت تنخواه
    'شارژ کارت تنخواه': {
      'گیرنده': [
        {
          'name': 'مهدی اسدی',
          'email': 'masadi@tavabojan.ir',
          'defaultBody':
              'موضوع: شارژ کارت تنخواه\nبا سلام،\nاینجانب [نام و نام خانوادگی] درخواست شارژ کارت تنخواه به مبلغ [مبلغ] ریال دارم.\nبا تشکر.',
        },
        {
          'name': 'بخش حسابداری',
          'email': 'zfathkhani@tavabojan.ir',
          'defaultBody':
              'موضوع: شارژ کارت تنخواه\nبا سلام،\nاینجانب [نام و نام خانوادگی] درخواست شارژ کارت تنخواه به مبلغ [مبلغ] ریال دارم.\nبا تشکر.',
        },
      ],
    },

    // 7. درخواست سفارش
    'درخواست سفارش': {
      'گیرنده': [
        {
          'name': 'مدیر تولیدی',
          'email': 'aabazadeh@tavabojan.ir',
          'defaultBody':
              'موضوع: درخواست سفارش\nبا سلام،\nاینجانب [نام و نام خانوادگی] درخواست سفارش زیر را دارم:\nموضوع: [موضوع درخواست]\nتوضیح: [توضیح درخواست]\nبا تشکر.',
        },
        {
          'name': 'انبار دار',
          'email': 'nnazempor@tavabojan.ir',
          'defaultBody':
              'موضوع: درخواست سفارش\nبا سلام،\nاینجانب [نام و نام خانوادگی] درخواست سفارش زیر را دارم:\nموضوع: [موضوع درخواست]\nتوضیح: [توضیح درخواست]\nبا تشکر.',
        },
      ],
      'تحویل سفارش': [
        {
          'name': 'زهرا محمدزاده',
          'email': 'zmohammadzadeh@tavabojan.ir',
          'defaultBody':
              'موضوع: تحویل سفارش\nبا سلام،\nسفارش [نام سفارش] آماده تحویل است.\nبا تشکر.',
        },
      ],
    },

    // 8. مدیرعامل
    'مدیرعامل': {
      'گزارش کاری': [
        {
          'name': 'مهدی اسدی',
          'email': 'masadi@tavabojan.ir',
          'defaultBody':
              'موضوع: گزارش کاری [روزانه/هفتگی/ماهانه]\nبا سلام،\nاینجانب [نام و نام خانوادگی] گزارش کاری [روزانه/هفتگی/ماهانه] مربوط به تاریخ [تاریخ] را آماده کرده‌ام.\nبا تشکر.',
        },
      ],
      'تذکر به کارکنان': [
        {
          'name': 'مهدی اسدی',
          'email': 'masadi@tavabojan.ir',
          'defaultBody':
              'موضوع: تذکر به کارکنان\nبا سلام،\nاینجانب [نام و نام خانوادگی] درخواست تذکر به کارمند [نام کارمند] به دلیل [علت] دارم.\nبا تشکر.',
        },
      ],
      'درخواست خرید / خدمات': [
        {
          'name': 'مدیر تدارکات',
          'email': 'izivari@tavabojan.ir',
          'defaultBody':
              'موضوع: درخواست خرید / خدمات\nبا سلام،\nاینجانب [نام و نام خانوادگی] درخواست خرید / خدمات [شرح درخواست] دارم.\nبا تشکر.',
        },
      ],
      'سایر': [
        {
          'name': 'مهدی اسدی',
          'email': 'masadi@tavabojan.ir',
          'defaultBody':
              'موضوع: سایر درخواست‌ها\nبا سلام،\nاینجانب [نام و نام خانوادگی] درخواست زیر را دارم:\n[متن درخواست]\nبا تشکر.',
        },
      ],
    },
    // 9. سایر
    'سایر': {
      'گیرنده': [
        {
          'name': 'مدیرعامل - مهدی اسدی',
          'email': 'masadi@tavabojan.ir',
          'defaultBody':
              'موضوع: سایر درخواست‌ها\nبا سلام،\nاینجانب [نام و نام خانوادگی] درخواست زیر را دارم:\n[متن درخواست]\nبا تشکر.',
        },
        {
          'name': 'مدیر تدارکات ',
          'email': 'izivari@tavabojan.ir',
          'defaultBody':
              'موضوع: سایر درخواست‌ها\nبا سلام،\nاینجانب [نام و نام خانوادگی] درخواست زیر را دارم:\n[متن درخواست]\nبا تشکر.',
        },
        {
          'name': 'انباردار',
          'email': 'nnazempor@tavabojan.ir',
          'defaultBody':
              'موضوع: سایر درخواست‌ها\nبا سلام،\nاینجانب [نام و نام خانوادگی] درخواست زیر را دارم:\n[متن درخواست]\nبا تشکر.',
        },
        {
          'name': 'مدیر فروش',
          'email': 'zmohammadzadeh@tavabojan.ir',
          'defaultBody':
              'موضوع: سایر درخواست‌ها\nبا سلام،\nاینجانب [نام و نام خانوادگی] درخواست زیر را دارم:\n[متن درخواست]\nبا تشکر.',
        },
        {
          'name': 'مدیر تولیدی ',
          'email': 'aabazadeh@tavabojan.ir',
          'defaultBody':
              'موضوع: سایر درخواست‌ها\nبا سلام،\nاینجانب [نام و نام خانوادگی] درخواست زیر را دارم:\n[متن درخواست]\nبا تشکر.',
        },
        {
          'name': 'مدیر مالی',
          'email': 'ealilo@tavabojan.ir',
          'defaultBody':
              'موضوع: سایر درخواست‌ها\nبا سلام،\nاینجانب [نام و نام خانوادگی] درخواست زیر را دارم:\n[متن درخواست]\nبا تشکر.',
        },
        {
          'name': 'تیم تحقیق و توسعه',
          'email': 'rdteam@tavabojan.ir',
          'defaultBody':
              'موضوع: سایر درخواست‌ها\nبا سلام،\nاینجانب [نام و نام خانوادگی] درخواست زیر را دارم:\n[متن درخواست]\nبا تشکر.',
        },
        {
          'name': 'حسابدار ',
          'email': 'zfathkhani@tavabojan.ir',
          'defaultBody':
              'موضوع: سایر درخواست‌ها\nبا سلام،\nاینجانب [نام و نام خانوادگی] درخواست زیر را دارم:\n[متن درخواست]\nبا تشکر.',
        },
        {
          'name': 'مسئول تیم R&D - مهدی رضائی',
          'email': 'mrezai@tavabojan.ir',
          'defaultBody':
              'موضوع: سایر درخواست‌ها\nبا سلام،\nاینجانب [نام و نام خانوادگی] درخواست زیر را دارم:\n[متن درخواست]\nبا تشکر.',
        },
        {
          'name': 'مسئول تیم R&D - علیرضا شاه‌کرمی',
          'email': 'tezatpour@tavabojan.ir',
          'defaultBody':
              'موضوع: سایر درخواست‌ها\nبا سلام،\nاینجانب [نام و نام خانوادگی] درخواست زیر را دارم:\n[متن درخواست]\nبا تشکر.',
        },
        {
          'name': 'مسئول تیم R&D - طاها عزت‌پور',
          'email': 'ashahkarami@tavabojan.ir',
          'defaultBody':
              'موضوع: سایر درخواست‌ها\nبا سلام،\nاینجانب [نام و نام خانوادگی] درخواست زیر را دارم:\n[متن درخواست]\nبا تشکر.',
        },
      ],
    },
  };

  // گرفتن عکس از دوربین
  Future<void> _takePhoto() async {
    final photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() => attachedImages.add(photo));
    }
  }

  Future<void> _pickImagesFromGallery() async {
    final images = await _picker.pickMultiImage();
    if (images.isNotEmpty) setState(() => attachedImages.addAll(images));
  }

  void _onSubjectChanged(String? newSubject) {
    if (newSubject == null) return;
    setState(() {
      selectedSubject = newSubject;
      subCategories = requestOptions[newSubject]!.keys.toList();
      selectedSubCategory = subCategories.first;
      recipients = requestOptions[newSubject]![selectedSubCategory!]!;
      selectedRecipientMap = recipients.first;
      _setDefaultBody();
    });
  }

  void _onSubCategoryChanged(String? newSub) {
    if (newSub == null) return;
    setState(() {
      selectedSubCategory = newSub;
      recipients = requestOptions[selectedSubject]![selectedSubCategory!]!;
      selectedRecipientMap = recipients.first;
      _setDefaultBody();
    });
  }

  void _setDefaultBody() {
    if (selectedRecipientMap != null) {
      String body = selectedRecipientMap!['defaultBody'] ?? '';
      body = body.replaceAll(
        '[نام و نام خانوادگی]',
        '${widget.currentUserFirstName} ${widget.currentUserLastName}',
      );
      bodyController.text = body;
    }
  }

  Future<void> _sendEmail() async {
    if (selectedSubject == null ||
        selectedSubCategory == null ||
        selectedRecipientMap == null ||
        bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً همه فیلدها را پر کنید')),
      );
      return;
    }

    setState(() => isSending = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final smtpServer = SmtpServer(
      'smtp.gmail.com',
      username: senderEmail,
      password: senderPassword,
      port: 465,
      ssl: true,
    );

    final message = Message()
      ..from = Address(senderEmail, 'توا بوجان')
      ..recipients.add(selectedRecipientMap!['email']!)
      ..subject = '$selectedSubject - $selectedSubCategory'
      ..text = bodyController.text;

    for (final image in attachedImages) {
      final file = File(image.path);
      if (await file.exists()) message.attachments.add(FileAttachment(file));
    }

    try {
      await send(message, smtpServer);

      final sentEmail = db.SentEmail(
        subject: '$selectedSubject - $selectedSubCategory',
        recipient: selectedRecipientMap!['email']!,
        body: bodyController.text,
        sender: senderEmail,
        sentDate: DateTime.now(),
        attachments: attachedImages.map((f) => f.path).toList(),
      );

      await DBService().insertSentEmail(sentEmail);

      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SentEmailsScreen()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ایمیل با موفقیت ارسال و ذخیره شد!')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در ارسال ایمیل: $e')));
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ثبت ایمیل')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'موضوع:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: selectedSubject,
                  hint: const Text('موضوع را انتخاب کنید'),
                  isExpanded: true,
                  items: requestOptions.keys
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: _onSubjectChanged,
                ),
                if (subCategories.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'زیردسته:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: selectedSubCategory,
                    isExpanded: true,
                    items: subCategories
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: _onSubCategoryChanged,
                  ),
                ],
                if (recipients.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'گیرنده:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<Map<String, String>>(
                    value: selectedRecipientMap,
                    isExpanded: true,
                    items: recipients
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(r['name'] ?? r['email'] ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (r) {
                      setState(() {
                        selectedRecipientMap = r;
                        _setDefaultBody();
                      });
                    },
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'متن ایمیل:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: bodyController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: 'متن ایمیل را اینجا بنویسید...',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickImagesFromGallery,
                        icon: const Icon(Icons.photo),
                        label: const Text('گالری'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _takePhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('دوربین'),
                      ),
                    ),
                  ],
                ),
                if (attachedImages.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: attachedImages.length,
                      itemBuilder: (context, index) {
                        final file = File(attachedImages[index].path);
                        return Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Image.file(
                                file,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => setState(
                                  () => attachedImages.removeAt(index),
                                ),
                                child: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.red,
                                  child: Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSending ? null : _sendEmail,
                        child: Text(isSending ? 'در حال ارسال...' : 'ارسال'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
