import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'theme/app_colors.dart';
import 'widgets/common.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _paths = ['/home', '/history', '/phrasebook', '/me'];

  int get _index {
    final i = _paths.indexWhere((p) => location == p || location.startsWith('$p/'));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: SafeArea(bottom: false, child: child),
        bottomNavigationBar: FloatingNav(
          currentIndex: _index,
          onSelect: (i) {
            if (i == _index) return;
            context.go(_paths[i]);
          },
        ),
      ),
    );
  }
}

/// 给各 Tab 页面复用的页面内边距。
EdgeInsets get shellPagePadding =>
    const EdgeInsets.fromLTRB(24, 8, 24, 120);

const shellBottomPadding = 120.0;

/// 无滚动内容时的占位背景色（与 AppShell 渐变衔接）。
const shellSurface = AppColors.surface;
