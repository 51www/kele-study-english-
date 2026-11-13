import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import 'path_model.dart';
import 'path_plan.dart';
import 'path_providers.dart';

/// 首页「下一步」卡：一句动作 + 一句可核对的理由 + 一键开始 + 退出选项。
/// compact 版用于复盘末尾，不新增主色实心按钮（复盘底部已有主按钮）。
class NextStepCard extends ConsumerWidget {
  const NextStepCard({super.key, required this.plan, this.compact = false});

  final PathPlan plan;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = plan.next;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.today_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(compact ? '下一次练这个' : '下一步', style: AppText.cardTitle),
              const Spacer(),
              AppTag(
                label: '第 ${plan.stage.index} 阶段 · ${plan.stage.name}',
                color: AppColors.primaryDeep,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(plan.nextTitle, style: AppText.section),
          const SizedBox(height: 6),
          Text(plan.nextReason, style: AppText.bodySecondary),
          const SizedBox(height: 14),
          if (compact)
            SecondaryButton(
              label: '开始下一步',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => context.push(plan.nextRoute),
            )
          else ...[
            PrimaryButton(
              label: '开始',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => context.push(plan.nextRoute),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _action(
                  '换一个',
                  () => updatePath(ref, nextPathAlternative),
                ),
                _action(
                  '今天先跳过',
                  next == null
                      ? null
                      : () => updatePath(
                            ref,
                            (state) => skipPathItem(state, next, DateTime.now()),
                          ),
                ),
                _action('查看学习路径', () => context.push('/path')),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _action(String label, VoidCallback? onPressed) => Expanded(
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryDeep,
            textStyle: AppText.caption.copyWith(fontSize: 11),
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(label),
        ),
      );
}

/// 复盘末尾的「下一次」入口。未配置路径时也不空白，给一个设定入口。
class ReviewNextStepCard extends ConsumerWidget {
  const ReviewNextStepCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pathPlanProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (plan) => plan.configured
          ? NextStepCard(plan: plan, compact: true)
          : AppCard(
              child: Row(
                children: [
                  const Icon(Icons.map_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text('还没设定学习路径，下次练什么由你定。', style: AppText.bodySecondary),
                  ),
                  TextButton(
                    onPressed: () => context.push('/path/setup'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryDeep,
                      textStyle: AppText.caption.copyWith(fontSize: 11),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('去设定'),
                  ),
                ],
              ),
            ),
    );
  }
}
