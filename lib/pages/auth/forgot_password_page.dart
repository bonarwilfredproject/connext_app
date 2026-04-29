import 'dart:async';

import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/constants/password_validation.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:connext_app/constants/decoration_constant.dart';
import 'package:connext_app/services/firebase_services.dart';
import 'package:connext_app/widgets/app_section_card.dart';
import 'package:connext_app/widgets/custom_appbar.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/widgets/tombol_sementara.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  static const List<_CountryDialOption> _countryOptions = [
    _CountryDialOption(label: 'Indonesia', dialCode: '+62'),
    _CountryDialOption(label: 'Singapore', dialCode: '+65'),
    _CountryDialOption(label: 'Malaysia', dialCode: '+60'),
    _CountryDialOption(label: 'Thailand', dialCode: '+66'),
    _CountryDialOption(label: 'Philippines', dialCode: '+63'),
    _CountryDialOption(label: 'United Kingdom', dialCode: '+44'),
    _CountryDialOption(label: 'Australia', dialCode: '+61'),
    _CountryDialOption(label: 'India', dialCode: '+91'),
  ];

  late _CountryDialOption _selectedCountry;
  final GlobalKey<FormState> _formKey = GlobalKey();
  TextEditingController phoneController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  bool isLoadingResetPassword = false;
  bool showNewPassword = false;
  bool showConfirmPassword = false;
  DateTime? _otpBlockedUntil;
  String? _pendingOtpTargetPhone;
  String? _pendingOtpVerificationId;
  DateTime? _pendingOtpExpiresAt;

  @override
  void initState() {
    super.initState();
    _selectedCountry = _countryOptions.first;
  }

  @override
  void dispose() {
    phoneController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();

    if (code == 'otp-timeout' ||
        message.contains('timed out') ||
        message.contains('timeout')) {
      return 'OTP request timed out. Please check your internet connection and try again. If it persists, try switching to a different network (WiFi/Mobile data).';
    }

    if (code == 'user-not-found' ||
        message.contains('not registered') ||
        message.contains('phone')) {
      return 'Phone number is not registered in the system.';
    }

    if (code == 'too-many-requests' ||
        message.contains('unusual activity') ||
        message.contains('blocked all requests')) {
      return 'This device is temporarily blocked due to too many attempts. Please try again in 30-60 minutes.';
    }

    return e.message ?? 'Failed to reset password';
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

    failSafeTimer = Timer(const Duration(seconds: 120), () {
      completeWithError(
        FirebaseAuthException(
          code: 'otp-timeout',
          message:
              'OTP request timed out. Please check your connection and try again.',
        ),
      );
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: e164Phone,
        timeout: const Duration(seconds: 90),
        verificationCompleted: (credential) {
          completeWithState(
            _PhoneVerificationState(autoCredential: credential),
          );
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
    } catch (e) {
      if (!completer.isCompleted) {
        completeWithError(
          FirebaseAuthException(
            code: 'otp-request-failed',
            message: 'Failed to request OTP. Please try again.',
          ),
        );
      }
    }

    return completer.future;
  }

  Future<String?> _showOtpDialog(
    String phoneNumber, {
    String? errorText,
  }) async {
    String enteredOtp = '';
    String? dialogError = errorText;

    final smsCode = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Verify Phone Number', style: styleText()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OTP code has been sent to $phoneNumber',
                    style: styleText().copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171A33),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.third.withOpacity(0.45),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enter your 6-digit OTP',
                          style: styleText().copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.third,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: styleText().copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 8,
                          ),
                          onChanged: (value) {
                            enteredOtp = value.trim();
                            if (dialogError != null) {
                              setDialogState(() {
                                dialogError = null;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            hintText: '000000',
                            hintStyle: styleText().copyWith(
                              fontSize: 24,
                              letterSpacing: 8,
                              color: AppTheme.secondary.withOpacity(0.4),
                              fontWeight: FontWeight.w600,
                            ),
                            counterText: '',
                            filled: true,
                            fillColor: AppTheme.primary.withOpacity(0.26),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: AppTheme.third.withOpacity(0.35),
                                width: 1.2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: AppTheme.third.withOpacity(0.5),
                                width: 1.4,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                              borderSide: BorderSide(
                                color: AppTheme.third,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      dialogError!,
                      style: styleText().copyWith(
                        fontSize: 12,
                        color: AppTheme.fourth,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: styleText().copyWith(color: AppTheme.secondary),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final code = enteredOtp;
                    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
                      setDialogState(() {
                        dialogError = 'OTP code must be 6 digits';
                      });
                      return;
                    }

                    Navigator.pop(context, code);
                  },
                  child: Text(
                    'Verify',
                    style: styleText().copyWith(
                      color: AppTheme.third,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    return smsCode;
  }

  Future<void> _resetPasswordWithOtp() async {
    if (isLoadingResetPassword) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoadingResetPassword = true;
    });

    try {
      final rawPhone = phoneController.text.trim();
      final newPassword = newPasswordController.text;

      final e164Phone = FirebaseServices.normalizePhoneToE164(
        rawPhone,
        countryDialCode: _selectedCountry.dialCode,
      );

      // Verify phone exists
      await FirebaseServices.findUserByPhoneForForgotPassword(
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

        String? otpDialogError;

        while (true) {
          final smsCode = await _showOtpDialog(
            e164Phone,
            errorText: otpDialogError,
          );
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

          final attemptCredential = PhoneAuthProvider.credential(
            verificationId: verificationId,
            smsCode: smsCode,
          );

          try {
            await FirebaseServices.resetPasswordWithPhoneVerification(
              phone: e164Phone,
              newPassword: newPassword,
              credential: attemptCredential,
            );
            credential = attemptCredential;
            break;
          } on FirebaseAuthException catch (e) {
            final code = e.code.toLowerCase();
            if (code == 'invalid-verification-code' ||
                code == 'session-expired') {
              otpDialogError = _friendlyAuthError(e);
              continue;
            }
            rethrow;
          }
        }
      } else {
        await FirebaseServices.resetPasswordWithPhoneVerification(
          phone: e164Phone,
          newPassword: newPassword,
          credential: credential,
        );
      }

      _pendingOtpTargetPhone = null;
      _pendingOtpVerificationId = null;
      _pendingOtpExpiresAt = null;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password reset success. Please login with your new password.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      final friendlyMessage = _friendlyAuthError(e);
      final errorCode = e.code.toLowerCase();
      final errorMessage = (e.message ?? '').toLowerCase();

      if (errorCode == 'otp-timeout' ||
          errorMessage.contains('timed out') ||
          errorMessage.contains('timeout')) {
        _pendingOtpTargetPhone = null;
        _pendingOtpVerificationId = null;
        _pendingOtpExpiresAt = null;
      }

      if (errorCode == 'too-many-requests' ||
          errorMessage.contains('unusual activity') ||
          errorMessage.contains('blocked all requests')) {
        _otpBlockedUntil = DateTime.now().add(const Duration(minutes: 30));
        _pendingOtpTargetPhone = null;
        _pendingOtpVerificationId = null;
        _pendingOtpExpiresAt = null;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reset password: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoadingResetPassword = false;
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
          SafeArea(
            child: Center(
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
                          const SizedBox(height: 24),
                          Text(
                            'Reset Your Password',
                            style: styleText().copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your phone number and new password',
                            style: styleText().copyWith(
                              fontSize: 12,
                              color: AppTheme.secondary.withAlpha(200),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Icon(Icons.phone, color: AppTheme.secondary),
                              const SizedBox(width: 8),
                              Text("Phone Number", style: styleText()),
                            ],
                          ),
                          const SizedBox(height: 8),
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
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.password,
                                color: AppTheme.secondary,
                              ),
                              const SizedBox(width: 8),
                              Text("New Password", style: styleText()),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: newPasswordController,
                            obscureText: !showNewPassword,
                            obscuringCharacter: "*",
                            style: TextStyle(
                              color: AppTheme.secondary,
                              fontSize: 12,
                            ),
                            validator: (value) {
                              return validateStrongPassword(value);
                            },
                            decoration: decorationConstant(
                              hintText: 'Please input your password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  showNewPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: AppTheme.secondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    showNewPassword = !showNewPassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.password,
                                color: AppTheme.secondary,
                              ),
                              const SizedBox(width: 8),
                              Text("Confirm Password", style: styleText()),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: confirmPasswordController,
                            obscureText: !showConfirmPassword,
                            obscuringCharacter: "*",
                            style: TextStyle(
                              color: AppTheme.secondary,
                              fontSize: 12,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              final passwordError = validateStrongPassword(
                                newPasswordController.text,
                              );
                              if (passwordError != null) {
                                return passwordError;
                              }
                              if (value != newPasswordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                            decoration: decorationConstant(
                              hintText: 'Please re-input your password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  showConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: AppTheme.secondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    showConfirmPassword = !showConfirmPassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          TombolSementara(
                            text: isLoadingResetPassword
                                ? 'Resetting...'
                                : 'Reset Password',
                            width: double.infinity,
                            height: 54,
                            onPressed: isLoadingResetPassword
                                ? null
                                : _resetPasswordWithOtp,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
