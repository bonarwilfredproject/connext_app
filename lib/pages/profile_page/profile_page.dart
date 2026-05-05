import 'dart:async';
import 'dart:typed_data';

import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/constants/decoration_constant.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:connext_app/pages/auth/reset_password_page.dart';
import 'package:connext_app/pages/landing_page/landing_page.dart';
import 'package:connext_app/services/firebase_services.dart';
import 'package:connext_app/services/preferences_services.dart';
import 'package:connext_app/widgets/app_section_card.dart';
import 'package:connext_app/widgets/connext_app_bar.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/widgets/profile_avatar.dart';
import 'package:connext_app/widgets/tombol_sementara.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:connext_app/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class _CountryDialOption {
  final String label;
  final String dialCode;

  const _CountryDialOption({required this.label, required this.dialCode});
}

class _PhoneVerificationState {
  final String? verificationId;
  final PhoneAuthCredential? autoCredential;

  const _PhoneVerificationState({this.verificationId, this.autoCredential});
}

class ProfilePage extends StatefulWidget {
  final String role;
  const ProfilePage({super.key, required this.role});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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

  static const Duration _roleChangeTimeout = Duration(seconds: 8);
  static const Duration _profileSaveTimeout = Duration(seconds: 25);
  static const Duration _otpRequestCooldown = Duration(seconds: 45);
  String? phoneError;
  bool isChangingRole = false;
  bool isLoggingOut = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? tempImage;
  Uint8List? tempImageBytes;
  String? tempImageName;
  final ImagePicker picker = ImagePicker();
  String? role;
  late _CountryDialOption _selectedCountry;
  String? _pendingOtpTargetPhone;
  String? _pendingOtpVerificationId;
  DateTime? _pendingOtpExpiresAt;
  String? _lastOtpRequestedPhone;
  DateTime? _lastOtpRequestedAt;
  Timer? _phoneValidationDebounce;
  String? _lastCheckedPhoneE164;

  @override
  void initState() {
    super.initState();
    role = widget.role;
    _selectedCountry = _countryOptions.first;
    loadRole();
  }

  void _applyStoredPhoneToForm(String storedPhone) {
    final raw = storedPhone.trim();
    if (raw.isEmpty) {
      _selectedCountry = _countryOptions.first;
      phoneController.clear();
      return;
    }

    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.startsWith('00') && digits.length > 2) {
      digits = digits.substring(2);
    }

