import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:connext_app/services/user_controller.dart';
import 'package:connext_app/models/user_model.dart';
import 'package:connext_app/constants/decoration_constant.dart';
import 'package:connext_app/pages/auth/log_in_page.dart';
import 'package:connext_app/widgets/app_section_card.dart';
import 'package:connext_app/widgets/custom_appbar.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/widgets/role_selector.dart';
import 'package:connext_app/widgets/tombol_sementara.dart';
import 'package:flutter/material.dart';

class DaftarPage extends StatefulWidget {
  const DaftarPage({super.key});

  @override
  State<DaftarPage> createState() => _DaftarPageState();
}

class _DaftarPageState extends State<DaftarPage> {
  String role = "Committee";
  bool isVisible = true;
  final GlobalKey<FormState> _formKey = GlobalKey();
  TextEditingController namaController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      body: Stack(
        children: [
          EllipseBackground(),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: AppSectionCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Center(
                          child: Image.asset(
                            "assets/images/logo.png",
                            width: 80,
                            height: 80,
                          ),
                        ),
                        SizedBox(height: 20),
                        SizedBox(height: 32),
                        //nama field
                        Row(
                          children: [
                            Expanded(
                              child: Icon(
                                Icons.person,
                                color: Color(0XFF424874),
                              ),
                            ),

                            Expanded(
                              flex: 8,
                              child: Text("Nama", style: styleText()),
                            ),
                          ],
                        ),
                        TextFormField(
                          controller: namaController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "Nama wajib diisi";
                            }
                            return null;
                          },
                          style: TextStyle(
                            color: Color(0xFFF4EEFF),
                            fontSize: 12,
                          ),
                          decoration: decorationConstant(
                            hintText: "Masukkan nama anda",
                          ),
                        ),
                        SizedBox(height: 12),
                        //phone field
                        Row(
                          children: [
                            Expanded(
                              child: Icon(
                                Icons.phone,
                                color: Color(0XFF424874),
                              ),
                            ),

                            Expanded(
                              flex: 8,
                              child: Text("Phone", style: styleText()),
                            ),
                          ],
                        ),
                        TextFormField(
                          keyboardType: TextInputType.numberWithOptions(),
                          controller: phoneController,
                          validator: (value) {
                            final phone = (value ?? '').trim();
                            if (phone.isEmpty) {
                              return "Nomor telepon tidak boleh kosong";
                            }
                            if (!RegExp(r'^\d+$').hasMatch(phone)) {
                              return "Nomor telepon hanya boleh angka";
                            }
                            if (phone.length < 9) {
                              return "Nomor telepon minimal 9 digit";
                            }
                            if (phone.length > 15) {
                              return "Nomor telepon maksimal 15 digit";
                            }
                            return null;
                          },
                          style: TextStyle(
                            color: Color(0xFFF4EEFF),
                            fontSize: 12,
                          ),
                          decoration: decorationConstant(
                            hintText: "Masukkan nomor telepon",
                          ),
                        ),
                        SizedBox(height: 12),
                        //password field
                        Row(
                          children: [
                            Expanded(
                              child: Icon(
                                Icons.password,
                                color: Color(0XFF424874),
                              ),
                            ),

                            Expanded(
                              flex: 8,
                              child: Text("Password", style: styleText()),
                            ),
                          ],
                        ),
                        TextFormField(
                          validator: (value) {
                            final password = value ?? '';
                            final hasUppercase = RegExp(
                              r'[A-Z]',
                            ).hasMatch(password);
                            final hasLowercase = RegExp(
                              r'[a-z]',
                            ).hasMatch(password);
                            final hasNumber = RegExp(r'\d').hasMatch(password);
                            final hasSpecialChar = RegExp(
                              r'[!@#$%^&*(),.?":{}|<>_\-\\/\[\];\`~+=]',
                            ).hasMatch(password);
                            if (password.isEmpty) {
                              return "Password wajib diisi";
                            }
                            if (password.length < 8 ||
                                !hasUppercase ||
                                !hasLowercase ||
                                !hasNumber ||
                                !hasSpecialChar) {
                              return "Password harus terdiri dari minimal 8 karakter, memiliki huruf besar, huruf kecil, nomor, dan special character";
                            }
                            return null;
                          },
                          controller: passwordController,
                          obscureText: isVisible ? true : false,
                          obscuringCharacter: "*",
                          style: TextStyle(
                            color: Color(0xFFF4EEFF),
                            fontSize: 12,
                          ),
                          decoration: decorationConstant(
                            hintText: "Masukkan password",
                            suffixIcon: IconButton(
                              onPressed: () {
                                isVisible = !isVisible;
                                setState(() {});
                              },
                              icon: isVisible
                                  ? Icon(
                                      Icons.visibility_off,
                                      color: AppTheme.secondary,
                                    )
                                  : Icon(
                                      Icons.visibility,
                                      color: AppTheme.secondary,
                                    ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        //confirm password field
                        Row(
                          children: [
                            Expanded(
                              child: Icon(
                                Icons.password,
                                color: Color(0XFF424874),
                              ),
                            ),
                            Expanded(
                              flex: 8,
                              child: Text(
                                "Confirm password",
                                style: styleText(),
                              ),
                            ),
                          ],
                        ),
                        TextFormField(
                          validator: (value) {
                            final confirmPassword = value ?? '';
                            if (confirmPassword.isEmpty) {
                              return "Masukkan ulang password";
                            }
                            if (passwordController.text !=
                                confirmPasswordController.text) {
                              return "Password tidak sama";
                            }

                            return null;
                          },
                          controller: confirmPasswordController,
                          obscureText: isVisible ? true : false,
                          obscuringCharacter: "*",
                          style: TextStyle(
                            color: Color(0xFFF4EEFF),
                            fontSize: 12,
                          ),
                          decoration: decorationConstant(
                            hintText: "Masukkan ulang password",
                            suffixIcon: IconButton(
                              onPressed: () {
                                isVisible = !isVisible;
                                setState(() {});
                              },
                              icon: isVisible
                                  ? Icon(
                                      Icons.visibility_off,
                                      color: AppTheme.secondary,
                                    )
                                  : Icon(
                                      Icons.visibility,
                                      color: AppTheme.secondary,
                                    ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Daftar sebagai", style: styleText()),
                            const SizedBox(height: 10),

                            RoleSelector(
                              role: role,
                              onChanged: (value) {
                                setState(() {
                                  role = value;
                                });
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 28),
                        //tombol daftar
                        TombolSementara(
                          icon: Icons.app_registration,
                          width: double.infinity,
                          height: 54,
                          text: "Daftar",
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              bool exists = await UserController.isPhoneExists(
                                phoneController.text,
                              );

                              if (exists) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Nomor telepon sudah terdaftar",
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              } else {
                                UserController.registerUser(
                                  UserModel(
                                    nama: namaController.text,
                                    phone: phoneController.text,
                                    password: passwordController.text,
                                    role: role,
                                  ),
                                );
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LogInPage(),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF4EEFF),
    );
  }
}
