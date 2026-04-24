import 'package:flutter/material.dart';
import 'package:connext_app/constants/app_theme.dart';

class TombolSementara extends StatelessWidget {
  const TombolSementara({
    super.key,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    required this.width,
    required this.height,
    required this.text,
  });
  final void Function()? onPressed;
  final IconData? icon;
  final bool isLoading;
  final String text;
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(width, height),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: AppTheme.third,
        foregroundColor: AppTheme.primary,
        elevation: 8,
      ),
      onPressed: isLoading ? null : onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            )
          else if (icon != null)
            Icon(icon),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 16, color: AppTheme.primary),
          ),
        ],
      ),
    );
  }
}
