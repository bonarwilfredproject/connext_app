import 'dart:async';

import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:connext_app/services/firebase_services.dart';
import 'package:connext_app/models/user_model.dart';
import 'package:connext_app/constants/decoration_constant.dart';
import 'package:connext_app/pages/auth/log_in_page.dart';
import 'package:connext_app/widgets/app_section_card.dart';
import 'package:connext_app/widgets/custom_appbar.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/widgets/role_selector.dart';
import 'package:connext_app/widgets/tombol_sementara.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class _PhoneVerificationState {
  final String? verificationId;
  final PhoneAuthCredential? autoCredential;

  const _PhoneVerificationState({this.verificationId, this.autoCredential});
}

class _CountryDialOption {
  final String label;
  final String dialCode;

  const _CountryDialOption({required this.label, required this.dialCode});
}

class DaftarPage extends StatefulWidget {
  const DaftarPage({super.key});

  @override
  State<DaftarPage> createState() => _DaftarPageState();
}

class _DaftarPageState extends State<DaftarPage> {
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

  String role = "Committee";
  bool isVisible = true;
  bool isLoadingSignUp = false;
  DateTime? _otpBlockedUntil;
  String? _pendingOtpTargetPhone;
  String? _pendingOtpVerificationId;
  DateTime? _pendingOtpExpiresAt;
  late _CountryDialOption _selectedCountry;
  final GlobalKey<FormState> _formKey = GlobalKey();
  TextEditingController namaController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCountry = _countryOptions.first;
  }

  @override
  void dispose() {
    namaController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();

    if (code == 'otp-timeout' ||
        message.contains('timed out') ||
        message.contains('timeout')) {
      return 'OTP request timed out. Please tap Sign Up again.';
    }

    if (code == 'too-many-requests' ||
        message.contains('unusual activity') ||
        message.contains('blocked all requests')) {
      return 'This device is temporarily blocked due to too many OTP attempts. Please try again in 30-60 minutes and switch your internet connection.';
    }

    if (code == 'captcha-check-failed' || message.contains('recaptcha')) {
      return 'reCAPTCHA verification failed. Please ensure a stable connection, active Google Play Services, and try again.';
    }

    if (code == 'invalid-app-credential' ||
        message.contains('missing a valid app identifier') ||
        message.contains('play integrity')) {
      return 'Android app verification with Firebase failed. Ensure debug SHA-1 and SHA-256 are added in Firebase Console.';
    }

    return e.message ?? 'Failed to register user';
  }

  Future<_PhoneVerificationState> _requestOtpVerification(
    String e164Phone,
  ) async {
    final completer = Completer<_PhoneVerificationState>();
    Timer? failSafeTimer;

    void completeWithState(_PhoneVerificationState state) {
      if (completer.isCompleted) return;
      failSafeTimer?.cancel();
      completer.complete(state);
    }

    void completeWithError(FirebaseAuthException exception) {
      if (completer.isCompleted) return;
      failSafeTimer?.cancel();
      completer.completeError(exception);
    }

    failSafeTimer = Timer(const Duration(seconds: 75), () {
      completeWithError(
        FirebaseAuthException(
          code: 'otp-timeout',
          message: 'OTP request timed out. Please try again.',
        ),
      );
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: e164Phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) {
        completeWithState(_PhoneVerificationState(autoCredential: credential));
      },
      verificationFailed: (exception) {
        completeWithError(exception);
      },
      codeSent: (verificationId, _) {
        completeWithState(
          _PhoneVerificationState(verificationId: verificationId),
        );
      },
      codeAutoRetrievalTimeout: (verificationId) {
        completeWithState(
          _PhoneVerificationState(verificationId: verificationId),
        );
      },
    );

    return completer.future;
  }

  Future<String?> _showOtpDialog(String phoneNumber) async {
    String enteredOtp = '';

    final smsCode = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Verify Phone Number', style: styleText()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OTP code has been sent to $phoneNumber',
                style: styleText(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                keyboardType: TextInputType.number,
                maxLength: 6,
                onChanged: (value) {
                  enteredOtp = value.trim();
                },
                decoration: decorationConstant(
                  hintText: 'Input 6-digit OTP code',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final code = enteredOtp;
                if (!RegExp(r'^\d{6}$').hasMatch(code)) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('OTP code must be 6 digits')),
                  );
                  return;
                }

                Navigator.pop(context, code);
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );

    return smsCode;
  }

  Future<void> _registerWithOtp() async {
    if (isLoadingSignUp) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoadingSignUp = true;
    });

    try {
      final rawPhone = phoneController.text.trim();

      final e164Phone = FirebaseServices.normalizePhoneToE164(
        rawPhone,
        countryDialCode: _selectedCountry.dialCode,
      );

      final hasReusableSession =
          _pendingOtpTargetPhone == e164Phone &&
          (_pendingOtpVerificationId ?? '').isNotEmpty &&
          _pendingOtpExpiresAt != null &&
          DateTime.now().isBefore(_pendingOtpExpiresAt!);

      final now = DateTime.now();
      if (!hasReusableSession &&
          _otpBlockedUntil != null &&
          now.isBefore(_otpBlockedUntil!)) {
        final wait = _otpBlockedUntil!.difference(now).inMinutes + 1;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'OTP is temporarily limited. Please try again in about $wait minutes.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hasReusableSession
                ? 'Using previously sent OTP for $e164Phone...'
                : 'Sending OTP to $e164Phone...',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      final verification = hasReusableSession
          ? _PhoneVerificationState(verificationId: _pendingOtpVerificationId)
          : await _requestOtpVerification(e164Phone);

      PhoneAuthCredential? credential = verification.autoCredential;

      if (credential == null) {
        final verificationId = verification.verificationId;
        if (verificationId == null || verificationId.isEmpty) {
          throw FirebaseAuthException(
            code: 'otp-missing-verification-id',
            message: 'Failed to get OTP verification session',
          );
        }

        final smsCode = await _showOtpDialog(e164Phone);
        if (smsCode == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('OTP verification canceled.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }

        credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode,
        );
      }

      await FirebaseServices.registerUserWithPhoneCredential(
        user: UserModel(
          nama: namaController.text.trim(),
          phone: e164Phone,
          password: passwordController.text,
          role: role,
        ),
        credential: credential,
      );

      _pendingOtpTargetPhone = null;
      _pendingOtpVerificationId = null;
      _pendingOtpExpiresAt = null;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration success. Please login.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LogInPage()),
      );
    } on FirebaseAuthException catch (e) {
      final friendlyMessage = _friendlyAuthError(e);
      final errorCode = e.code.toLowerCase();
      final errorMessage = (e.message ?? '').toLowerCase();

      if (errorCode == 'session-expired') {
        _pendingOtpTargetPhone = null;
        _pendingOtpVerificationId = null;
        _pendingOtpExpiresAt = null;
      }

      if (errorCode == 'too-many-requests' ||
          errorMessage.contains('unusual activity') ||
          errorMessage.contains('blocked all requests')) {
        _otpBlockedUntil = DateTime.now().add(const Duration(minutes: 30));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to register user'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoadingSignUp = false;
        });
      }
    }
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
                                    _pendingOtpTargetPhone = null;
                                    _pendingOtpVerificationId = null;
                                    _pendingOtpExpiresAt = null;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 6,
                              child: TextFormField(
                                keyboardType: TextInputType.number,
                                controller: phoneController,
                                onChanged: (_) {
                                  _pendingOtpTargetPhone = null;
                                  _pendingOtpVerificationId = null;
                                  _pendingOtpExpiresAt = null;
                                },
                                validator: (value) {
                                  final phone = (value ?? '').trim();
                                  if (phone.isEmpty) {
                                    return "Phone number can't be empty";
                                  }
                                  if (!RegExp(r'^\d+$').hasMatch(phone)) {
                                    return "Phone number must contain digits only";
                                  }
                                  if (phone.length < 4) {
                                    return "Phone number is too short";
                                  }
                                  if (phone.length > 15) {
                                    return "Phone number is too long";
                                  }
                                  return null;
                                },
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
                          isLoading: isLoadingSignUp,
                          text: "Sign Up",
                          onPressed: _registerWithOtp,
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
