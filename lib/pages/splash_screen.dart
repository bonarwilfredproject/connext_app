import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/services/preferences_services.dart';
import 'package:connext_app/pages/home_page/home_page.dart';
import 'package:connext_app/pages/landing_page/landing_page.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _showContent = true;
      });
    });
    autoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF9F5FF),
                    Color(0xFFEDE5FF),
                    Color(0xFFE4D9FF),
                  ],
                ),
              ),
            ),
          ),
          const _SplashOrb(
            top: -120,
            right: -70,
            size: 260,
            color: Color(0x66FFFFFF),
          ),
          const _SplashOrb(
            bottom: 80,
            left: -90,
            size: 300,
            color: Color(0x4DA6B1E1),
          ),
          const _SplashOrb(
            top: 140,
            left: 30,
            size: 80,
            color: Color(0x55DCD6F7),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: _showContent ? 1 : 0.9,
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity: _showContent ? 1 : 0,
                      duration: const Duration(milliseconds: 650),
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFFFFF), Color(0xFFF0E8FF)],
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x4D424874),
                              blurRadius: 30,
                              spreadRadius: 2,
                              offset: Offset(0, 18),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFFCDC4EA),
                            width: 1.3,
                          ),
                        ),
                        child: Center(
                          child: Image.asset(
                            "assets/images/logo.png",
                            width: 100,
                            height: 100,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  AnimatedSlide(
                    offset: _showContent ? Offset.zero : const Offset(0, 0.15),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOut,
                    child: AnimatedOpacity(
                      opacity: _showContent ? 1 : 0,
                      duration: const Duration(milliseconds: 600),
                      child: Text(
                        'Connext',
                        style: TextStyle(
                          color: AppTheme.secondary,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedOpacity(
                    opacity: _showContent ? 1 : 0,
                    duration: const Duration(milliseconds: 800),
                    child: Text(
                      'Crafting Moments, Seamlessly.',
                      style: TextStyle(
                        color: AppTheme.secondary.withOpacity(0.78),
                        fontSize: 14,
                        letterSpacing: 0.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 180,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 2600),
                        builder: (context, value, _) {
                          return LinearProgressIndicator(
                            minHeight: 5,
                            value: value,
                            backgroundColor: const Color(0x40A6B1E1),
                            color: AppTheme.secondary,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void autoLogin() async {
    await Future.delayed(Duration(seconds: 3));

    final pref = PreferenceHandler();
    await pref.init();

    bool? data = await pref.getIsLogin();
    String? nama = await pref.getNamaUser();
    String? role = await pref.getRole();

    if (data == true && nama != null && role != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LandingPage()),
      (route) => false,
    );
  }
}

class _SplashOrb extends StatelessWidget {
  final double size;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final Color color;

  const _SplashOrb({
    required this.size,
    required this.color,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}
