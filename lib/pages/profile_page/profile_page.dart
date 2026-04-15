import 'dart:async';
import 'dart:typed_data';

import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/constants/decoration_constant.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:connext_app/pages/landing_page/landing_page.dart';
import 'package:connext_app/services/firebase_services.dart';
import 'package:connext_app/services/preferences_services.dart';
import 'package:connext_app/widgets/app_section_card.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/widgets/profile_avatar.dart';
import 'package:connext_app/widgets/tombol_sementara.dart';
import 'package:flutter/material.dart';
import 'package:connext_app/models/user_model.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  final String role;
  const ProfilePage({super.key, required this.role});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Duration _roleChangeTimeout = Duration(seconds: 8);
  static const Duration _profileSaveTimeout = Duration(seconds: 25);
  String? phoneError;
  bool isChangingRole = false;
  bool isLoggingOut = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? tempImage;
  Uint8List? tempImageBytes;
  String? tempImageName;
  late Future<UserModel?> userFuture;
  final ImagePicker picker = ImagePicker();
  String? role;

  @override
  void initState() {
    super.initState();
    role = widget.role;
    userFuture = FirebaseServices.getCurrentUserProfile();
    loadRole();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> pickImageSource(Function(void Function()) setModalState) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: AppTheme.secondary,
                ),
                title: Text("Take a picture", style: styleText()),
                onTap: () async {
                  Navigator.pop(context);

                  final XFile? image = await picker.pickImage(
                    source: ImageSource.camera,
                  );

                  if (image != null) {
                    final bytes = await image.readAsBytes();
                    setModalState(() {
                      tempImage = image.path;
                      tempImageBytes = bytes;
                      tempImageName = image.name;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo, color: AppTheme.secondary),
                title: Text("Choose from Gallery", style: styleText()),
                onTap: () async {
                  Navigator.pop(context);

                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                  );

                  if (image != null) {
                    final bytes = await image.readAsBytes();
                    setModalState(() {
                      tempImage = image.path;
                      tempImageBytes = bytes;
                      tempImageName = image.name;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void showEditProfileSheet(UserModel user) {
    nameController.text = user.nama;
    phoneController.text = user.phone;
    bool isSavingProfile = false;
    bool isSheetClosed = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Wrap(
                children: [
                  Column(
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
                      const SizedBox(height: 16),
                      Form(
                        key: _formKey,
                        child: AppSectionCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Edit Profile",
                                style: styleText().copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),

                              const SizedBox(height: 20),

                              GestureDetector(
                                onTap: () => pickImageSource(setModalState),
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    ProfileAvatar(
                                      imagePath: tempImage != null
                                          ? tempImage
                                          : user.profileImage,
                                      radius: 45,
                                      backgroundColor: AppTheme.third,
                                      iconSize: 45,
                                    ),

                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.secondary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              /// NAMA
                              TextFormField(
                                style: TextStyle(
                                  color: AppTheme.secondary,
                                  fontSize: 14,
                                ),
                                controller: nameController,
                                decoration: decorationConstant(
                                  labelText: "Name",
                                  hintText: nameController.text,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Name can't be empty";
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              /// PHONE
                              TextFormField(
                                style: TextStyle(
                                  color: AppTheme.secondary,
                                  fontSize: 14,
                                ),
                                controller: phoneController,
                                keyboardType: TextInputType.number,
                                decoration: decorationConstant(
                                  labelText: "Phone Number",
                                  hintText: phoneController.text,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Phone number must be filled";
                                  }

                                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                    return "Phone number must be numbers";
                                  }

                                  if (value.length < 10) {
                                    return "Phone number is not valid";
                                  }

                                  if (phoneError != null) {
                                    return phoneError;
                                  }

                                  return null;
                                },
                                onChanged: (value) {
                                  if (phoneError != null) {
                                    setModalState(() {
                                      phoneError = null;
                                    });
                                  }
                                },
                              ),

                              const SizedBox(height: 24),

                              /// SAVE BUTTON
                              TombolSementara(
                                icon: Icons.save,
                                text: "Save",
                                width: double.infinity,
                                height: 50,
                                isLoading: isSavingProfile,
                                onPressed: () async {
                                  if (isSavingProfile) return;
                                  if (!_formKey.currentState!.validate())
                                    return;

                                  setModalState(() {
                                    isSavingProfile = true;
                                  });

                                  try {
                                    String newName = nameController.text.trim();
                                    String newPhone = phoneController.text
                                        .trim();

                                    if (newPhone != user.phone) {
                                      bool exists =
                                          await FirebaseServices.isPhoneExists(
                                            newPhone,
                                          );

                                      if (exists) {
                                        setModalState(() {
                                          phoneError =
                                              "Phone number is already used";
                                        });

                                        _formKey.currentState!.validate();
                                        return;
                                      }
                                    }

                                    await FirebaseServices.updateProfile(
                                      name: newName,
                                      phone: newPhone,
                                    ).timeout(_profileSaveTimeout);

                                    final pref = PreferenceHandler();
                                    await pref.init();
                                    await pref.saveNamaUser(newName);

                                    if (tempImageBytes != null) {
                                      await FirebaseServices.updateProfileImageBytes(
                                        tempImageBytes!,
                                        fileName: tempImageName,
                                      ).timeout(_profileSaveTimeout);
                                    } else if (tempImage != null) {
                                      await FirebaseServices.updateProfileImage(
                                        tempImage!,
                                      ).timeout(_profileSaveTimeout);
                                    }

                                    setState(() {
                                      tempImage = null;
                                      tempImageBytes = null;
                                      tempImageName = null;
                                      userFuture =
                                          FirebaseServices.getCurrentUserProfile();
                                    });

                                    if (!mounted) return;

                                    isSheetClosed = true;
                                    Navigator.pop(context);
                                  } catch (_) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Failed to update profile/photo. Please check your connection and Storage rules.",
                                        ),
                                      ),
                                    );
                                  } finally {
                                    if (mounted && !isSheetClosed) {
                                      setModalState(() {
                                        isSavingProfile = false;
                                      });
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      setState(() {
        tempImage = null;
        tempImageBytes = null;
        tempImageName = null;
      });
    });
  }

  Future<void> loadRole() async {
    final pref = PreferenceHandler();
    await pref.init();

    if (!mounted) return;

    setState(() {
      role = pref.getRole() ?? widget.role;
    });
  }

  Future<void> changeRole() async {
    if (isChangingRole) return;

    setState(() {
      isChangingRole = true;
    });

    try {
      final pref = PreferenceHandler();
      await pref.init();

      String currentRole = role ?? "Attendee";
      String newRole = currentRole == "Committee" ? "Attendee" : "Committee";

      /// Prioritize local role switch so UI never hangs on poor connection.
      await pref.saveRole(newRole);

      if (mounted) {
        setState(() {
          role = newRole;
        });
      }

      try {
        await FirebaseServices.updateRole(newRole).timeout(_roleChangeTimeout);
      } on TimeoutException {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Role updated locally. Firebase sync will continue when connection is stable",
              ),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Role updated locally. Firebase sync failed for now",
              ),
            ),
          );
        }
      }

      if (!mounted) return;

      /// kembali ke homepage dengan role terbaru
      Navigator.pop(context, newRole);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to change role")));
      }
    } finally {
      if (mounted) {
        setState(() {
          isChangingRole = false;
        });
      }
    }
  }

  Future<void> logout() async {
    if (isLoggingOut) return;

    setState(() {
      isLoggingOut = true;
    });

    try {
      final confirm = await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.third,
          title: Text("Log Out", style: styleText()),
          content: Text("Are you sure want to log out?", style: styleText()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel", style: styleText()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Yes", style: styleText()),
            ),
          ],
        ),
      );

      if (confirm == true) {
        final pref = PreferenceHandler();
        await pref.init();
        await FirebaseServices.logout();
        await pref.logout();

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LandingPage()),
          (route) => false,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoggingOut = false;
        });
      }
    }
  }

  Future<void> pickImage(UserModel user) async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        tempImage = image.path;
      });

      if (!mounted) return;

      /// tutup modal lama
      Navigator.pop(context);

      /// buka lagi modal dengan image baru
      showEditProfileSheet(user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
            return Center(child: Text("User is not found", style: styleText()));
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
                          ProfileAvatar(
                            imagePath: user.profileImage,
                            radius: 50,
                            backgroundColor: AppTheme.third,
                            iconSize: 50,
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
                                "Name",
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
                                "Phone Number",
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
                                onTap: isChangingRole ? null : changeRole,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: isChangingRole
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Icon(
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
                      isLoading: isLoggingOut,
                      onPressed: logout,
                      text: "Log Out",
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
