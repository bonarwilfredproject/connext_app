import 'package:flutter/material.dart';

class TombolSementara extends StatelessWidget {
  const TombolSementara({
    super.key,
    this.onPressed,
    this.icon,
    this.child,
    required this.width,
    required this.height,
  });
  final void Function()? onPressed;
  final IconData? icon;
  final Widget? child;
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        fixedSize: Size(width, height),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(12),
        ),
        backgroundColor: Color(0XFF424874),
        foregroundColor: Color(0xFFF4EEFF),
      ),
      onPressed: onPressed,
      child: child,
    );
  }
}
