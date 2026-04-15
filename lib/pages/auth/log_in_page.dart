import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/constants/decoration_constant.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:connext_app/services/firebase_services.dart';
import 'package:connext_app/services/preferences_services.dart';
import 'package:connext_app/models/user_model.dart';
import 'package:connext_app/pages/home_page/home_page.dart';
import 'package:connext_app/widgets/app_section_card.dart';
import 'package:connext_app/widgets/custom_appbar.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/widgets/tombol_sementara.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LogInPage extends StatefulWidget {
  const LogInPage({super.key});

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  bool isVisible = true;
  bool isLoadingLogin = false;
  GlobalKey<FormState> _formKey = GlobalKey();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  Future<void> login() async {
    if (isLoadingLogin) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoadingLogin = true;
    });

    UserModel? login;
    try {
      login = await FirebaseServices.loginUser(
        phone: phoneController.text.trim(),
        password: passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed';
      if (e.code == 'user-not-found') {
        errorMessage = 'Phone is not registered';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password';
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
      return;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed, please try again')),
        );
      }
      return;
    } finally {
      if (mounted) {
        setState(() {
          isLoadingLogin = false;
        });
      }
    }

    if (login == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Phone number or password is wrong")),
        );
      }
      return;
    }

    final pref = PreferenceHandler();
    await pref.init();

    int? resolvedUserId = login.id;
    if (resolvedUserId == null || resolvedUserId <= 0) {
      final profile = await FirebaseServices.getCurrentUserProfile();
      final profileId = profile?.id;
      if (profileId != null && profileId > 0) {
        resolvedUserId = profileId;
      }
    }

    if (resolvedUserId == null || resolvedUserId <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login succeeded but user profile ID is invalid.'),
        ),
      );
      return;
    }

    await pref.saveUser(resolvedUserId, login.nama, login.role);

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
                            Icon(Icons.phone, color: AppTheme.secondary),
                            const SizedBox(width: 8),
                            Text("Phone Number", style: styleText()),
                          ],
                        ),
                        TextFormField(
                          keyboardType: TextInputType.numberWithOptions(),
                          validator: (value) {
                            final phone = (value ?? '').trim();

                            if (phone.isEmpty) {
                              return "Phone number can't be empty";
                            }

                            if (!RegExp(r'^\d+$').hasMatch(phone)) {
                              return "Phone number must be numbers";
                            }

                            if (phone.length < 9) {
                              return "Phone number must at least 9 digits";
                            }

                            return null;
                          },
                          controller: phoneController,
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
                              return "Password can't be empty";
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
                        SizedBox(height: 16),

                        //tombol login as committee button
                        TombolSementara(
                          width: double.infinity,
                          height: 54,
                          onPressed: login,
                          icon: Icons.login,
                          isLoading: isLoadingLogin,
                          text: "Log In",
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
      backgroundColor: AppTheme.primary,
    );
  }
}
