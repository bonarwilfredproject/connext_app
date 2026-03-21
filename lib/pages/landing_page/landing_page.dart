import 'package:animate_do/animate_do.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:connext_app/pages/auth/daftar_page.dart';
import 'package:connext_app/pages/auth/log_in_page.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/widgets/tombol_sementara.dart';
import 'package:flutter/material.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EEFF),
      body: Stack(
        children: [
          EllipseBackground(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ZoomIn(
                duration: Duration(milliseconds: 800),
                child: Image.asset(
                  "assets/images/logo.png",
                  width: 79,
                  height: 79,
                ),
              ),
              SizedBox(height: 24),

              FadeInDown(
                duration: Duration(milliseconds: 900),
                child: Text(
                  "Welcome!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),

              SizedBox(height: 32),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: FadeInLeft(
                  duration: Duration(milliseconds: 1000),
                  child: TombolSementara(
                    icon: Icons.login,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LogInPage()),
                      );
                    },
                    width: 240,
                    height: 56,
                    text: "Log In",
                  ),
                ),
              ),

              SizedBox(height: 16),

              FadeIn(
                duration: Duration(milliseconds: 1100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: Color(0xFF424874))),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text("or", style: styleText()),
                      ),
                      Expanded(child: Divider(color: Color(0xFF424874))),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: FadeInRight(
                  duration: Duration(milliseconds: 1200),
                  child: TombolSementara(
                    icon: Icons.app_registration,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DaftarPage()),
                      );
                    },
                    width: 240,
                    height: 56,
                    text: "Sign Up",
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
