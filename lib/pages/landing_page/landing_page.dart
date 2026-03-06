import 'package:connext_app/pages/daftar_page/daftar_page.dart';
import 'package:connext_app/pages/log_in_page/log_in_page.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/widgets/positioning_inside.dart';
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
      appBar: AppBar(backgroundColor: Color(0xFFF4EEFF)),
      body: Stack(
        children: [
          EllipseBackground(),

          PositioningInside(
            child: Column(
              children: [
                Image.asset(
                  "lib/assets/images/logo.png",
                  width: 79,
                  height: 79,
                ),
                SizedBox(height: 36),
                Text(
                  "Selamat Datang!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 36),

                //tombol masuk
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
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
                    text: "Masuk",
                  ),
                ),
                SizedBox(height: 12),

                //atau divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        indent: 100,
                        endIndent: 12,
                        color: Color(0xFF424874),
                      ),
                    ),
                    Text(
                      "atau",
                      style: TextStyle(
                        fontSize: 20,
                        color: Color(0xFF424874),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        indent: 12,
                        endIndent: 100,
                        color: Color(0xFF424874),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                //tombol daftar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
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
                    text: "Daftar",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF4EEFF),
    );
  }
}
