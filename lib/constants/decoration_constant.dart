import 'package:connext_app/constants/app_theme.dart';
import 'package:flutter/material.dart';

InputDecoration decorationConstant({required String hintText}) {
  return InputDecoration(
    errorMaxLines: 2,
    contentPadding: EdgeInsets.symmetric(horizontal: 8),
    hint: Text(
      hintText,
      style: TextStyle(color: AppTheme.primary, fontSize: 12),
    ),
    fillColor: AppTheme.fourth,
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );
}
