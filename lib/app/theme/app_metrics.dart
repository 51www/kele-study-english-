import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppSpacing {
  AppSpacing._();

  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const page = 24.0;
  static const section = 28.0;
  static const scrollBottom = 112.0;
}

class AppRadius {
  AppRadius._();

  static const xl = 32.0;
  static const lg = 24.0;
  static const md = 18.0;
  static const sm = 12.0;
  static const xs = 8.0;
  static const pill = 999.0;
}

class AppShadows {
  AppShadows._();

  static const card = [
    BoxShadow(color: Color(0x1A4E66BE), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const floating = [
    BoxShadow(color: Color(0x2E465CB4), blurRadius: 40, offset: Offset(0, 16)),
  ];
  static const primary = [
    BoxShadow(color: Color(0x476E8BFF), blurRadius: 24, offset: Offset(0, 10)),
  ];
  static const sheet = [
    BoxShadow(color: Color(0x24465AA5), blurRadius: 40, offset: Offset(0, -16)),
  ];
  static const soft = [
    BoxShadow(color: Color(0x0F4E66BE), blurRadius: 16, offset: Offset(0, 6)),
  ];
}

class AppLayout {
  AppLayout._();

  static const designWidth = 393.0;
  static const pagePadding = 24.0;
  static const contentWidth = designWidth - pagePadding * 2;
  static const headerHeight = 56.0;
  static const navHeight = 58.0;
  static const buttonHeight = 50.0;
  static const inputHeight = 48.0;
  static const listItemHeight = 60.0;
  static const cardGap = 12.0;
  static const sectionGap = 28.0;
}

/// 全局圆角装饰，便于页面复用。
BoxDecoration cardDecoration({
  Color color = AppColors.surface,
  double radius = AppRadius.lg,
  bool shadow = true,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: shadow ? AppShadows.card : null,
  );
}
