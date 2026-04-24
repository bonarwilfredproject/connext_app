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

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  TextEditingController currentPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  bool isLoadingReset = false;
  bool showCurrentPassword = false;
  bool showNewPassword = false;
  bool showConfirmPassword = false;

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (isLoadingReset) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoadingReset = true;
    });

    try {
      await FirebaseServices.resetPasswordForCurrentUser(
        currentPassword: currentPasswordController.text,
        newPassword: newPasswordController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );

      // Clear fields
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      // Back to previous screen
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to reset password';
      final code = e.code.toLowerCase();
      final message = (e.message ?? '').toLowerCase();

      if (code == 'wrong-password' ||
          code == 'invalid-credential' ||
          message.contains('wrong password') ||
          message.contains('incorrect password') ||
          message.contains('invalid credential')) {
        errorMessage = 'Current password is incorrect';
      } else if (code == 'user-not-found') {
        errorMessage = 'User not found';
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.fourth,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.fourth,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoadingReset = false;
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
                        const SizedBox(height: 24),
                        Text(
                          'Change Password',
                          style: styleText().copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your current password and new password',
                          style: styleText().copyWith(
                            fontSize: 12,
                            color: AppTheme.secondary.withAlpha(200),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Icon(
                              Icons.password,
                              color: AppTheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Text("Current Password", style: styleText()),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: currentPasswordController,
                          obscureText: !showCurrentPassword,
                          obscuringCharacter: "*",
                          style: TextStyle(
                            color: AppTheme.secondary,
                            fontSize: 12,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Current password is required';
                            }
                            return null;
                          },
                          decoration: decorationConstant(
                            hintText: 'Please input your password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                showCurrentPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: AppTheme.secondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  showCurrentPassword = !showCurrentPassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.third.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.third, width: 1),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppTheme.third,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Password must have at least 8 characters, an uppercase, a lowercase, a number, and a special character',
                                  style: styleText().copyWith(
                                    fontSize: 12,
                                    color: AppTheme.third,
                                  ),
                                ),
                              ),
                            ],
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
                            final error = validateStrongPassword(value);
                            if (error != null) return error;
                            if (value == currentPasswordController.text) {
                              return 'New password must be different from current password';
                            }
                            return null;
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
                            Text("Confirm New Password", style: styleText()),
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
                          text: isLoadingReset
                              ? 'Updating...'
                              : 'Update Password',
                          width: double.infinity,
                          height: 54,
                          onPressed: isLoadingReset ? null : _resetPassword,
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
    );
  }
}
