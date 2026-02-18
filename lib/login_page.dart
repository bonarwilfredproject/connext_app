import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFF4EEFF),
        leading: Icon(
          Icons.arrow_back,
          color: Color(0xFF424874),
        ), //tombol panah ke belakang
      ),
      body: Stack(
        children: [
          // ellipse di belakang layar (background)
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
          //logo, dan field serta tombol
          Positioned(
            top: 96,
            left: 0,
            right: 0,
            //logo
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
                    height: 40,
                    child: TextField(
                      style: TextStyle(color: Color(0xFFF4EEFF), fontSize: 12),
                      decoration: InputDecoration(
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
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      "Login sebagai",
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  //tombol login as committee button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        width: 140,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Color(0xFF424874),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Icon(Icons.group, color: Color(0xFFF4EEFF)),
                            Text(
                              "Committee",
                              style: TextStyle(
                                color: Color(0xFFF4EEFF),
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Spacer(),
                      //login as attendee button
                      Container(
                        width: 140,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Color(0xFF424874),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Icon(Icons.chair_alt, color: Color(0xFFF4EEFF)),
                            Text(
                              "Attendee",
                              style: TextStyle(
                                color: Color(0xFFF4EEFF),
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
