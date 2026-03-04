import 'package:connext_app/database/preferences.dart';
import 'package:connext_app/database/user_controller.dart';
import 'package:connext_app/model/user_model.dart';
import 'package:connext_app/utils/style_text.dart';
import 'package:connext_app/utils/tombol_sementara.dart';
import 'package:connext_app/view/landing_page/landing_page.dart';
import 'package:connext_app/utils/ellipse_background.dart';
import 'package:connext_app/utils/home_screen_appbar.dart';
import 'package:connext_app/utils/positioning_inside.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.namaUser, required this.role});
  final String namaUser;
  final String role;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<UserModel> dataUser = [];
  @override
  void initState() {
    super.initState();
    getDataUser();
  }

  Future<void> getDataUser() async {
    await Future.delayed(Duration(seconds: 3));
    dataUser = await UserController.getAllUser();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeScreenAppbar(
        data: "Selamat datang, ${widget.namaUser} as ${widget.role}.",
        onTap: () async {
          final confirm = await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text("Logout"),
              content: Text("Apakah kamu yakin ingin logout?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text("Batal"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text("Ya"),
                ),
              ],
            ),
          );

          if (confirm == true) {
            final pref = PreferenceHandler();
            await pref.init();
            await pref.logout();

            if (!mounted) return;

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => LandingPage()),
              (route) => false,
            );
          }
        },
      ),
      backgroundColor: Color(0xFFF4EEFF),
      body: Stack(
        children: [
          EllipseBackground(),
          PositioningInside(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.role == "Committee")
                      TombolSementara(
                        onPressed: () {},
                        height: 54,
                        width: 164,
                        icon: Icons.edit,
                        text: "Buat Event",
                      ),
                    SizedBox(height: 40),
                    Text("Events:", style: styleText()),
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color(0xffF4EEFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.event),
                              SizedBox(width: 8),
                              Text("Belajar Bareng", style: styleText()),
                            ],
                          ),

                          Row(
                            children: [
                              Icon(Icons.location_pin),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Toko Kopi Palapa, Jakarta",
                                  style: styleText(),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: Icon(Icons.info),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.people),
                              SizedBox(width: 8),
                              Text("1 Peserta", style: styleText()),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.numbers),
                              SizedBox(width: 8),
                              Text("1", style: styleText()),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (widget.role == "Attendee")
                      TombolSementara(
                        onPressed: () {},
                        text: "Lihat Event",
                        height: 54,
                        width: 164,
                        icon: Icons.event,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
