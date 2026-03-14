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
        color: AppTheme.third,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}
