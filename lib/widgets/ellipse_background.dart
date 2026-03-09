import 'package:flutter/material.dart';

class EllipseBackground extends StatelessWidget {
  const EllipseBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 320,
      right: -244,
      left: -244,
      child: Container(
        width: 1000,
        height: 1000,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(1000),
          color: Color(0xFFDCD6F7),
        ),
      ),
    );
  }
}
