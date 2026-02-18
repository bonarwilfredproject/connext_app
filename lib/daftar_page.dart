import 'package:flutter/material.dart';

class DaftarPage extends StatelessWidget {
  const DaftarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFF4EEFF),
        leading: Icon(Icons.arrow_back, color: Color(0xFF424874)),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 140,
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
            top: 96,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36.0),
              child: Column(
                children: [
                  Image.asset(
                    "lib/assets/images/logo.png",
                    width: 79,
                    height: 79,
                  ),
                  SizedBox(height: 32),
                  //nama field
                  Row(
                    children: [
                      Expanded(
                        child: Icon(Icons.person, color: Color(0XFF424874)),
                      ),

                      Expanded(
                        flex: 8,
                        child: Text(
                          "Nama",
                          style: TextStyle(
                            color: Color(0XFF424874),
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 40,
                    child: TextField(
                      style: TextStyle(color: Color(0xFFF4EEFF), fontSize: 12),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        hint: Text(
                          "e.x: Bambi",
                          style: TextStyle(
                            color: Color(0xFFF4EEFF),
                            fontSize: 12,
                          ),
                        ),
                        fillColor: Color(0xFFA6B1E1),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  //phone field
                  Row(
                    children: [
                      Expanded(
                        child: Icon(Icons.phone, color: Color(0XFF424874)),
                      ),

                      Expanded(
                        flex: 8,
                        child: Text(
                          "Phone",
                          style: TextStyle(
                            color: Color(0XFF424874),
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 80,
                    child: TextField(
                      style: TextStyle(color: Color(0xFFF4EEFF), fontSize: 12),
                      decoration: InputDecoration(
                        helperStyle: TextStyle(
                          fontSize: 12,
                          color: Color(0XFF424874),
                        ),
                        helperMaxLines: 2,
                        helperText:
                            "*Kerahasiaan nomor telepon sepenuhnya menjadi tanggung jawab panitia",
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        hint: Text(
                          "08123456789",
                          style: TextStyle(
                            color: Color(0xFFF4EEFF),
                            fontSize: 12,
                          ),
                        ),
                        fillColor: Color(0xFFA6B1E1),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 4),
                  //password field
                  Row(
                    children: [
                      Expanded(
                        child: Icon(Icons.password, color: Color(0XFF424874)),
                      ),

                      Expanded(
                        flex: 8,
                        child: Text(
                          "Password",
                          style: TextStyle(
                            color: Color(0XFF424874),
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 40,
                    child: TextField(
                      obscureText: true,
                      obscuringCharacter: "*",
                      style: TextStyle(color: Color(0xFFF4EEFF), fontSize: 12),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        hint: Text(
                          "********",
                          style: TextStyle(
                            color: Color(0xFFF4EEFF),
                            fontSize: 12,
                          ),
                        ),
                        fillColor: Color(0xFFA6B1E1),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  //confirm password field
                  Row(
                    children: [
                      Expanded(
                        child: Icon(Icons.password, color: Color(0XFF424874)),
                      ),
                      Expanded(
                        flex: 8,
                        child: Text(
                          "Confirm password",
                          style: TextStyle(
                            color: Color(0XFF424874),
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 80,
                    child: TextField(
                      obscureText: true,
                      obscuringCharacter: "*",
                      style: TextStyle(color: Color(0xFFF4EEFF), fontSize: 12),
                      decoration: InputDecoration(
                        helperStyle: TextStyle(
                          fontSize: 12,
                          color: Color(0XFF424874),
                        ),
                        helperMaxLines: 2,
                        helperText:
                            "*Kata sandi harus terdiri dari minimal 8 karakter dengan huruf kapital, angka, dan tanda baca",
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        hint: Text(
                          "********",
                          style: TextStyle(
                            color: Color(0xFFF4EEFF),
                            fontSize: 12,
                          ),
                        ),

                        fillColor: Color(0xFFA6B1E1),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 12),
                  //tombol daftar
                  Container(
                    width: 104,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(0xFF424874),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        "Daftar",
                        style: TextStyle(
                          color: Color(0xFFF4EEFF),
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  //tombol daftar
                ],
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF4EEFF),
    );
  }
}
