import 'dart:async';

import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:connext_app/pages/home_page/home_page.dart';
import 'package:connext_app/pages/attendee_event_page/attendee_event_page.dart';
import 'package:connext_app/pages/event_invite_page.dart';
import 'package:connext_app/services/firebase_services.dart';
import 'package:connext_app/models/user_model.dart';
import 'package:connext_app/constants/decoration_constant.dart';
import 'package:connext_app/services/pending_join_route_service.dart';
import 'package:connext_app/services/preferences_services.dart';
import 'package:connext_app/widgets/app_section_card.dart';
import 'package:connext_app/widgets/custom_appbar.dart';
import 'package:connext_app/widgets/ellipse_background.dart';
import 'package:connext_app/widgets/role_selector.dart';
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

class DaftarPage extends StatefulWidget {
  const DaftarPage({super.key});

  @override
  State<DaftarPage> createState() => _DaftarPageState();
}

class _DaftarPageState extends State<DaftarPage> {
  static const int _maxOtpResendAttempts = 2;
  static const Duration _otpResendCooldown = Duration(seconds: 60);

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

  String role = "Committee";
  bool isVisible = true;
  bool isLoadingSignUp = false;
  String? _pendingOtpTargetPhone;
  String? _pendingOtpVerificationId;
  DateTime? _pendingOtpExpiresAt;
  String? _lastOtpAttemptPhone;
  bool _mustChangePhoneBeforeRetry = false;
  DateTime? _otpServerBlockedUntil;
  late _CountryDialOption _selectedCountry;
  final GlobalKey<FormState> _formKey = GlobalKey();
  TextEditingController namaController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  bool get _isRegistrationLocked =>
      isLoadingSignUp ||
      ((_pendingOtpVerificationId ?? '').isNotEmpty &&
          _pendingOtpExpiresAt != null &&
          DateTime.now().isBefore(_pendingOtpExpiresAt!));

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
      return 'OTP request timed out. Please check your internet connection and tap Sign Up again. If it persists, try switching to a different network (WiFi/Mobile data).';
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

    if (code == 'invalid-phone-number' ||
        message.contains('invalid phone') ||
        message.contains('missing or invalid') ||
        message.contains('phone number format')) {
      return 'Phone number format is invalid. Please use an active real number with the correct country code.';
    }

    if (code == 'email-already-registered' ||
        code == 'credential-already-in-use' ||
        code == 'email-already-in-use') {
      return 'This email (from phone number) is already registered. Please login with your existing account or use a different phone number.';
    }

    if (code == 'email-linking-failed') {
      return 'Failed to complete email registration. Please try again or contact support.';
    }

    if (code == 'email-recovery-failed') {
      return 'Failed to recover previous account mapping for this number. Please try again later.';
    }

    if (code == 'firestore-write-failed') {
      return 'Failed to save your profile. Please check your internet connection and try again.';
    }

    if (code == 'phone-already-registered') {
      return 'This phone number is already registered. Please login with your existing account.';
    }

    if (code == 'registration-error') {
      return 'An error occurred during registration. Please try again.';
    }

    if (code == 'otp-missing-verification-id') {
      return 'OTP session was lost. Please try Sign Up again.';
    }

    if (code == 'internal-error' || message.contains('internal error')) {
      return 'OTP provider is currently throttling this device/session. Please stop retrying for a while, switch network, or use another phone number.';
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

    // Fail fast to avoid long loading spinner when provider doesn't respond.
    failSafeTimer = Timer(const Duration(seconds: 45), () {
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
        timeout: const Duration(seconds: 30),
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
      if (completer.isCompleted) return completer.future;
      if (e is FirebaseAuthException) {
        completeWithError(e);
        return completer.future;
      }

      completeWithError(
        FirebaseAuthException(
          code: 'otp-request-failed',
          message: 'Failed to request OTP. Please try again.',
        ),
      );
    }

    return completer.future;
  }

  Future<String?> _showOtpDialog(
    String phoneNumber, {
    String? errorText,
    required DateTime resendAvailableAt,
    required int resendAttempts,
    required int maxResendAttempts,
  }) async {
    String enteredOtp = '';
    String? dialogError = errorText;
    var resendCountdown = 0;
    var timerInitialized = false;
    Timer? resendTimer;

    void startResendTimer(void Function(void Function()) setDialogState) {
      resendTimer?.cancel();
      final secondsLeft = resendAvailableAt
          .difference(DateTime.now())
          .inSeconds;
      resendCountdown = secondsLeft > 0 ? secondsLeft : 0;
      resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (resendCountdown <= 0) {
          timer.cancel();
          return;
        }

        setDialogState(() {
          resendCountdown--;
        });
      });
    }

