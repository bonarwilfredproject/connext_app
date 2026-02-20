import 'package:connext_app/materials/ellipse_background.dart';
import 'package:connext_app/materials/home_screen_appbar.dart';
import 'package:connext_app/materials/positioning_inside.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? namaUser;
  String? role;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeScreenAppbar(data: "Selamat datang, ${namaUser} as ${role}."),
      backgroundColor: Color(0xFFF4EEFF),
      body: Stack(
        children: [
          EllipseBackground(),
          PositioningInside(child: Container()),
        ],
      ),
    );
  }
}