    final sorted = [..._countryOptions]
      ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));

    for (final option in sorted) {
      final dialDigits = option.dialCode.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.startsWith(dialDigits) && digits.length > dialDigits.length) {
        _selectedCountry = option;
        phoneController.text = digits.substring(dialDigits.length);
        return;
      }
    }

    _selectedCountry = _countryOptions.first;
    phoneController.text = digits;
  }

  String? _validatePhoneNumber(String phone, {String? countryDialCode}) {
    if (!RegExp(r'^\d+$').hasMatch(phone)) {
      return 'Phone number must contain digits only';
    }

    if (phone.length < 8) {
      return 'Phone number is too short';
    }

    if (phone.length > 15) {
      return 'Phone number is too long';
    }

    // Validasi khusus untuk Indonesia: harus dimulai dengan 8
    if (countryDialCode == '+62' && !phone.startsWith('8')) {
      return 'For Indonesia number, use local format starting with 8';
    }

    if (RegExp(r'^(\d)\1+$').hasMatch(phone)) {
      return 'Phone number seems invalid (repeating digits)';
    }

    return null;
  }

  String _friendlyPhoneUpdateError(FirebaseAuthException e) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();

    if (code == 'otp-cooldown') {
      return e.message ?? 'Please wait before requesting OTP again';
    }

    if (code == 'otp-timeout' ||
        message.contains('timed out') ||
        message.contains('timeout')) {
      return 'OTP request timed out. Please check your internet connection and tap Save again.';
    }

    if (code == 'invalid-phone-number' ||
        message.contains('invalid phone') ||
        message.contains('missing or invalid') ||
        message.contains('phone number format')) {
      return 'Phone number format is invalid. Please use an active real number with the correct country code.';
    }

    if (code == 'phone-already-registered' ||
        code == 'credential-already-in-use' ||
        code == 'phone-number-already-exists') {
      return 'Phone number is already used';
    }

    if (code == 'invalid-verification-code') {
      return 'OTP code is invalid';
    }

    if (code == 'session-expired') {
      return 'OTP session expired. Please request a new OTP';
    }

    if (code == 'too-many-requests' ||
        code == 'quota-exceeded' ||
        message.contains('blocked all requests')) {
      return 'OTP is temporarily blocked. Please try again later';
    }

    if (_isAndroidAppVerificationFailure(e)) {
      return 'Android app verification failed. Please add SHA-1 and SHA-256 to Firebase Android app settings, then download latest google-services.json.';
    }

    return e.message ?? 'Failed to verify phone number';
  }

  bool _isAndroidAppVerificationFailure(FirebaseAuthException e) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();

    return code == 'invalid-app-credential' ||
        code == 'captcha-check-failed' ||
        message.contains('missing a valid app identifier') ||
        message.contains('play integrity') ||
        message.contains('recaptcha');
  }

  Future<_PhoneVerificationState> _requestOtpVerification(
    String e164Phone,
  ) async {
    if (_lastOtpRequestedPhone == e164Phone && _lastOtpRequestedAt != null) {
      final elapsed = DateTime.now().difference(_lastOtpRequestedAt!);
      if (elapsed < _otpRequestCooldown) {
        final waitSeconds = _otpRequestCooldown.inSeconds - elapsed.inSeconds;
        throw FirebaseAuthException(
          code: 'otp-cooldown',
          message:
              'Please wait ${waitSeconds.clamp(1, _otpRequestCooldown.inSeconds)} seconds before requesting OTP again',
        );
      }
    }

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

    _lastOtpRequestedPhone = e164Phone;
    _lastOtpRequestedAt = DateTime.now();

    Future<void> startVerification({required bool forceRecaptcha}) async {
      if (forceRecaptcha) {
        await FirebaseAuth.instance.setSettings(forceRecaptchaFlow: true);
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: e164Phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) {
          completeWithState(
            _PhoneVerificationState(autoCredential: credential),
          );
        },
        verificationFailed: (exception) async {
          if (!forceRecaptcha && _isAndroidAppVerificationFailure(exception)) {
            try {
              await startVerification(forceRecaptcha: true);
              return;
            } on FirebaseAuthException catch (recaptchaError) {
              completeWithError(recaptchaError);
              return;
            }
          }

          completeWithError(exception);
        },
        codeSent: (verificationId, _) {
          _pendingOtpTargetPhone = e164Phone;
          _pendingOtpVerificationId = verificationId;
          _pendingOtpExpiresAt = DateTime.now().add(
            const Duration(minutes: 10),
          );
          completeWithState(
            _PhoneVerificationState(verificationId: verificationId),
          );
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _pendingOtpTargetPhone = e164Phone;
          _pendingOtpVerificationId = verificationId;
          _pendingOtpExpiresAt = DateTime.now().add(
            const Duration(minutes: 10),
          );
          completeWithState(
            _PhoneVerificationState(verificationId: verificationId),
          );
        },
      );
    }

    await startVerification(forceRecaptcha: false);

    return completer.future;
  }

  Future<String?> _showOtpDialog(
    String phoneNumber, {
    String? errorText,
  }) async {
    String enteredOtp = '';
    String? dialogError = errorText;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Verify New Phone Number', style: styleText()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OTP code has been sent to $phoneNumber',
                    style: styleText(),
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
                    const SizedBox(height: 4),
                    Text(
                      dialogError!,
                      style: const TextStyle(
                        color: AppTheme.fourth,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Divider(
                    height: 0,
                    color: AppTheme.secondary.withOpacity(0.12),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context, '__CHANGE_PHONE__');
                    },
                    child: Text(
                      'Change Number',
                      style: styleText().copyWith(
                        color: AppTheme.secondary.withOpacity(0.65),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.underline,
                        decorationColor: AppTheme.secondary.withOpacity(0.35),
                      ),
                    ),
                  ),
                ],
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (!RegExp(r'^\d{6}$').hasMatch(enteredOtp)) {
                      setDialogState(() {
                        dialogError = 'OTP code must be 6 digits';
                      });
                      return;
                    }

                    Navigator.pop(context, enteredOtp);
                  },
                  child: Text(
                    'Verify',
                    style: styleText().copyWith(color: AppTheme.third),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _phoneValidationDebounce?.cancel();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _schedulePhoneValidation(
    String localPhone, {
    Function(void Function())? sheetSetState,
    String? excludeUid,
  }) {
    _phoneValidationDebounce?.cancel();

    _phoneValidationDebounce = Timer(
      const Duration(milliseconds: 700),
      () async {
        final phone = localPhone.trim();

        // quick sync validation using existing validator
        final syncError = _validatePhoneNumber(
          phone,
          countryDialCode: _selectedCountry.dialCode,
        );
        if (syncError != null) {
          // clear any async error and validate form
          if (phoneError != null) {
            if (sheetSetState != null) {
              sheetSetState(() {
                phoneError = null;
              });
            } else {
              setState(() {
                phoneError = null;
              });
            }
          }
          _formKey.currentState?.validate();
          return;
        }

        final e164 = FirebaseServices.normalizePhoneToE164(
          phone,
          countryDialCode: _selectedCountry.dialCode,
        );

        if (_lastCheckedPhoneE164 == e164) return;
        _lastCheckedPhoneE164 = e164;

        try {
          final exists = await FirebaseServices.isPhoneExists(
            e164,
            excludeUid: excludeUid,
          );
          if (!mounted) return;
          if (exists) {
            if (sheetSetState != null) {
              sheetSetState(() {
                phoneError = 'Phone number is already used';
              });
            } else {
              setState(() {
                phoneError = 'Phone number is already used';
              });
            }
          } else {
            if (phoneError != null) {
              if (sheetSetState != null) {
                sheetSetState(() {
                  phoneError = null;
                });
              } else {
                setState(() {
                  phoneError = null;
                });
              }
            }
          }
          _formKey.currentState?.validate();
        } catch (_) {
          // ignore network errors for async validation; do not block user
        }
      },
    );
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
    _applyStoredPhoneToForm(user.phone);
    phoneError = null;
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
        return SafeArea(
          top: false,
          child: StatefulBuilder(
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
                                          color: AppTheme.primary,
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
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isCompact =
                                        constraints.maxWidth < 380;

                                    final countryField =
                                        DropdownButtonFormField<
                                          _CountryDialOption
                                        >(
                                          value: _selectedCountry,
                                          isExpanded: true,
                                          decoration: decorationConstant(
                                            labelText: isCompact
                                                ? null
                                                : "Phone Number",
                                            hintText: 'Country',
                                          ),
                                          items: _countryOptions.map((option) {
                                            return DropdownMenuItem<
                                              _CountryDialOption
                                            >(
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
                                            setModalState(() {
                                              _selectedCountry = value;
                                              phoneError = null;
                                              _pendingOtpTargetPhone = null;
                                              _pendingOtpVerificationId = null;
                                              _pendingOtpExpiresAt = null;
                                            });
                                            _schedulePhoneValidation(
                                              phoneController.text,
                                              sheetSetState: setModalState,
                                              excludeUid:
                                                  FirebaseServices.currentUid,
                                            );
                                          },
                                        );

                                    final phoneField = TextFormField(
                                      style: TextStyle(
                                        color: AppTheme.secondary,
                                        fontSize: 14,
                                      ),
                                      controller: phoneController,
                                      keyboardType: TextInputType.number,
                                      decoration: decorationConstant(
                                        labelText: isCompact
                                            ? "Phone Number"
                                            : null,
                                        hintText: 'Local phone number',
                                      ),
                                      validator: (value) {
                                        final phone = (value ?? '').trim();

                                        if (phone.isEmpty) {
                                          return "Phone number must be filled";
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

                                        // Validasi khusus untuk Indonesia: harus dimulai dengan 8
                                        if (_selectedCountry.dialCode ==
                                                '+62' &&
                                            !phone.startsWith('8')) {
                                          return "For Indonesia number, use local format starting with 8";
                                        }

                                        if (RegExp(
                                          r'^(\d)\1+$',
                                        ).hasMatch(phone)) {
                                          return "Phone number seems invalid (repeating digits)";
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

                                        _pendingOtpTargetPhone = null;
                                        _pendingOtpVerificationId = null;
                                        _pendingOtpExpiresAt = null;
                                        _schedulePhoneValidation(
                                          value,
                                          sheetSetState: setModalState,
                                          excludeUid:
                                              FirebaseServices.currentUid,
                                        );
                                      },
                                    );

                                    if (isCompact) {
                                      return Column(
                                        children: [
                                          countryField,
                                          const SizedBox(height: 8),
                                          phoneField,
                                        ],
                                      );
                                    }

                                    return Row(
                                      children: [
                                        Expanded(flex: 4, child: countryField),
                                        const SizedBox(width: 8),
                                        Expanded(flex: 6, child: phoneField),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Enter your local number without country code. Example: 8123456789',
                                    style: TextStyle(
                                      color: AppTheme.secondary.withOpacity(
                                        0.7,
                                      ),
                                      fontSize: 11,
                                    ),
                                  ),
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

                                    if (phoneError != null) {
                                      setModalState(() {
                                        phoneError = null;
                                      });
                                    }

                                    if (!_formKey.currentState!.validate())
                                      return;

                                    setModalState(() {
                                      isSavingProfile = true;
                                    });

                                    try {
                                      String newName = nameController.text
                                          .trim();
                                      final localPhone = phoneController.text
                                          .trim();

                                      // Validate phone number before OTP
                                      final phoneValidationError =
                                          _validatePhoneNumber(
                                            localPhone,
                                            countryDialCode:
                                                _selectedCountry.dialCode,
                                          );
                                      if (phoneValidationError != null) {
                                        setModalState(() {
                                          phoneError = phoneValidationError;
                                          isSavingProfile = false;
                                        });
                                        return;
                                      }

                                      final newPhone =
                                          FirebaseServices.normalizePhoneToE164(
                                            localPhone,
                                            countryDialCode:
                                                _selectedCountry.dialCode,
                                          );

                                      final isPhoneAlreadyRegistered =
                                          await FirebaseServices.isPhoneExists(
                                            newPhone,
                                            excludeUid:
                                                FirebaseServices.currentUid,
                                          );
                                      if (isPhoneAlreadyRegistered) {
                                        setModalState(() {
                                          phoneError =
                                              'Phone number is already used';
                                          isSavingProfile = false;
                                        });
                                        _formKey.currentState!.validate();
                                        return;
                                      }

                                      final authPhone = FirebaseAuth
                                          .instance
                                          .currentUser
                                          ?.phoneNumber;

                                      final currentPhone =
                                          (authPhone ?? '').trim().isNotEmpty
                                          ? FirebaseServices.normalizePhoneToE164(
                                              authPhone!,
                                            )
                                          : FirebaseServices.normalizePhoneToE164(
                                              user.phone,
                                              countryDialCode:
                                                  _selectedCountry.dialCode,
                                            );

                                      if (newPhone != currentPhone) {
                                        final hasReusableSession =
                                            _pendingOtpTargetPhone ==
                                                newPhone &&
                                            (_pendingOtpVerificationId ?? '')
                                                .isNotEmpty &&
                                            _pendingOtpExpiresAt != null &&
                                            DateTime.now().isBefore(
                                              _pendingOtpExpiresAt!,
                                            );

                                        if (!mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              hasReusableSession
                                                  ? 'Using previously sent OTP for $newPhone...'
                                                  : 'Sending OTP to $newPhone...',
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );

                                        final verification = hasReusableSession
                                            ? _PhoneVerificationState(
                                                verificationId:
                                                    _pendingOtpVerificationId,
                                              )
                                            : await _requestOtpVerification(
                                                newPhone,
                                              );

                                        PhoneAuthCredential? credential =
                                            verification.autoCredential;

                                        if (credential == null) {
                                          final verificationId =
                                              verification.verificationId;
                                          if (verificationId == null ||
                                              verificationId.isEmpty) {
                                            throw FirebaseAuthException(
                                              code:
                                                  'otp-missing-verification-id',
                                              message:
                                                  'Failed to get OTP verification session',
                                            );
                                          }

                                          String? otpDialogError;

                                          while (true) {
                                            final smsCode =
                                                await _showOtpDialog(
                                                  newPhone,
                                                  errorText: otpDialogError,
                                                );
                                            if (smsCode == null) {
                                              setModalState(() {
                                                isSavingProfile = false;
                                              });

                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Phone update canceled',
                                                    ),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                  ),
                                                );
                                              }
                                              return;
                                            }

                                            final attemptCredential =
                                                PhoneAuthProvider.credential(
                                                  verificationId:
                                                      verificationId,
                                                  smsCode: smsCode,
                                                );

                                            try {
                                              await FirebaseServices.updateCurrentUserPhoneWithCredential(
                                                credential: attemptCredential,
                                              );
                                              credential = attemptCredential;
                                              break;
                                            } on FirebaseAuthException catch (
                                              e
                                            ) {
                                              final code = e.code.toLowerCase();
                                              if (code ==
                                                      'invalid-verification-code' ||
                                                  code == 'session-expired') {
                                                otpDialogError =
                                                    _friendlyPhoneUpdateError(
                                                      e,
                                                    );
                                                continue;
                                              }
                                              rethrow;
                                            }
                                          }
                                        }

                                        _pendingOtpTargetPhone = null;
                                        _pendingOtpVerificationId = null;
                                        _pendingOtpExpiresAt = null;
                                      }

                                      await FirebaseServices.updateProfile(
                                        name: newName,
                                        phone: newPhone,
                                        oldPhone: currentPhone,
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
                                      });

                                      if (!mounted) return;

                                      isSheetClosed = true;
                                      Navigator.pop(context);
                                    } on FirebaseAuthException catch (e) {
                                      if (e.code == 'session-expired') {
                                        _pendingOtpTargetPhone = null;
                                        _pendingOtpVerificationId = null;
                                        _pendingOtpExpiresAt = null;
                                      }

                                      if (e.code ==
                                              'phone-already-registered' ||
                                          e.code == 'email-already-in-use' ||
                                          e.code ==
                                              'credential-already-in-use' ||
                                          e.code ==
                                              'phone-number-already-exists') {
                                        setModalState(() {
                                          phoneError =
                                              "Phone number is already used";
                                        });
                                        _formKey.currentState!.validate();
                                        return;
                                      }

                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            _friendlyPhoneUpdateError(e),
                                          ),
                                        ),
                                      );
                                    } catch (_) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
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

                                const SizedBox(height: 12),

                                /// RESET PASSWORD BUTTON
                                TombolSementara(
                                  icon: Icons.lock,
                                  height: 50,
                                  width: double.infinity,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ResetPasswordPage(),
                                      ),
                                    );
                                  },
                                  text: "Reset Password",
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
          ),
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
          backgroundColor: const Color(0xFF171A33),
          title: Text("Log Out", style: styleText()),
          content: Text("Are you sure want to log out?", style: styleText()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel", style: styleText()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                "Yes",
                style: styleText().copyWith(color: AppTheme.third),
              ),
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
      appBar: ConnextAppBar(
        variant: ConnextAppBarVariant.minimal,
        title: Text("Profile", style: styleText()),
        onLeadingPressed: () => Navigator.pop(context),
        centerTitle: true,
      ),
      body: StreamBuilder<UserModel?>(
        stream: FirebaseServices.currentUserProfileStream(),
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
                              color: AppTheme.primary,
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
                              Icon(
                                Icons.person,
                                color: const Color(0xFF73E8D7),
                              ),
                              SizedBox(width: 10),

                              Text(
                                "Name",
                                style: styleText().copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  user.nama,
                                  style: styleText(),
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),

                          Divider(height: 20),

                          /// PHONE
                          Row(
                            children: [
                              Icon(Icons.phone, color: const Color(0xFF00C2FF)),
                              SizedBox(width: 10),

                              Text(
                                "Phone Number",
                                style: styleText().copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  user.phone,
                                  style: styleText(),
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),

                          Divider(height: 20),

                          /// ROLE
                          Row(
                            children: [
                              Icon(Icons.badge, color: const Color(0xFF73E8D7)),
                              const SizedBox(width: 10),

                              Text(
                                "Role",
                                style: styleText().copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Wrap(
                                  alignment: WrapAlignment.end,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 10,
                                  runSpacing: 8,
                                  children: [
                                    Text(
                                      role ?? "Unknown",
                                      style: styleText().copyWith(
                                        color: AppTheme.third,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: isChangingRole ? null : changeRole,
                                      borderRadius: BorderRadius.circular(999),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF2AE6B7),
                                              Color(0xFF00C2FF),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.third.withOpacity(
                                                0.35,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: isChangingRole
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(AppTheme.primary),
                                                ),
                                              )
                                            : Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.swap_horiz_rounded,
                                                    size: 18,
                                                    color: AppTheme.primary,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  ConstrainedBox(
                                                    constraints:
                                                        const BoxConstraints(
                                                          maxWidth: 130,
                                                        ),
                                                    child: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Text(
                                                        role == 'Committee'
                                                            ? 'Switch to Attendee'
                                                            : 'Apply for Committee',
                                                        maxLines: 1,
                                                        softWrap: false,
                                                        style: styleText()
                                                            .copyWith(
                                                              color: AppTheme
                                                                  .primary,
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Committee access can be requested from this profile menu.',
                            style: styleText().copyWith(
                              fontSize: 11,
                              color: AppTheme.secondary.withOpacity(0.7),
                            ),
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
