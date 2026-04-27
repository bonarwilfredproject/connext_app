import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/constants/decoration_constant.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:connext_app/pages/auth/daftar_page.dart';
import 'package:connext_app/services/firebase_services.dart';
import 'package:connext_app/pages/attendee_event_page/attendee_event_page.dart';
import 'package:connext_app/services/preferences_services.dart';
import 'package:connext_app/services/event_participant_controller.dart';
import 'package:connext_app/models/user_model.dart';
import 'package:connext_app/pages/auth/forgot_password_page.dart';
import 'package:connext_app/pages/event_invite_page.dart';
import 'package:connext_app/pages/home_page/home_page.dart';
import 'package:connext_app/widgets/app_section_card.dart';
import 'package:connext_app/widgets/custom_appbar.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/widgets/tombol_sementara.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class _CountryDialOption {
  final String label;
  final String dialCode;

  const _CountryDialOption({required this.label, required this.dialCode});
}

class LogInPage extends StatefulWidget {
  const LogInPage({super.key});

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  static const List<_CountryDialOption> _countryOptions = [
    _CountryDialOption(label: 'Indonesia', dialCode: '+62'),
    _CountryDialOption(label: 'Singapore', dialCode: '+65'),
    _CountryDialOption(label: 'Malaysia', dialCode: '+60'),
    _CountryDialOption(label: 'Thailand', dialCode: '+66'),
    _CountryDialOption(label: 'Philippines', dialCode: '+63'),
    _CountryDialOption(label: 'United States', dialCode: '+1'),
    _CountryDialOption(label: 'United Kingdom', dialCode: '+44'),
    _CountryDialOption(label: 'Australia', dialCode: '+61'),
    _CountryDialOption(label: 'India', dialCode: '+91'),
  ];

  bool isVisible = true;
  bool isLoadingLogin = false;
  final GlobalKey<FormState> _formKey = GlobalKey();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  late _CountryDialOption _selectedCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = _countryOptions.first;
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

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
      final normalizedPhone = FirebaseServices.normalizePhoneToE164(
        phoneController.text.trim(),
        countryDialCode: _selectedCountry.dialCode,
      );

      login = await FirebaseServices.loginUser(
        phone: normalizedPhone,
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

    final pendingJoinEventId = pref.getPendingJoinEventId();
    if (pendingJoinEventId > 0) {
      final alreadyJoined = await EventParticipantController.isJoined(
        resolvedUserId,
        pendingJoinEventId,
      );

      await pref.clearPendingJoinEventId();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => alreadyJoined
              ? AttendeeEventPage(
                  userId: resolvedUserId!,
                  eventId: pendingJoinEventId,
                )
              : EventInvitePage(eventId: pendingJoinEventId),
        ),
        (route) => false,
      );
      return;
    }

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
                        Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: DropdownButtonFormField<_CountryDialOption>(
                                value: _selectedCountry,
                                isExpanded: true,
                                decoration: decorationConstant(
                                  hintText: 'Country',
                                ),
                                items: _countryOptions.map((option) {
                                  return DropdownMenuItem<_CountryDialOption>(
                                    value: option,
                                    child: Text(
                                      '${option.label} (${option.dialCode})',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppTheme.secondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _selectedCountry = value;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 6,
                              child: TextFormField(
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  final phone = (value ?? '').trim();

                                  if (phone.isEmpty) {
                                    return "Phone number can't be empty";
                                  }

                                  if (!RegExp(r'^\d+$').hasMatch(phone)) {
                                    return "Phone number must contain digits only";
                                  }

                                  if (phone.length < 8) {
                                    return "Phone number is too short";
                                  }

                                  if (phone.length > 15) {
                                    return "Phone number is too long";
                                  }

                                  if (_selectedCountry.dialCode == '+62' &&
                                      !phone.startsWith('8')) {
                                    return "For Indonesia number, use local format starting with 8";
                                  }

                                  if (RegExp(r'^(\d)\1+$').hasMatch(phone)) {
                                    return "Phone number seems invalid";
                                  }

                                  return null;
                                },
                                controller: phoneController,
                                style: TextStyle(
                                  color: AppTheme.secondary,
                                  fontSize: 12,
                                ),
                                decoration: decorationConstant(
                                  hintText: 'Local phone number',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Enter your local number without country code. Example: 8123456789',
                            style: TextStyle(
                              color: AppTheme.secondary.withOpacity(0.7),
                              fontSize: 11,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        //password field
                        Row(
                          children: [
                            const Icon(
                              Icons.password,
                              color: AppTheme.secondary,
                            ),
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
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgotPasswordPage(),
                                ),
                              );
                            },
                            child: Text(
                              'Forgot Password?',
                              style: styleText().copyWith(
                                color: AppTheme.third,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: AppTheme.secondary.withOpacity(0.72),
                                  fontSize: 13,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const DaftarPage(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Sign Up',
                                  style: styleText().copyWith(
                                    color: AppTheme.third,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
