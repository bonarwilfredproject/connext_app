import 'package:flutter/material.dart';

class PositioningInside extends StatelessWidget {
  const PositioningInside({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Positioned(child: child, top: 96, left: 0, right: 0);
  }
}
