import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:connext_app/services/preferences_services.dart';
import 'package:connext_app/services/user_controller.dart';
import 'package:connext_app/models/user_model.dart';
import 'package:connext_app/pages/home_page/home_page.dart';
import 'package:connext_app/widgets/app_section_card.dart';
import 'package:connext_app/widgets/custom_appbar.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/widgets/positioning_inside.dart';
import 'package:connext_app/widgets/tombol_sementara.dart';
import 'package:flutter/material.dart';

class LogInPage extends StatefulWidget {
  const LogInPage({super.key});

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  bool isVisible = true;
  GlobalKey<FormState> _formKey = GlobalKey();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  Future<void> login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final UserModel? login = await UserController.loginUser(
      phone: phoneController.text,
      password: passwordController.text,
    );

    if (login == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Phone atau password salah")));
      return;
    }

    final pref = PreferenceHandler();
    await pref.init();

    await pref.saveUser(login.id!, login.nama, login.role);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false,
    );
  }

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
          // ellipse di belakang layar (background)
          EllipseBackground(),
          //logo, dan field serta tombol
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
                        SizedBox(height: 24),
                        //phone field
                        Row(
                          children: [
                            Icon(Icons.phone, color: Color(0XFF424874)),
                            const SizedBox(width: 8),
                            Text("Phone", style: styleText()),
                          ],
                        ),
                        TextFormField(
                          validator: (value) {
                            final phone = (value ?? '').trim();

                            if (phone.isEmpty) {
                              return "Nomor telepon tidak boleh kosong";
                            }

                            if (!RegExp(r'^\d+$').hasMatch(phone)) {
                              return "Nomor telepon hanya boleh angka";
                            }

                            if (phone.length < 9) {
                              return "Minimal 9 digit";
                            }

                            return null;
                          },
                          controller: phoneController,
                          style: TextStyle(
                            color: Color(0xFFF4EEFF),
                            fontSize: 12,
                          ),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                            hint: Text(
                              "Masukkan nomor telepon",
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
                        SizedBox(height: 12),
                        //password field
                        Row(
                          children: [
                            Icon(Icons.password, color: Color(0XFF424874)),
                            const SizedBox(width: 8),
                            Text("Password", style: styleText()),
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
                              return "Password tidak boleh kosong";
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
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              onPressed: () {
                                isVisible = !isVisible;
                                setState(() {});
                              },
                              icon: isVisible
                                  ? Icon(
                                      Icons.visibility_off,
                                      color: AppTheme.primary,
                                    )
                                  : Icon(
                                      Icons.visibility,
                                      color: AppTheme.primary,
                                    ),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                            hint: Text(
                              "Masukkan password",
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
                        SizedBox(height: 16),

                        //tombol login as committee button
                        TombolSementara(
                          width: double.infinity,
                          height: 54,
                          onPressed: login,
                          icon: Icons.login,
                          text: "Login",
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
