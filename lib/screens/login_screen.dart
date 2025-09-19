import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/screens/forgot_password_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/screens/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool showFields = false;
  bool isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _loginError;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        showFields = true;
      });
    });

    // پاک کردن خطا هنگام تایپ
    _usernameController.addListener(() {
      if (_loginError != null) setState(() => _loginError = null);
    });
    _passwordController.addListener(() {
      if (_loginError != null) setState(() => _loginError = null);
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    // URL API درست
    final apiUrl = "http://192.168.37.128:8000/api/login/";

    try {
      final response = await http.post(
        Uri.parse(apiUrl), // ← اصلاح شد
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final token = data['token'] ?? '';
        final user = data['user'] ?? {};

        // ذخیره در UserSession (Singleton)
        UserSession().setUser(
          username: username,
          userEmail: user['email'] ?? '',
          password: password,
          token: token,
        );

        if (token.isNotEmpty) {
          // هدایت به داشبورد
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomeScreen(
                user: {
                  'email': user['email'] ?? '',
                  'name':
                      (user['first_name'] ?? '') +
                      ' ' +
                      (user['last_name'] ?? ''),
                  'role': user['role'] ?? 'کاربر',
                  'token': token,
                },
              ),
            ),
          );
        } else {
          setState(() => _loginError = "توکن دریافت نشد");
        }
      } else if (response.statusCode == 401) {
        setState(() => _loginError = "نام کاربری یا رمز عبور اشتباه است");
      } else {
        setState(() => _loginError = "خطا: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _loginError = 'خطا در ارتباط با سرور: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Animate(
                  effects: [
                    FadeEffect(duration: 800.ms),
                    SlideEffect(begin: const Offset(0, -0.2)),
                  ],
                  child: Image.asset(
                    'lib/assets/logo.png',
                    width: 300,
                    height: 300,
                  ),
                ),
                const SizedBox(height: 30),
                if (showFields)
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildInputField(
                          _usernameController,
                          Icons.person,
                          'نام کاربری',
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          _passwordController,
                          Icons.lock,
                          'رمز عبور',
                          obscure: true,
                        ),
                        const SizedBox(height: 12),
                        if (_loginError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              _loginError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 120,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'ورود',
                                      style: GoogleFonts.vazirmatn(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                  .animate()
                                  .fade(duration: 500.ms)
                                  .slideY(begin: 0.3),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordPage(),
                              ),
                            );
                          },
                          child: Text(
                            'فراموشی رمز عبور؟',
                            style: GoogleFonts.vazirmatn(color: Colors.black87),
                          ),
                        ).animate().fade().slideY(begin: 0.3),
                      ],
                    ).animate().fade(duration: 500.ms).slideY(begin: 0.3),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    IconData icon,
    String hint, {
    bool obscure = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        textAlign: TextAlign.right,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'این فیلد نمی‌تواند خالی باشد';
          }
          return null;
        },
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black87),
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.black54,
            fontFamily: 'Vazirmatn',
          ),
          filled: true,
          fillColor: const Color.fromARGB(132, 201, 201, 224),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black),
          ),
        ),
      ),
    );
  }
}

// مدیریت سشن کاربری
class UserSession {
  static final UserSession _instance = UserSession._internal();

  String? username;
  String? userEmail;
  String? password;
  String? token;

  factory UserSession() => _instance;

  UserSession._internal();

  void setUser({
    required String username,
    required String userEmail,
    required String password,
    required String token,
  }) {
    this.username = username;
    this.userEmail = userEmail;
    this.password = password;
    this.token = token;
  }
}
