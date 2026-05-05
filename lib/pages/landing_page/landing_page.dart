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
                    Color(0xFF0F1026),
                    Color(0xFF171A33),
                    Color(0xFF262B57),
                  ],
                ),
              ),
            ),
          ),
          const _LandingOrb(
            size: 320,
            top: -120,
            right: -60,
            color: Color(0x3300D9FF),
          ),
          const _LandingOrb(
            size: 280,
            bottom: -70,
            left: -80,
            color: Color(0x33FF4D8D),
          ),
          const _LandingOrb(
            size: 90,
            top: 190,
            left: 28,
            color: Color(0x33FFFFFF),
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
                              color: const Color(0xFF171A33).withOpacity(0.78),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppTheme.third.withOpacity(0.3),
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
                        const SizedBox(height: 18),

                        FadeInUp(
                          duration: const Duration(milliseconds: 600),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF171A33,
                                ).withOpacity(0.72),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.third.withOpacity(0.16),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: AppTheme.third.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.verified_user_outlined,
                                      size: 18,
                                      color: AppTheme.third,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Terms & Conditions',
                                          style: TextStyle(
                                            color: AppTheme.secondary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Committee members must follow event rules, and attendee phone numbers may only be used for event operations.',
                                          style: styleText().copyWith(
                                            fontSize: 11.8,
                                            color: AppTheme.secondary
                                                .withOpacity(0.78),
                                            height: 1.35,
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

                        const SizedBox(height: 16),

                        FadeInUp(
                          duration: const Duration(milliseconds: 650),
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2A2F5C), Color(0xFF171A33)],
                              ),
                              border: Border.all(
                                color: AppTheme.third.withOpacity(0.35),
                                width: 1.4,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x6600D9FF),
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
                              color: AppTheme.secondary.withOpacity(0.86),
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
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF171A33),
                                      Color(0xFF22254A),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.third.withOpacity(0.18),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x5500D9FF),
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
                                          backgroundColor: AppTheme.third,
                                          foregroundColor: AppTheme.primary,
                                          elevation: 8,
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
                                          side: BorderSide(
                                            color: AppTheme.fourth.withOpacity(
                                              0.8,
                                            ),
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
                              color: AppTheme.secondary.withOpacity(0.82),
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
        color: const Color(0xFF171A33).withOpacity(0.85),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.third.withOpacity(0.18)),
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
