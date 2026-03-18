import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/constants/style_text.dart';
import 'package:flutter/material.dart';

InputDecoration decorationConstant({
  required String hintText,
  Widget? suffixIcon,
  String? labelText,
}) {
  return InputDecoration(
    labelText: labelText,
    labelStyle: styleText(),

    hintText: hintText,
    hintStyle: TextStyle(color: AppTheme.secondary, fontSize: 12),

    suffixIcon: suffixIcon,
    errorMaxLines: 3,

    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),

    /// 🔥 BACKGROUND NORMAL
    filled: true,
    fillColor: AppTheme.primary,

    /// 🔥 DEFAULT (TIDAK ADA BORDER)
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),

    /// 🔥 SAAT TIDAK FOCUS
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),

    /// 🔥 SAAT DIKLIK / FOCUS
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppTheme.fourth, width: 1.5),
    ),

    /// 🔥 ERROR
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 1.2),
    ),

    /// 🔥 FOCUS + ERROR
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    ),
  );
}
