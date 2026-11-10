import 'package:flutter/material.dart';

/// 对应《UI 设计规范》§3.1 颜色 Token。
class AppColors {
  AppColors._();

  static const primary = Color(0xFF6E8BFF);
  static const primaryDeep = Color(0xFF5A74F0);
  static const primaryLight = Color(0xFFAFC0FF);
  static const primaryTint = Color(0xFFDFE5FF);
  static const primaryWash = Color(0xFFEEF3FF);

  static const ink = Color(0xFF1D2340);
  static const inkSecondary = Color(0xFF7F88A4);
  static const inkMuted = Color(0xFFA0A8C0);
  static const line = Color(0xFFDCE5FB);
  static const divider = Color(0xFFE8EEFB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceTint = Color(0xFFF7F9FF);

  static const pink = Color(0xFFF27CC5);
  static const yellow = Color(0xFFFFD35C);
  static const mint = Color(0xFF9FE3C5);
  static const orange = Color(0xFFFFB07A);
  static const success = Color(0xFF3CCB9A);
  static const warning = Color(0xFFFFB45C);
  static const error = Color(0xFFFF6B7A);

  static const bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFD5DDFB), Color(0xFFB9C6F4)],
  );
}
