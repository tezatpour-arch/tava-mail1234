import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _logoController;
  late AnimationController _cardFloatController;

  final List<Map<String, dynamic>> teamMembers = [
    {
      'name': 'طاها عزت‌پور',
      'role': 'طراح و توسعه‌دهنده رابط کاربری',
      'image': 'lib/assets/taha.png',
      'color': const Color(0xFF7C4DFF),
    },
    {
      'name': 'مهدی رضائی',
      'role': 'توسعه‌دهنده و بهینه‌ساز اپلیکیشن',
      'image': 'lib/assets/mehdi.png',
      'color': Colors.blueAccent,
    },
    {
      'name': 'علیرضا شاه‌کرمی',
      'role': 'توسعه‌دهنده و هماهنگ‌کننده تیم تحقیق',
      'image': 'lib/assets/alireza.png',
      'color': Colors.orangeAccent,
    },
    {
      'name': 'تیم تحقیق و توسعه',
      'role': 'بهینه‌سازی و توسعه اپلیکیشن',
      'image': 'lib/assets/logo.png',
      'color': Colors.greenAccent,
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _cardFloatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _logoController.dispose();
    _cardFloatController.dispose();
    super.dispose();
  }

  double _calculateParallax(
    double cardPosition,
    double scrollOffset,
    double height,
  ) {
    return ((scrollOffset - cardPosition + height / 2) * 0.15).clamp(-40, 40);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('درباره ما'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Stack(
        children: [
          // پس‌زمینه لوگوی متحرک حرفه‌ای
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Lottie.network(
                'https://assets6.lottiefiles.com/packages/lf20_tutvdkg0.json',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                const SizedBox(height: 40),
                // لوگوی اصلی با Scale و Glow
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    double scale = 0.8 + sin(_logoController.value * pi) * 0.2;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.deepPurpleAccent,
                            width: 5,
                          ),
                          image: const DecorationImage(
                            image: AssetImage('lib/assets/logo.png'),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              // ignore: deprecated_member_use
                              color: Colors.deepPurpleAccent.withOpacity(0.9),
                              blurRadius: 28,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'اپلیکیشن مدیریت سازمانی تاوا',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurpleAccent,
                    shadows: const [
                      Shadow(
                        blurRadius: 18,
                        color: Colors.purpleAccent,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'این اپلیکیشن برای مدیریت حرفه‌ای ایمیل‌ها، یادداشت‌ها و ارتباطات داخلی طراحی شده است. '
                    'تیم تحقیق و توسعه تاوا همراه با طاها عزت‌پور، مهدی رضائی و علیرضا شاه‌کرمی به بهینه‌سازی و توسعه این اپلیکیشن پرداخته‌اند.',
                    style: GoogleFonts.vazirmatn(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 48),
                // کارت‌های تیم با پارالاکس و float انیمیشنی
                for (int i = 0; i < teamMembers.length; i++)
                  Column(
                    children: [
                      AnimatedBuilder(
                        animation: _scrollController,
                        builder: (context, child) {
                          double offset = _scrollController.hasClients
                              ? _calculateParallax(
                                  i * 200.0,
                                  _scrollController.offset,
                                  height,
                                )
                              : 0;
                          double floatOffset =
                              sin(
                                (_cardFloatController.value + i * 0.25) *
                                    2 *
                                    pi,
                              ) *
                              8;
                          return Transform.translate(
                            offset: Offset(0, offset + floatOffset),
                            child: child,
                          );
                        },
                        child: _glowHoverCard(teamMembers[i]),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowHoverCard(Map<String, dynamic> member) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {},
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 400),
            tween: Tween(begin: 0.95, end: 1),
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 18,
              shadowColor: member['color'].withOpacity(0.9),
              color: Colors.grey[900],
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      member['color'].withOpacity(0.25),
                      Colors.grey[900]!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: member['color'].withOpacity(0.7),
                      blurRadius: 28,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundImage: AssetImage(member['image']),
                      backgroundColor: Colors.transparent,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member['name'],
                            style: GoogleFonts.vazirmatn(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: member['color'].withOpacity(0.9),
                                  blurRadius: 16,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            member['role'],
                            style: GoogleFonts.vazirmatn(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
