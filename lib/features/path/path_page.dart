import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import 'next_step_card.dart';
import 'path_model.dart';
import 'path_plan.dart';
import 'path_providers.dart';

/// 学习路径页：回答「我在哪 / 走到哪了 / 接下来做什么」。
/// 阶段不是关卡：4 段都可点、可跳、可退；完成标准只是「建议往前走」。
class PathPage extends ConsumerWidget {
  const PathPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pathPlanProvider);
    return PageScaffold(
      title: '学习路径',
      actions: [
        IconButton(
          onPressed: () => context.push('/path/setup'),
          icon: const Icon(Icons.tune_rounded, size: 22),
          color: AppColors.primaryDeep,
          tooltip: '改目标 / 改起点',
        ),
      ],
      child: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: ErrorBanner(
            message: '路径加载失败：$error',
            onRetry: () => ref.invalidate(pathPlanProvider),
          ),
        ),
        data: (plan) =>
            plan.configured ? _PathBody(plan: plan) : const _EmptyPath(),
      ),
    );
  }
}

class _EmptyPath extends StatelessWidget {
  const _EmptyPath();

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        children: [
          AppCard(
            color: AppColors.primaryWash,
            shadow: false,
            child: Text(
              '路径只是一层导航：把已有的场景、表达和复练串成阶段，'
              '不排课、不考试、不解锁，随时可以换方向。',
              style: AppText.bodySecondary.copyWith(height: 1.6),
            ),
          ),
          const SizedBox(height: 20),
          EmptyState(
            icon: Icons.map_outlined,
            title: '还没有学习路径',
            message: '回答 3 个问题，就能看到现在在哪、接下来练什么、练完到哪了。',
            actionLabel: '设定我的起点',
            action: () => context.push('/path/setup'),
          ),
          const SizedBox(height: 16),
          SecondaryButton(
            label: '先随便来一段',
            icon: Icons.chat_bubble_outline_rounded,
            onPressed: () => context.push('/scenarios'),
          ),
        ],
      );
}

class _PathBody extends ConsumerWidget {
  const _PathBody({required this.plan});

  final PathPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = plan.state;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      children: [
        _ThreeQuestions(plan: plan),
        const SizedBox(height: 16),
        _StageBar(plan: plan),
        const SizedBox(height: 20),
        SectionTitle(title: '第 ${plan.stage.index} 阶段 · ${plan.stage.name}'),
        const SizedBox(height: 8),
        _StageInfo(plan: plan),
        const SizedBox(height: 20),
        SectionTitle(
          title: '阶段安排',
          actionLabel: '重排本阶段',
          onAction: () => updatePath(
            ref,
            (value) => changePathStage(value, value.stage, DateTime.now()),
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < plan.items.length; i++) ...[
          _ItemCard(index: i + 1, item: plan.items[i]),
          const SizedBox(height: 8),
        ],
        Text(
          '安排可以随时跳过或换顺序，跳过不会锁住后面的内容。'
          '${state.specificGoal.isEmpty ? '' : ' 当前目标：${state.specificGoal}'}',
          style: AppText.caption.copyWith(height: 1.6),
        ),
        const SizedBox(height: 20),
        const SectionTitle(title: '下一步'),
        const SizedBox(height: 8),
        NextStepCard(plan: plan),
        const SizedBox(height: 20),
        _ReviewCard(plan: plan),
        const SizedBox(height: 20),
        _ReturnCard(plan: plan),
        const SizedBox(height: 20),
        _AdjustCard(plan: plan),
      ],
    );
  }
}

class _ThreeQuestions extends StatelessWidget {
  const _ThreeQuestions({required this.plan});

  final PathPlan plan;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _question(
              '我在哪',
              '第 ${plan.stage.index} 阶段 · ${plan.stage.name} · ${plan.state.goalLabel}',
            ),
            const SizedBox(height: 8),
            _question(
              '走到哪了',
              '已完成 ${plan.doneCount} / ${plan.items.length} 条 · 还有 ${plan.pendingCount} 条待练',
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: plan.items.isEmpty ? 0 : plan.doneCount / plan.items.length,
              minHeight: 3,
              backgroundColor: AppColors.line,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 10),
            _question('接下来做什么', plan.nextTitle),
          ],
        ),
      );

  Widget _question(String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: AppText.caption),
          ),
          Expanded(
            child: Text(value, style: AppText.bodySecondary),
          ),
        ],
      );
}

class _StageBar extends ConsumerWidget {
  const _StageBar({required this.plan});

