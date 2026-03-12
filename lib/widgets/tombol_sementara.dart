import 'package:flutter/material.dart';

class TombolSementara extends StatelessWidget {
  const TombolSementara({
    super.key,
    this.onPressed,
    this.icon,
    required this.width,
    required this.height,
    required this.text,
  });
  final void Function()? onPressed;
  final IconData? icon;
  final String text;
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(width, height),
        padding: EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(12),
        ),
        backgroundColor: Color(0XFF424874),
        foregroundColor: Color(0xFFF4EEFF),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(icon),
          SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 16, color: Color(0xFFF4EEFF))),
        ],
      ),
    );
  }
}
