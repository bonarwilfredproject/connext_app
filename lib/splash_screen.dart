import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4EEFF),
      body: Center(
        child: Image.asset(
          "lib/assets/images/logo.png",
          width: 175,
          height: 175,
        ),
      ),
    );
  }
}