  final PathPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < kPathStages.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    height: 2,
                    color: i < plan.stage.index
                        ? AppColors.primary
                        : AppColors.line,
                  ),
                ),
              ),
            SizedBox(
              width: 60,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => updatePath(
                  ref,
                  (value) => changePathStage(
                    value,
                    kPathStages[i].index,
                    DateTime.now(),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i + 1 <= plan.stage.index
                            ? AppColors.primary
                            : AppColors.surface,
                        border: Border.all(
                          color: i + 1 <= plan.stage.index
                              ? AppColors.primary
                              : AppColors.line,
                          width: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      kPathStages[i].name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(
                        fontSize: 10,
                        color: i + 1 == plan.stage.index
                            ? AppColors.primaryDeep
                            : AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
}

class _StageInfo extends StatelessWidget {
  const _StageInfo({required this.plan});

  final PathPlan plan;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _info('学习目标', plan.stage.goal),
            const SizedBox(height: 10),
            _info('内容范围', plan.stage.scope),
            const SizedBox(height: 10),
            _info('推荐顺序', plan.stage.order),
            const SizedBox(height: 10),
            Text('完成标准', style: AppText.caption),
            const SizedBox(height: 4),
            for (final criterion in plan.stage.criteria) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('· ', style: AppText.bodySecondary),
                    Expanded(
                      child: Text(criterion, style: AppText.bodySecondary),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );

  Widget _info(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption),
          const SizedBox(height: 3),
          Text(value, style: AppText.bodySecondary.copyWith(height: 1.5)),
        ],
      );
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.index, required this.item});

  final int index;
  final PathItem item;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: () => context.push(item.route),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryWash,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$index',
                style: AppText.caption.copyWith(
                  fontSize: 11,
                  color: AppColors.primaryDeep,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: AppText.bodySecondary),
                  const SizedBox(height: 3),
                  Text(
                    item.reason,
                    style: AppText.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AppTag(
              label: pathStatusLabels[item.status] ?? '未开始',
              color: _statusColor(item.status),
            ),
          ],
        ),
      );

  Color _statusColor(String status) => switch (status) {
        'done' => AppColors.success,
        'consolidating' => AppColors.warning,
        'skipped' => AppColors.inkMuted,
        _ => AppColors.primaryDeep,
      };
}

class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({required this.plan});

  final PathPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evaluation = plan.evaluation;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                evaluation.complete ? '可以往前走了' : '还在当前阶段',
                style: AppText.cardTitle,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            evaluation.complete
                ? '下面三条是判断依据，不是分数；想继续练也完全可以。'
                : '还差一点：${evaluation.pending.isEmpty ? '再练几次看看' : evaluation.pending.join(' · ')}',
            style: AppText.caption.copyWith(height: 1.6),
          ),
          const SizedBox(height: 12),
          for (final line in evaluation.evidence) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(line, style: AppText.caption),
            ),
          ],
          if (evaluation.complete) ...[
            const SizedBox(height: 8),
            SecondaryButton(
              label: plan.stage.index < kPathStages.length
                  ? '进入下一阶段'
                  : '继续自主运用',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => updatePath(
                ref,
                (value) => changePathStage(
                  value,
                  (plan.stage.index + 1).clamp(1, kPathStages.length),
                  DateTime.now(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SecondaryButton(
              label: '再巩固一轮',
              icon: Icons.refresh_rounded,
              onPressed: () => updatePath(
                ref,
                (value) => changePathStage(value, value.stage, DateTime.now()),
              ),
            ),
            const SizedBox(height: 8),
            SecondaryButton(
              label: '换个目标重排',
              icon: Icons.tune_rounded,
              onPressed: () => context.push('/path/setup'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReturnCard extends StatelessWidget {
  const _ReturnCard({required this.plan});

  final PathPlan plan;

  @override
  Widget build(BuildContext context) {
    final gap = plan.daysSinceLast >= 3;
    return AppCard(
      color: AppColors.primaryWash,
      shadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            gap
                ? '好几天没练也没关系，从一轮轻量的开始就行。'
                : '今天状态一般？先来一轮 3 分钟轻量，也算保持手感。',
            style: AppText.bodySecondary,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: '接着上次',
                  onPressed: () => context.push('/history'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SecondaryButton(
                  label: '3 分钟轻量',
                  onPressed: () => context.push('/quick'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '轻量练习计入今日分钟，不计入每周 3 次有效练习。',
            style: AppText.caption,
          ),
        ],
      ),
    );
  }
}

class _AdjustCard extends ConsumerWidget {
  const _AdjustCard({required this.plan});

  final PathPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: '调整'),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Column(
              children: [
                SettingRow(
                  icon: Icons.tune_rounded,
                  title: '改目标 / 改起点',
                  subtitle: '只重排计划，不丢历史练习与已巩固内容',
                  value: '重新生成',
                  onTap: () => context.push('/path/setup'),
                ),
                const Divider(height: 1, color: AppColors.divider),
                SettingRow(
                  icon: Icons.insights_rounded,
                  title: '敢开口自评',
                  subtitle: '每月自评一次，只用于阶段回顾',
                  value: '${plan.state.confidence}/5',
                  onTap: () => _pickConfidence(context, ref),
                ),
                const Divider(height: 1, color: AppColors.divider),
                SettingRow(
                  icon: Icons.refresh_rounded,
                  title: '重排本阶段',
                  subtitle: '按最近表现重新挑场景与顺序',
                  onTap: () => updatePath(
                    ref,
                    (value) => changePathStage(value, value.stage, DateTime.now()),
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Future<void> _pickConfidence(BuildContext context, WidgetRef ref) async {
    final picked = await showAppSheet<int>(
      context: context,
      title: '敢开口自评',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final value = index + 1;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text('$value / 5', style: AppText.body),
              trailing: value == plan.state.confidence
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(value),
            );
          }),
        ),
      ),
    );
    if (picked != null) {
      await updatePath(ref, (value) => value.copyWith(confidence: picked));
    }
  }
}
