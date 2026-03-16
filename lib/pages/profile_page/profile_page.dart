import 'dart:io';

import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:connext_app/pages/landing_page/landing_page.dart';
import 'package:connext_app/services/preferences_services.dart';
import 'package:connext_app/services/user_controller.dart';
import 'package:connext_app/widgets/app_section_card.dart';
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
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? tempImage;
  late Future<UserModel?> userFuture;
  final ImagePicker picker = ImagePicker();
  String? role;
  @override
  void initState() {
    super.initState();
    userFuture = UserController.getUserById(widget.userId);
    loadRole();
  }

  void showEditProfileSheet(UserModel user) {
    nameController.text = user.nama;
    phoneController.text = user.phone;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// HANDLE
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  "Edit Profile",
                  style: styleText().copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 20),

                /// NAMA
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: "Nama"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Nama tidak boleh kosong";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                /// PHONE
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "Nomor HP"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Nomor HP wajib diisi";
                    }

                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return "Nomor hanya boleh angka";
                    }

                    if (value.length < 10) {
                      return "Nomor HP tidak valid";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                /// SAVE BUTTON
                TombolSementara(
                  icon: Icons.save,
                  text: "Simpan",
                  width: double.infinity,
                  height: 50,
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> loadRole() async {
    final pref = PreferenceHandler();
    await pref.init();

    role = pref.getRole();

    setState(() {});
  }

  Future<void> changeRole() async {
    final pref = PreferenceHandler();
    await pref.init();

    String currentRole = role ?? "Attendee";
    String newRole = currentRole == "Committee" ? "Attendee" : "Committee";

    /// update database
    await UserController.updateRole(widget.userId, newRole);

    /// update preference
    await pref.saveRole(newRole);

    setState(() {
      role = newRole;
    });

    if (!mounted) return;

    /// kembali ke homepage dan refresh role
    Navigator.pop(context, true);
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
        elevation: 0,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    /// FOTO PROFILE
                    GestureDetector(
                      onTap: () => showEditProfileSheet(user),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppTheme.third,
                            backgroundImage: user.profileImage != null
                                ? FileImage(File(user.profileImage!))
                                : null,
                            child: user.profileImage == null
                                ? Icon(Icons.person, size: 50)
                                : null,
                          ),

                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      user.nama,
                      style: styleText().copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 24),
                    AppSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// NAMA
                          Row(
                            children: [
                              Icon(Icons.person, color: AppTheme.secondary),
                              SizedBox(width: 10),

                              Text(
                                "Nama",
                                style: styleText().copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Spacer(),

                              Text(user.nama, style: styleText()),
                            ],
                          ),

                          Divider(height: 20),

                          /// PHONE
                          Row(
                            children: [
                              Icon(Icons.phone, color: AppTheme.secondary),
                              SizedBox(width: 10),

                              Text(
                                "No HP",
                                style: styleText().copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Spacer(),

                              Text(user.phone, style: styleText()),
                            ],
                          ),

                          Divider(height: 20),

                          /// ROLE
                          Row(
                            children: [
                              Icon(Icons.badge, color: AppTheme.secondary),
                              const SizedBox(width: 10),

                              Text(
                                "Role",
                                style: styleText().copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const Spacer(),

                              Text(role ?? "Unknown", style: styleText()),

                              const SizedBox(width: 10),

                              GestureDetector(
                                onTap: changeRole,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.swap_horiz,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    /// LOGOUT BUTTON
                    TombolSementara(
                      icon: Icons.logout,
                      height: 54,
                      width: double.infinity,
                      onPressed: () async {
                        final confirm = await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: AppTheme.third,
                            title: Text("Logout", style: styleText()),
                            content: Text(
                              "Apakah kamu yakin ingin logout?",
                              style: styleText(),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text("Batal", style: styleText()),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text("Ya", style: styleText()),
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
            ],
          );
        },
      ),
    );
  }
}
