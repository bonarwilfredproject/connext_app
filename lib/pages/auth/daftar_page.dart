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
                              child: Text("Name", style: styleText()),
                            ),
                          ],
                        ),
                        TextFormField(
                          controller: namaController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "Name must be filled";
                            }
                            return null;
                          },
                          style: TextStyle(
                            color: AppTheme.secondary,
                            fontSize: 12,
                          ),
                          decoration: decorationConstant(
                            hintText: "Please input your name",
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
                              child: Text("Phone Number", style: styleText()),
                            ),
                          ],
                        ),
                        TextFormField(
                          keyboardType: TextInputType.numberWithOptions(),
                          controller: phoneController,
                          validator: (value) {
                            final phone = (value ?? '').trim();
                            if (phone.isEmpty) {
                              return "Phone number can't be empty";
                            }
                            if (!RegExp(r'^\d+$').hasMatch(phone)) {
                              return "Phone number can only be numbers";
                            }
                            if (phone.length < 9) {
                              return "Phone number must be at least 9 digits";
                            }
                            if (phone.length > 15) {
                              return "Phone number can't be more than 15 digits";
                            }
                            return null;
                          },
                          style: TextStyle(
                            color: AppTheme.secondary,
                            fontSize: 12,
                          ),
                          decoration: decorationConstant(
                            hintText: "Please input your phone number",
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
                              return "Password must be filled";
                            }
                            if (password.length < 8 ||
                                !hasUppercase ||
                                !hasLowercase ||
                                !hasNumber ||
                                !hasSpecialChar) {
                              return "Password must have at least 8 characters, an uppercase, a lowercase, a number, and a special character";
                            }
                            return null;
                          },
                          controller: passwordController,
                          obscureText: isVisible ? true : false,
                          obscuringCharacter: "*",
                          style: TextStyle(
                            color: AppTheme.secondary,
                            fontSize: 12,
                          ),
                          decoration: decorationConstant(
                            hintText: "Please input your password",
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
                              return "Please re-input your password";
                            }
                            if (passwordController.text !=
                                confirmPasswordController.text) {
                              return "Password is not match";
                            }

                            return null;
                          },
                          controller: confirmPasswordController,
                          obscureText: isVisible ? true : false,
                          obscuringCharacter: "*",
                          style: TextStyle(
                            color: AppTheme.secondary,
                            fontSize: 12,
                          ),
                          decoration: decorationConstant(
                            hintText: "Please re-input your password",
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
                            Text("Sign Up As", style: styleText()),
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
                          text: "Sign Up",
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              bool exists = await UserController.isPhoneExists(
                                phoneController.text,
                              );

                              if (exists) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Phone number is already registered",
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
