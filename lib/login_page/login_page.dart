import 'package:connext_app/materials/custom_appbar.dart';
import 'package:connext_app/materials/ellipse_background.dart';
import 'package:connext_app/materials/positioning_inside.dart';
import 'package:connext_app/materials/tombol_sementara.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(onPressed: () {}),
      body: Stack(
        children: [
          // ellipse di belakang layar (background)
          EllipseBackground(),
          //logo, dan field serta tombol
          PositioningInside(
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
                    children: [
                      Expanded(
                        child: TombolSementara(
                          width: 140,
                          height: 54,
                          onPressed: () {},
                          icon: Icons.group,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Icon(Icons.group, color: Color(0xFFF4EEFF)),
                              Text(
                                "Committee",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFFF4EEFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 40),
                      //login as attendee button
                      Expanded(
                        child: TombolSementara(
                          width: 140,
                          height: 54,
                          onPressed: () {},
                          icon: Icons.chair_alt,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Icon(Icons.chair_alt, color: Color(0xFFF4EEFF)),
                              Text(
                                "Attendee",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFFF4EEFF),
                                ),
                              ),
                            ],
                          ),
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
