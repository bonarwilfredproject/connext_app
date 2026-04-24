import 'package:flutter/material.dart';
import 'package:connext_app/constants/app_theme.dart';

class AppListCard extends StatelessWidget {
  const AppListCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final Widget child;
  final EdgeInsets padding;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1B1F3E), const Color(0xFF262B57)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.third.withOpacity(0.14), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.third.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
