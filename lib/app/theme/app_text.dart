import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 对应《UI 设计规范》§3.2 字号 Token。
class AppText {
  AppText._();

  static const display = TextStyle(
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    color: AppColors.ink,
  );
  static const h1 = TextStyle(
    fontSize: 24,
    height: 30 / 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: AppColors.ink,
  );
  static const h2 = TextStyle(
    fontSize: 20,
    height: 26 / 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.ink,
  );
  static const section = TextStyle(
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    color: AppColors.ink,
  );
  static const cardTitle = TextStyle(
    fontSize: 15,
    height: 21 / 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    color: AppColors.ink,
  );
  static const body = TextStyle(
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
  );
  static const bodySecondary = TextStyle(
    fontSize: 13,
    height: 20 / 13,
    fontWeight: FontWeight.w400,
    color: AppColors.inkSecondary,
  );
  static const caption = TextStyle(
    fontSize: 11,
    height: 16 / 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.inkMuted,
  );
  static const tag = TextStyle(
    fontSize: 10,
    height: 14 / 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
  static const button = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );
}
