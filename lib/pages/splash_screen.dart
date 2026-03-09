import 'package:connext_app/services/preferences_services.dart';
import 'package:connext_app/pages/home_page/home_page.dart';
import 'package:connext_app/pages/landing_page/landing_page.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    autoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4EEFF),
      body: Center(
        child: Image.asset("assets/images/logo.png", width: 175, height: 175),
      ),
    );
  }

  void autoLogin() async {
    await Future.delayed(Duration(seconds: 3));
    final pref = PreferenceHandler();
    await pref.init();
    bool? data = await pref.getIsLogin();
    if (data == true) {
      String? nama = await pref.getNamaUser();
      String? role = await pref.getRole();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) =>
              HomePage(namaUser: nama ?? "", role: role ?? ""),
        ),
        (route) => false,
      );
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LandingPage()),
      (route) => false,
    );
  }
}
