import 'package:flutter/material.dart';
import 'package:connext_app/constants/app_theme.dart';

class EllipseBackground extends StatelessWidget {
  const EllipseBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -120,
          right: -130,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.third.withOpacity(0.22),
                  AppTheme.third.withOpacity(0.04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 260,
          left: -140,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.fourth.withOpacity(0.18),
                  AppTheme.fourth.withOpacity(0.03),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -180,
          right: -160,
          child: Container(
            width: 420,
            height: 420,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppTheme.third.withOpacity(0.14), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
