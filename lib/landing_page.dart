import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 244,
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
          ),
          Positioned(
            top: 200,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Image.asset(
                  "lib/assets/images/logo.png",
                  width: 79,
                  height: 79,
                ),
                SizedBox(height: 36),
                Text("Selamat Datang!", style: TextStyle(fontSize: 20)),
                SizedBox(height: 36),

                //tombol masuk
                Container(
                  width: 240,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Color(0xFF424874),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      "Masuk",
                      style: TextStyle(color: Color(0xFFF4EEFF), fontSize: 20),
                    ),
                  ),
                ),
                SizedBox(height: 12),

                //atau divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        indent: 76,
                        endIndent: 12,
                        color: Color(0xFF424874),
                      ),
                    ),
                    Text(
                      "atau",
                      style: TextStyle(fontSize: 20, color: Color(0xFF424874)),
                    ),
                    Expanded(
                      child: Divider(
                        indent: 12,
                        endIndent: 76,
                        color: Color(0xFF424874),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                //tombol daftar
                Container(
                  width: 240,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Color(0xFF424874),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      "Daftar",
                      style: TextStyle(color: Color(0xFFF4EEFF), fontSize: 20),
                    ),
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
