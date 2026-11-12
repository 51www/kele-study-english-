import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';

/// 首页「今天练这个」：纯规则生成，一键直达，打开 App 不用做选择。
class TodayPracticeCard extends ConsumerWidget {
  const TodayPracticeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(todayPlanProvider);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.today_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('今天练这个', style: AppText.cardTitle),
            ],
          ),
          const SizedBox(height: 12),
          plan.when(
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
        ],
      ),
    );
  }
}