    final smsCode = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: true,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              if (!timerInitialized) {
                timerInitialized = true;
                startResendTimer(setDialogState);
              }

              final mediaQuery = MediaQuery.of(context);
              final keyboardInset = mediaQuery.viewInsets.bottom;
              final maxDialogContentHeight =
                  mediaQuery.size.height - keyboardInset - 220;

              return AlertDialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                title: Text('Verify Phone Number', style: styleText()),
                content: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: maxDialogContentHeight > 220
                        ? maxDialogContentHeight
                        : 220,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OTP code has been sent to $phoneNumber',
                          style: styleText().copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Complete verification or change number. Resend is rate-limited to prevent OTP spam.',
                          style: styleText().copyWith(
                            fontSize: 11,
                            color: AppTheme.secondary.withOpacity(0.8),
                          ),
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
                        const SizedBox(height: 8),
                        Text(
                          'Resend attempts: $resendAttempts/$maxResendAttempts',
                          style: styleText().copyWith(
                            fontSize: 11,
                            color: AppTheme.secondary.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, '__CHANGE_PHONE__');
                    },
                    child: Text(
                      'Change Number',
                      style: styleText().copyWith(color: AppTheme.secondary),
                    ),
                  ),
                  TextButton(
                    onPressed:
                        (resendCountdown == 0 &&
                            resendAttempts < maxResendAttempts)
                        ? () {
                            Navigator.pop(context, '__RESEND__');
                          }
                        : null,
                    child: Text(
                      resendAttempts >= maxResendAttempts
                          ? 'Resend limit reached'
                          : (resendCountdown == 0
                                ? 'Resend OTP'
                                : 'Resend in ${resendCountdown}s'),
                      style: styleText().copyWith(
                        color:
                            (resendCountdown == 0 &&
                                resendAttempts < maxResendAttempts)
                            ? AppTheme.third
                            : AppTheme.secondary.withOpacity(0.6),
                      ),
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
          ),
        );
      },
    );

    resendTimer?.cancel();

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

      final now = DateTime.now();
      if (_otpServerBlockedUntil != null &&
          now.isBefore(_otpServerBlockedUntil!)) {
        final wait = _otpServerBlockedUntil!.difference(now).inMinutes + 1;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'OTP provider is temporarily throttling this device. Try again in about $wait minutes, switch network, or use another number.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (_mustChangePhoneBeforeRetry && _lastOtpAttemptPhone == e164Phone) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please use a different phone number first before requesting OTP again.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      _mustChangePhoneBeforeRetry = false;
      _lastOtpAttemptPhone = e164Phone;

      final hasReusableSession =
          _pendingOtpTargetPhone == e164Phone &&
          (_pendingOtpVerificationId ?? '').isNotEmpty &&
          _pendingOtpExpiresAt != null &&
          DateTime.now().isBefore(_pendingOtpExpiresAt!);

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
          : await _requestOtpVerification(e164Phone).timeout(
              const Duration(seconds: 50),
              onTimeout: () {
                throw FirebaseAuthException(
                  code: 'otp-timeout',
                  message:
                      'OTP request timed out. Please check your connection and try again.',
                );
              },
            );

      if (verification.verificationId != null &&
          verification.verificationId!.isNotEmpty) {
        _pendingOtpTargetPhone = e164Phone;
        _pendingOtpVerificationId = verification.verificationId;
        _pendingOtpExpiresAt = DateTime.now().add(const Duration(minutes: 5));
      }

      PhoneAuthCredential? credential = verification.autoCredential;

      if (credential == null) {
        var verificationId = verification.verificationId;
        var resendAttempts = 0;
        var resendAvailableAt = DateTime.now().add(_otpResendCooldown);

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
            resendAvailableAt: resendAvailableAt,
            resendAttempts: resendAttempts,
            maxResendAttempts: _maxOtpResendAttempts,
          );

          if (smsCode == '__CHANGE_PHONE__') {
            _pendingOtpTargetPhone = null;
            _pendingOtpVerificationId = null;
            _pendingOtpExpiresAt = null;
            _mustChangePhoneBeforeRetry = true;
            _lastOtpAttemptPhone = e164Phone;

            setState(() {
              phoneController.clear();
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'OTP flow stopped. Please update your number and try again.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }

          if (smsCode == '__RESEND__') {
            if (resendAttempts >= _maxOtpResendAttempts) {
              otpDialogError =
                  'Resend limit reached. Please change number or try again later.';
              continue;
            }

            final waitSeconds = resendAvailableAt
                .difference(DateTime.now())
                .inSeconds;
            if (waitSeconds > 0) {
              otpDialogError =
                  'Please wait ${waitSeconds + 1}s before requesting OTP again.';
              continue;
            }

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Resending OTP to $e164Phone...'),
                behavior: SnackBarBehavior.floating,
              ),
            );

            resendAttempts++;
            resendAvailableAt = DateTime.now().add(_otpResendCooldown);

            _PhoneVerificationState resendVerification;
            try {
              resendVerification = await _requestOtpVerification(e164Phone).timeout(
                const Duration(seconds: 50),
                onTimeout: () {
                  throw FirebaseAuthException(
                    code: 'otp-timeout',
                    message:
                        'OTP resend timed out. Please check your connection and try again.',
                  );
                },
              );
            } on FirebaseAuthException catch (e) {
              final code = e.code.toLowerCase();
              final message = (e.message ?? '').toLowerCase();
              if (code == 'too-many-requests' ||
                  code == 'internal-error' ||
                  message.contains('unusual activity') ||
                  message.contains('blocked all requests') ||
                  message.contains('internal error')) {
                _pendingOtpTargetPhone = null;
                _pendingOtpVerificationId = null;
                _pendingOtpExpiresAt = null;
                _mustChangePhoneBeforeRetry = true;
                _lastOtpAttemptPhone = e164Phone;
                _otpServerBlockedUntil = DateTime.now().add(
                  const Duration(minutes: 10),
                );

                if (mounted) {
                  setState(() {
                    phoneController.clear();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'OTP temporarily blocked by Firebase. Please use a different number/network and try again later.',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                return;
              }
              otpDialogError = _friendlyAuthError(e);
              continue;
            }

            if (resendVerification.verificationId != null &&
                resendVerification.verificationId!.isNotEmpty) {
              verificationId = resendVerification.verificationId;
              _pendingOtpTargetPhone = e164Phone;
              _pendingOtpVerificationId = verificationId;
              _pendingOtpExpiresAt = DateTime.now().add(
                const Duration(minutes: 5),
              );
            }

            if (resendVerification.autoCredential != null) {
              credential = resendVerification.autoCredential;
              break;
            }

            otpDialogError = null;
            continue;
          }

          if (smsCode == null) {
            _pendingOtpTargetPhone = null;
            _pendingOtpVerificationId = null;
            _pendingOtpExpiresAt = null;

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'OTP verification closed. You can edit your number and try again.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }

          if (verificationId == null || verificationId.isEmpty) {
            otpDialogError = 'OTP session expired. Please resend OTP.';
            continue;
          }

          final attemptCredential = PhoneAuthProvider.credential(
            verificationId: verificationId,
            smsCode: smsCode,
          );

          try {
            await FirebaseServices.registerUserWithPhoneCredential(
              user: UserModel(
                nama: namaController.text.trim(),
                phone: e164Phone,
                password: passwordController.text,
                role: role,
              ),
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
        await FirebaseServices.registerUserWithPhoneCredential(
          user: UserModel(
            nama: namaController.text.trim(),
            phone: e164Phone,
            password: passwordController.text,
            role: role,
          ),
          credential: credential,
        );
      }

      _pendingOtpTargetPhone = null;
      _pendingOtpVerificationId = null;
      _pendingOtpExpiresAt = null;

      if (!mounted) return;

      final pref = PreferenceHandler();
      await pref.init();

      final normalizedPhone = FirebaseServices.normalizePhoneToE164(
        phoneController.text.trim(),
        countryDialCode: _selectedCountry.dialCode,
      );

      final loggedInUser = await FirebaseServices.loginUser(
        phone: normalizedPhone,
        password: passwordController.text,
      );

      if (loggedInUser == null) {
        throw FirebaseAuthException(
          code: 'registration-error',
          message: 'Registration succeeded but automatic login failed.',
        );
      }

      int? resolvedUserId = loggedInUser.id;
      if (resolvedUserId == null || resolvedUserId <= 0) {
        final profile = await FirebaseServices.getCurrentUserProfile();
        final profileId = profile?.id;
        if (profileId != null && profileId > 0) {
          resolvedUserId = profileId;
        }
      }

      if (resolvedUserId == null || resolvedUserId <= 0) {
        throw FirebaseAuthException(
          code: 'registration-error',
          message: 'Registration succeeded but could not resolve user ID.',
        );
      }

      await pref.saveUser(resolvedUserId, loggedInUser.nama, loggedInUser.role);

      final pendingJoinEventId = pref.getPendingJoinEventId();
      if (!mounted) return;

      if (pendingJoinEventId > 0) {
        final routeDecision = await PendingJoinRouteService.resolve(
          userId: resolvedUserId,
          userRole: loggedInUser.role,
          eventId: pendingJoinEventId,
        );

        await pref.clearPendingJoinEventId();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => routeDecision.openAttendee
                ? AttendeeEventPage(
                    userId: resolvedUserId!,
                    eventId: pendingJoinEventId,
                  )
                : EventInvitePage(eventId: pendingJoinEventId),
          ),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      final friendlyMessage = _friendlyAuthError(e);
      final errorCode = e.code.toLowerCase();
      final errorMessage = (e.message ?? '').toLowerCase();

      // Auto-clear pending OTP state on timeout to allow fresh retry
      if (errorCode == 'otp-timeout' ||
          errorMessage.contains('timed out') ||
          errorMessage.contains('timeout')) {
        _pendingOtpTargetPhone = null;
        _pendingOtpVerificationId = null;
        _pendingOtpExpiresAt = null;
      }

      if (errorCode == 'session-expired') {
        _pendingOtpTargetPhone = null;
        _pendingOtpVerificationId = null;
        _pendingOtpExpiresAt = null;
      }

      if (errorCode == 'too-many-requests' ||
          errorCode == 'internal-error' ||
          errorMessage.contains('unusual activity') ||
          errorMessage.contains('blocked all requests') ||
          errorMessage.contains('internal error')) {
        final blockedPhone = _pendingOtpTargetPhone;
        // Clear pending OTP state when Firebase rate-limit happens.
        _pendingOtpTargetPhone = null;
        _pendingOtpVerificationId = null;
        _pendingOtpExpiresAt = null;
        _mustChangePhoneBeforeRetry = true;
        _lastOtpAttemptPhone = blockedPhone ?? _lastOtpAttemptPhone;
        _otpServerBlockedUntil = DateTime.now().add(
          const Duration(minutes: 10),
        );
      }

      if (errorCode == 'email-already-registered' ||
          errorCode == 'email-linking-failed' ||
          errorCode == 'email-recovery-failed') {
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
    } catch (error) {
      if (!mounted) return;

      String errorMessage = 'Failed to register user';
      if (error is Exception) {
        errorMessage = error.toString();
        if (errorMessage.contains('SocketException') ||
            errorMessage.contains('ConnectionException')) {
          errorMessage =
              'Network connection failed. Please check your internet and try again.';
        } else if (errorMessage.contains('TimeoutException')) {
          errorMessage =
              'Request timed out. Please check your connection and try again.';
        } else if (errorMessage.contains('Exception:')) {
          errorMessage =
              'An error occurred: ${error.toString().replaceFirst('Exception: ', '')}';
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
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
    return PopScope(
      canPop: !_isRegistrationLocked,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isRegistrationLocked && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Registration is in progress. Please complete OTP verification first.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          onPressed: () {
            if (_isRegistrationLocked) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Registration is in progress. Please complete OTP verification first.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
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
                    child: IgnorePointer(
                      ignoring: isLoadingSignUp,
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
                                    color: AppTheme.secondary,
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
                                    color: AppTheme.secondary,
                                  ),
                                ),

                                Expanded(
                                  flex: 8,
                                  child: Text(
                                    "Phone Number",
                                    style: styleText(),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child:
                                      DropdownButtonFormField<
                                        _CountryDialOption
                                      >(
                                        value: _selectedCountry,
                                        isExpanded: true,
                                        decoration: decorationConstant(
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
                                      if (RegExp(
                                        r'^(\d)\1+$',
                                      ).hasMatch(phone)) {
                                        return "Phone number seems invalid";
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
                                    color: AppTheme.secondary,
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
                                final hasNumber = RegExp(
                                  r'\d',
                                ).hasMatch(password);
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
                                    color: AppTheme.secondary,
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
                            TombolSementara(
                              icon: Icons.app_registration,
                              width: double.infinity,
                              height: 54,
                              isLoading: isLoadingSignUp,
                              text: "Sign Up",
                              onPressed: _registerWithOtp,
                            ),
                            if (isLoadingSignUp) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Please wait, registration is being processed...',
                                style: TextStyle(
                                  color: AppTheme.secondary.withOpacity(0.8),
                                  fontSize: 11,
                                ),
                              ),
                            ],
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
        backgroundColor: AppTheme.primary,
      ),
    );
  }
}
