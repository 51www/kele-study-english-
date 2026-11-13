import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import '../path/next_step_card.dart';
import '../path/path_providers.dart';

/// 首页「今天练这个」→ M14 升级为「下一步」：
/// 已配置路径时读路径计划；未配置或计划出错时回落到原有纯规则，升级用户不空白。
class TodayPracticeCard extends ConsumerWidget {
  const TodayPracticeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref.watch(pathPlanProvider);
    return path.when(
      loading: () => const _CardShell(
        child: SizedBox(
          height: 20,
          child: LinearProgressIndicator(minHeight: 3),
        ),
      ),
      error: (_, _) => const _LegacyTodayCard(),
      data: (plan) =>
          plan.configured ? NextStepCard(plan: plan) : const _LegacyTodayCard(),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.today_rounded, size: 18, color: AppColors.primary),
                SizedBox(width: 8),
                Text('今天练这个', style: AppText.cardTitle),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}

/// 未配置学习路径时沿用三期 M9 的规则卡，口径与文案保持不变。
class _LegacyTodayCard extends ConsumerWidget {
  const _LegacyTodayCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(todayPlanProvider);
    return _CardShell(
      child: plan.when(
        loading: () => const SizedBox(
          height: 20,
          child: LinearProgressIndicator(minHeight: 3),
        ),
        error: (_, _) => const Text(
          '暂时没算出今天的练习，去场景库挑一个吧。',
          style: AppText.bodySecondary,
        ),
        data: (value) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value.title, style: AppText.section),
            const SizedBox(height: 6),
            Text(value.reason, style: AppText.bodySecondary),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: '开始',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => context.push(value.route),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
