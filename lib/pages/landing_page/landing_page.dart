import 'package:animate_do/animate_do.dart';
import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:connext_app/pages/auth/daftar_page.dart';
import 'package:connext_app/pages/auth/log_in_page.dart';
import 'package:flutter/material.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cardHorizontalPadding = width < 380 ? 16.0 : 20.0;

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
                    Color(0xFFF8F3FF),
                    Color(0xFFEFE6FF),
                    Color(0xFFE5DCFF),
                  ],
                ),
              ),
            ),
          ),
          const _LandingOrb(
            size: 320,
            top: -120,
            right: -60,
            color: Color(0x55FFFFFF),
          ),
          const _LandingOrb(
            size: 280,
            bottom: -70,
            left: -80,
            color: Color(0x55DCD6F7),
          ),
          const _LandingOrb(
            size: 90,
            top: 190,
            left: 28,
            color: Color(0x55A6B1E1),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 20,
                    ),
                    child: Column(
                      children: [
                        FadeInDown(
                          duration: const Duration(milliseconds: 550),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0x66A6B1E1),
                              ),
                            ),
                            child: Text(
                              'EVENT MANAGEMENT APP',
                              style: TextStyle(
                                color: AppTheme.secondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        FadeInUp(
                          duration: const Duration(milliseconds: 650),
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFFFFF), Color(0xFFF1E9FF)],
                              ),
                              border: Border.all(
                                color: const Color(0xFFCBC0EC),
                                width: 1.4,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x3D424874),
                                  blurRadius: 24,
                                  offset: Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Image.asset(
                                "assets/images/logo.png",
                                width: 58,
                                height: 58,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        FadeInUp(
                          duration: const Duration(milliseconds: 760),
                          child: Text(
                            'Host Events Like a Pro',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.secondary,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        FadeInUp(
                          duration: const Duration(milliseconds: 860),
                          child: Text(
                            'From event creation to live QR check-in, Connext helps your committee and attendees stay perfectly connected.',
                            textAlign: TextAlign.center,
                            style: styleText().copyWith(
                              fontSize: 14,
                              color: AppTheme.secondary.withOpacity(0.82),
                              height: 1.45,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        FadeInUp(
                          duration: const Duration(milliseconds: 960),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: const [
                              _FeatureChip(
                                icon: Icons.bolt,
                                label: 'Realtime Sync',
                              ),
                              _FeatureChip(
                                icon: Icons.qr_code_scanner,
                                label: 'Smart QR Check-in',
                              ),
                              _FeatureChip(
                                icon: Icons.groups_3,
                                label: 'Committee & Attendee',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        FadeInUp(
                          duration: const Duration(milliseconds: 1060),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: Container(
                                padding: EdgeInsets.fromLTRB(
                                  cardHorizontalPadding,
                                  18,
                                  cardHorizontalPadding,
                                  18,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.67),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0x66BBB0DE),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x1F424874),
                                      blurRadius: 22,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0XFF424874,
                                          ),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const LogInPage(),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.login),
                                        label: const Text(
                                          'Log In',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.secondary,
                                          side: const BorderSide(
                                            color: Color(0x99424874),
                                            width: 1.2,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const DaftarPage(),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.app_registration,
                                        ),
                                        label: const Text(
                                          'Sign Up',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        FadeIn(
                          duration: const Duration(milliseconds: 1200),
                          child: Text(
                            'Plan better. Check in faster. Deliver memorable events.',
                            textAlign: TextAlign.center,
                            style: styleText().copyWith(
                              fontSize: 12.5,
                              color: AppTheme.secondary.withOpacity(0.75),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingOrb extends StatelessWidget {
  final double size;
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final Color color;

  const _LandingOrb({
    required this.size,
    required this.color,
    this.top,
    this.right,
    this.bottom,
    this.left,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
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

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x66A6B1E1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.secondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
