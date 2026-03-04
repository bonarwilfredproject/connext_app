import 'package:flutter/material.dart';

InputDecoration decorationConstant({required String hintText}) {
  return InputDecoration(
    errorMaxLines: 2,
    contentPadding: EdgeInsets.symmetric(horizontal: 8),
    hint: Text(
      hintText,
      style: TextStyle(color: Color(0xFFF4EEFF), fontSize: 12),
    ),
    fillColor: Color(0xFFA6B1E1),
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );
}
