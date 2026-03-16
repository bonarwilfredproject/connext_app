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
    suffixIcon: suffixIcon,
    errorMaxLines: 3,
    contentPadding: EdgeInsets.symmetric(horizontal: 8),
    hint: Text(
      hintText,
      style: TextStyle(color: AppTheme.secondary, fontSize: 12),
    ),
    fillColor: AppTheme.fourth,
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );
}
