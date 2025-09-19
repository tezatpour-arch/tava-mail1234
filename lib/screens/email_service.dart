import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  final String username = '1390tahagaiml@gmail.com'; // ایمیل فرستنده
  final String password = 'ukbx zjql evrg slrj'; // رمز اپلیکیشن (App Password)

  /// تولید کد 6 رقمی تصادفی عددی
  String generateRandomCode({int length = 6}) {
    final random = Random.secure();
    String code = '';
    for (int i = 0; i < length; i++) {
      code += random.nextInt(10).toString();
    }
    return code;
  }

  /// تولید رمز عبور جدید تصادفی 8 رقمی شامل حروف کوچک، بزرگ و اعداد
  String generateRandomPassword({int length = 6}) {
    const chars = '0123456789';
    final random = Random.secure();
    return List.generate(
      length,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// ارسال کد تایید به ایمیل مقصد
  Future<bool> sendVerificationCode(String toEmail, String code) async {
    final smtpServer = gmail(username, password);

    final message = Message()
      ..from =
          Address(username, 'MyAppName') // نام برنامه خودت رو بزار
      ..recipients.add(toEmail)
      ..subject = 'کد تأیید بازیابی رمز عبور'
      ..text = 'کد تأیید شما: $code';

    try {
      final sendReport = await send(message, smtpServer);
      print('ایمیل کد تأیید ارسال شد: $sendReport');
      return true;
    } on MailerException catch (e) {
      print('خطا در ارسال ایمیل کد تأیید: $e');
      return false;
    } catch (e) {
      print('خطای ناشناخته در ارسال ایمیل کد تأیید: $e');
      return false;
    }
  }

  /// ارسال رمز عبور جدید به ایمیل کاربر
  Future<bool> sendNewPassword(String toEmail, String newPassword) async {
    final smtpServer = gmail(username, password);

    final message = Message()
      ..from =
          Address(username, 'MyAppName') // نام برنامه خودت رو بزار
      ..recipients.add(toEmail)
      ..subject = 'رمز عبور جدید شما'
      ..text =
          'رمز عبور جدید شما:\n$newPassword\nلطفاً پس از ورود، آن را تغییر دهید.';

    try {
      final sendReport = await send(message, smtpServer);
      print('ایمیل رمز عبور جدید ارسال شد: $sendReport');
      return true;
    } on MailerException catch (e) {
      print('خطا در ارسال ایمیل رمز عبور جدید: $e');
      return false;
    } catch (e) {
      print('خطای ناشناخته در ارسال ایمیل رمز عبور جدید: $e');
      return false;
    }
  }
}
