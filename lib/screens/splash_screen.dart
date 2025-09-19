import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart'; // صفحه بعدی اپ

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // 3 ثانیه بعد برو به صفحه لاگین
    Timer(const Duration(seconds: 1), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.from(
        alpha: 100,
        red: 1,
        green: 1,
        blue: 1,
      ), // یا رنگ برند شما
      body: Center(
        child: Image.asset(
          'lib/assets/logo.png', // آدرس درست فایل لوگو
          width: 150,
          height: 150,
        ),
      ),
    );
  }
}
