import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// 场景分类 → 图标 / 浅底 / 强调色映射，只使用既有颜色 Token。
///
/// 用于首页、场景库、场景详情与记录页，替代按 `id.contains('cafe')` 硬编码图标。
class ScenarioVisual {
  const ScenarioVisual({
    required this.icon,
    required this.tint,
    required this.accent,
  });

  final IconData icon;
  final Color tint;
  final Color accent;
}

/// 分类 Chip 的固定顺序；「全部」永远在首位，数据里出现的未知分类补在末尾。
const scenarioCategoryOrder = <String>[
  '全部',
  '日常',
  '工作',
  '旅行',
  '社交',
  '健康',
  '观点',
  '居住家政',
  '政务金融',
  '校园学习',
  '数码线上',
  '关系情绪',
  '消费服务',
];

/// 按固定顺序取实际存在的分类，未知分类补在末尾，避免出现空 Chip。
List<String> scenarioCategoriesOf(Iterable<String> raw) {
  final present = raw.toSet();
  return <String>[
    '全部',
    for (final category in scenarioCategoryOrder.skip(1))
      if (present.contains(category)) category,
    for (final category in present)
      if (!scenarioCategoryOrder.contains(category)) category,
  ];
}

ScenarioVisual scenarioVisual(String? category) {
  switch (category) {
    case '日常':
      return const ScenarioVisual(
        icon: Icons.local_cafe_rounded,
        tint: AppColors.primaryWash,
        accent: AppColors.orange,
      );
    case '工作':
      return const ScenarioVisual(
        icon: Icons.work_outline_rounded,
        tint: AppColors.primaryTint,
        accent: AppColors.primaryDeep,
      );
    case '旅行':
      return ScenarioVisual(
        icon: Icons.flight_takeoff_rounded,
        tint: AppColors.mint.withValues(alpha: 0.28),
        accent: AppColors.success,
      );
    case '社交':
      return ScenarioVisual(
        icon: Icons.forum_outlined,
        tint: AppColors.pink.withValues(alpha: 0.10),
        accent: AppColors.primaryDeep,
      );
    case '健康':
      return ScenarioVisual(
        icon: Icons.local_hospital_outlined,
        tint: AppColors.warning.withValues(alpha: 0.10),
        accent: AppColors.warning,
      );
    case '观点':
      return ScenarioVisual(
        icon: Icons.lightbulb_outline_rounded,
        tint: AppColors.yellow.withValues(alpha: 0.20),
        accent: AppColors.primaryDeep,
      );
    case '居住家政':
      return ScenarioVisual(
        icon: Icons.home_outlined,
        tint: AppColors.pink.withValues(alpha: 0.10),
        accent: AppColors.orange,
      );
    case '政务金融':
      return ScenarioVisual(
        icon: Icons.account_balance_outlined,
        tint: AppColors.mint.withValues(alpha: 0.28),
        accent: AppColors.success,
      );
    case '校园学习':
      return ScenarioVisual(
        icon: Icons.school_outlined,
        tint: AppColors.yellow.withValues(alpha: 0.20),
        accent: AppColors.warning,
      );
    case '数码线上':
      return const ScenarioVisual(
        icon: Icons.wifi_rounded,
        tint: AppColors.primaryTint,
        accent: AppColors.primaryDeep,
      );
    case '关系情绪':
      return ScenarioVisual(
        icon: Icons.favorite_border_rounded,
        tint: AppColors.pink.withValues(alpha: 0.10),
        accent: AppColors.primaryDeep,
      );
    case '消费服务':
      return const ScenarioVisual(
        icon: Icons.shopping_bag_outlined,
        tint: AppColors.primaryWash,
        accent: AppColors.orange,
      );
    default:
      return const ScenarioVisual(
        icon: Icons.chat_bubble_outline_rounded,
        tint: AppColors.primaryWash,
        accent: AppColors.primaryDeep,
      );
  }
}
