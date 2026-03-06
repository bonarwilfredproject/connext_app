import 'package:connext_app/services/preferences_services.dart';
import 'package:connext_app/services/user_controller.dart';
import 'package:connext_app/models/user_model.dart';
import 'package:connext_app/pages/home_page/home_page.dart';
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
  GlobalKey<FormState> _formKey = GlobalKey();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  String selectedRole = "Attendee";
  Future<void> loginAs(String role) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final UserModel? login = await UserController.loginUser(
      phone: phoneController.text,
      password: passwordController.text,
    );

    if (login == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Phone atau password belum terdaftar")),
      );
      return;
    }

    final pref = PreferenceHandler();
    await pref.init();

    await pref.storingIsLogin(true);
    await pref.saveUser(login.id!, login.nama, role);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(namaUser: login.nama, role: role),
      ),
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
          PositioningInside(
            //logo
            child: SingleChildScrollView(
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
                        obscureText: true,
                        obscuringCharacter: "*",
                        style: TextStyle(
                          color: Color(0xFFF4EEFF),
                          fontSize: 12,
                        ),
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
                              width: double.infinity,
                              height: 54,
                              onPressed: () async {
                                await loginAs("Committee");
                              },
                              icon: Icons.group,
                              text: "Committee",
                            ),
                          ),
                          SizedBox(width: 12),
                          //login as attendee button
                          Expanded(
                            child: TombolSementara(
                              width: double.infinity,
                              height: 54,
                              onPressed: () async {
                                await loginAs("Attendee");
                              },
                              icon: Icons.chair_alt,
                              text: "Attendee",
                            ),
                          ),
                        ],
                      ),

                      //tombol daftar
                    ],
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
