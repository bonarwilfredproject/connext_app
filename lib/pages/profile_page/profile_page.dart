import 'dart:io';

import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:connext_app/pages/landing_page/landing_page.dart';
import 'package:connext_app/services/preferences_services.dart';
import 'package:connext_app/services/user_controller.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/widgets/tombol_sementara.dart';
import 'package:flutter/material.dart';
import 'package:connext_app/models/user_model.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  final int userId;
  final String role;
  const ProfilePage({super.key, required this.userId, required this.role});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<UserModel?> userFuture;
  final ImagePicker picker = ImagePicker();
  String? role;
  @override
  void initState() {
    super.initState();
    userFuture = UserController.getUserById(widget.userId);
    loadRole();
  }

  Future<void> loadRole() async {
    final pref = PreferenceHandler();
    await pref.init();

    role = pref.getRole();

    setState(() {});
  }

  Future<void> pickImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      await UserController.updateProfileImage(widget.userId, image.path);

      setState(() {
        userFuture = UserController.getUserById(widget.userId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: Text("Profile", style: styleText()),
        centerTitle: true,
        backgroundColor: AppTheme.primary,
      ),
      body: FutureBuilder<UserModel?>(
        future: userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return Center(
              child: Text("User tidak ditemukan", style: styleText()),
            );
          }

          final user = snapshot.data!;

          return Stack(
            children: [
              EllipseBackground(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: pickImage,
                        child: user.profileImage == null
                            ? Icon(Icons.account_circle, size: 100)
                            : CircleAvatar(
                                radius: 50,
                                backgroundImage: FileImage(
                                  File(user.profileImage!),
                                ),
                              ),
                      ),

                      const SizedBox(height: 20),

                      Text(user.nama, style: styleText()),

                      const SizedBox(height: 10),

                      Text(user.phone, style: styleText()),

                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.badge, color: AppTheme.secondary),
                          SizedBox(width: 8),
                          Text(role ?? "Unknown", style: styleText()),
                        ],
                      ),
                      const SizedBox(height: 40),
                      TombolSementara(
                        icon: Icons.logout,
                        height: 54,
                        width: double.infinity,
                        onPressed: () async {
                          final confirm = await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text("Logout"),
                              content: Text("Apakah kamu yakin ingin logout?"),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
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
                        text: "Logout",
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
