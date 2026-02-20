import 'package:connext_app/materials/ellipse_background.dart';
import 'package:connext_app/materials/positioning_inside.dart';
import 'package:connext_app/materials/tombol_sementara.dart';
import 'package:flutter/foundation.dart';
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
                TombolSementara(
                  onPressed: () {},
                  width: 240,
                  height: 56,
                  child: Text("Masuk", style: TextStyle(fontSize: 20)),
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
                TombolSementara(
                  onPressed: () {},
                  width: 240,
                  height: 56,
                  child: Text("Daftar", style: TextStyle(fontSize: 20)),
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
