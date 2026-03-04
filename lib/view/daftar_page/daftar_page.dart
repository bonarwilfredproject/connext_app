import 'package:connext_app/database/user_controller.dart';
import 'package:connext_app/model/user_model.dart';
import 'package:connext_app/utils/decoration_constant.dart';
import 'package:connext_app/view/log_in_page/log_in_page.dart';
import 'package:connext_app/utils/custom_appbar.dart';
import 'package:connext_app/utils/ellipse_background.dart';
import 'package:connext_app/utils/positioning_inside.dart';
import 'package:connext_app/utils/tombol_sementara.dart';
import 'package:flutter/material.dart';

class DaftarPage extends StatefulWidget {
  const DaftarPage({super.key});

  @override
  State<DaftarPage> createState() => _DaftarPageState();
}

class _DaftarPageState extends State<DaftarPage> {
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
          PositioningInside(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36.0),
              child: Form(
                key: _formKey,
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
                    TextFormField(
                      controller: namaController,
                      validator: (value) {
                        if (value!.isEmpty || value == null) {
                          return "Nama wajib diisi";
                        }
                        return null;
                      },
                      style: TextStyle(color: Color(0xFFF4EEFF), fontSize: 12),
                      decoration: decorationConstant(hintText: "******"),
                    ),
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
                    TextFormField(
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
                      style: TextStyle(color: Color(0xFFF4EEFF), fontSize: 12),
                      decoration: decorationConstant(hintText: "******"),
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
                      obscureText: true,
                      obscuringCharacter: "*",
                      style: TextStyle(color: Color(0xFFF4EEFF), fontSize: 12),
                      decoration: decorationConstant(hintText: "******"),
                    ),
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
                    TextFormField(
                      validator: (value) {
                        final confirmPassword = value ?? '';
                        if (confirmPassword.isEmpty ||
                            confirmPassword == null) {
                          return "Masukkan ulang password";
                        }
                        if (passwordController.text !=
                            confirmPasswordController.text) {
                          return "Password tidak sama";
                        }

                        return null;
                      },
                      controller: confirmPasswordController,
                      obscureText: true,
                      obscuringCharacter: "*",
                      style: TextStyle(color: Color(0xFFF4EEFF), fontSize: 12),
                      decoration: decorationConstant(hintText: "******"),
                    ),
                    SizedBox(height: 20),
                    //tombol daftar
                    TombolSementara(
                      icon: Icons.app_registration,
                      width: 140,
                      height: 54,
                      text: "Daftar",
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          UserController.registerUser(
                            UserModel(
                              nama: namaController.text,
                              phone: phoneController.text,
                              password: passwordController.text,
                            ),
                          );
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LogInPage(),
                            ),
                          );
                        }
                      },
                    ),
                  ],
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
