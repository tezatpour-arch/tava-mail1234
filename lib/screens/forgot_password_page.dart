import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:flutter_application_1/services/database_helper.dart';
import 'email_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final nationalIdController = TextEditingController();
  final codeController = TextEditingController();

  int step = 1;
  String generatedCode = "";
  bool isSendingCode = false;
  bool isVerifying = false;

  final emailService = EmailService();

  // ارسال کد تأیید
  void sendVerificationCode() async {
    if (isSendingCode) return;

    final nationalId = nationalIdController.text.trim();

    if (nationalId.isEmpty) {
      showSnackBar('لطفاً کد ملی را وارد کنید');
      return;
    }

    setState(() => isSendingCode = true);

    final user = await DatabaseHelper.instance.findUserByNationalId(nationalId);

    if (user == null) {
      showSnackBar('کاربری با این کد ملی یافت نشد');
      setState(() => isSendingCode = false);
      return;
    }

    final email = user['email'];
    if (email == null || email.isEmpty) {
      showSnackBar('ایمیل کاربر ثبت نشده است');
      setState(() => isSendingCode = false);
      return;
    }

    final code = emailService.generateRandomCode();
    final success = await emailService.sendVerificationCode(email, code);

    if (success) {
      setState(() {
        step = 2;
        generatedCode = code;
      });
      showSnackBar('کد تایید به ایمیل شما ارسال شد');
    } else {
      showSnackBar('ارسال ایمیل با مشکل مواجه شد');
    }

    setState(() => isSendingCode = false);
  }

  // تأیید کد و ارسال رمز جدید
  void verifyCode() async {
    if (isVerifying) return;
    if (codeController.text.trim() != generatedCode) {
      showSnackBar('کد تأیید اشتباه است');
      return;
    }

    setState(() => isVerifying = true);

    final nationalId = nationalIdController.text.trim();
    final user = await DatabaseHelper.instance.findUserByNationalId(nationalId);

    if (user == null) {
      showSnackBar('کاربر یافت نشد');
      setState(() => isVerifying = false);
      return;
    }

    final username = user['username'] as String;
    final email = user['email'] as String;
    final newPassword = emailService.generateRandomPassword(length: 8);

    final updated = await DatabaseHelper.instance.updatePassword(
      username,
      newPassword,
    );

    if (updated > 0) {
      final success = await emailService.sendNewPassword(email, newPassword);

      if (success) {
        setState(() => step = 3);
        showSnackBar('رمز عبور جدید به ایمیل شما ارسال شد');
      } else {
        showSnackBar('ارسال ایمیل با مشکل مواجه شد');
      }
    } else {
      showSnackBar('خطا در به‌روزرسانی رمز عبور');
    }

    setState(() => isVerifying = false);
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 22, 22, 22),
        appBar: AppBar(
          title: const Text('فراموشی رمز عبور'),
          backgroundColor: const Color.fromARGB(255, 211, 207, 207),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: SingleChildScrollView(child: buildStepWidget())),
        ),
      ),
    );
  }

  Widget buildStepWidget() {
    switch (step) {
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nationalIdController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'کد ملی',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 12, 12, 12),
                  foregroundColor: Colors.white,
                ),
                onPressed: isSendingCode ? null : sendVerificationCode,
                child: isSendingCode
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('ارسال کد تأیید'),
              ),
            ),
          ],
        );

      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'کدی که به ایمیل شما ارسال شد را وارد کنید',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'کد تأیید',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 8, 8, 8),
                  foregroundColor: Colors.white,
                ),
                onPressed: isVerifying ? null : verifyCode,
                child: isVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('تأیید کد'),
              ),
            ),
          ],
        );

      case 3:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              MaterialCommunityIcons.check_circle,
              color: Color.fromARGB(255, 240, 241, 241),
              size: 80,
            ),
            SizedBox(height: 20),
            Text(
              'رمز عبور جدید به ایمیل شما ارسال شد.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ],
        );

      default:
        return const Text(
          'خطایی رخ داده است',
          style: TextStyle(color: Colors.white),
        );
    }
  }
}
