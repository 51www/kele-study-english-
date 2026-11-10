import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/shell.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import '../../core/formatters.dart';
import '../../domain/models/models.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(homeDataProvider);
    final profile = ref.watch(profileInfoProvider).asData?.value;
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(homeDataProvider),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: shellPagePadding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopBar(streak: async.asData?.value.streakDays ?? 0),
                const SizedBox(height: 22),
                async.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  ),
                  error: (error, _) => ErrorBanner(
                    message: '加载首页失败：$error',
                    onRetry: () => ref.invalidate(homeDataProvider),
                  ),
                  data: (data) => _Body(data: data),
                ),
                if (profile != null && !profile.hasKey) ...[
                  const SizedBox(height: 16),
                  _SetupHint(
                    onTap: () => context.push('/settings/model'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${greetingForNow()}，', style: AppText.bodySecondary.copyWith(fontSize: 14)),
              const SizedBox(height: 2),
              Text('今天想开口说点什么？', style: AppText.h1.copyWith(fontSize: 22)),
              if (streak > 0) ...[
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, size: 13, color: AppColors.orange),
                    const SizedBox(width: 3),
                    Text('连续练习 $streak 天', style: AppText.caption.copyWith(fontSize: 10)),
                  ],
                ),
              ],
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            boxShadow: AppShadows.soft,
            border: Border.all(color: Colors.white, width: 2),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.wb_sunny_rounded, color: AppColors.orange, size: 22),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.data});

  final HomeData data;

  @override
  Widget build(BuildContext context) {
    final target = data.targetMinutes;
    final progress = (data.todayMinutes / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GoalCard(
          minutes: data.todayMinutes,
          turns: data.todayTurns,
          weekSessions: data.weekSessions,
          target: target,
          progress: progress.toDouble(),
        ),
        const SizedBox(height: 26),
        SectionTitle(
          title: '场景练习',
          actionLabel: data.totalSessions > 0 ? '练习记录' : null,
          onAction: () => context.go('/history'),
        ),
        const SizedBox(height: 12),
        if (data.scenarios.isEmpty)
          AppCard(
            child: EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: '还没有场景',
              message: '内置场景尚未加载，请稍后重试。',
            ),
          )
        else
          ...data.scenarios.take(2).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final scenario = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: index == 0
                  ? _FeatureScenarioCard(scenario: scenario)
                  : _ScenarioCard(scenario: scenario),
            );
          }),
        if (data.lastStuck != null) ...[
          const SizedBox(height: 22),
          SectionTitle(
            title: '上次卡在哪',
            actionLabel: '看复盘',
            onAction: () => context.push('/review/${data.lastStuck!.sessionId}'),
          ),
          const SizedBox(height: 10),
          _StuckCard(correction: data.lastStuck!),
        ],
        if (data.lastSession != null) ...[
          const SizedBox(height: 14),
          SectionTitle(
            title: '继续上次',
            actionLabel: '全部记录',
            onAction: () => context.go('/history'),
          ),
          const SizedBox(height: 10),
          _LastSessionCard(session: data.lastSession!, scenarios: data.scenarios),
        ],
        const SizedBox(height: 24),
        const _TipsEntry(),
      ],
    );
  }
}

class _StuckCard extends StatelessWidget {
  const _StuckCard({required this.correction});

  final Correction correction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_rounded, size: 16, color: AppColors.warning),
              const SizedBox(width: 6),
              Text('上次这句可以换个说法', style: AppText.caption.copyWith(color: AppColors.inkSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            correction.original,
            style: AppText.bodySecondary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(correction.improved, style: AppText.body.copyWith(color: AppColors.primaryDeep)),
          const SizedBox(height: 6),
          Text(correction.reasonZh, style: AppText.caption),
        ],
      ),
    );
  }
}

/// 发现内容放在首页栏目区块里，不新增独立 Tab、不改底部导航。
class _TipsEntry extends StatelessWidget {
  const _TipsEntry();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: '方法 / 技巧'),
        const SizedBox(height: 10),
        AppCard(
          onTap: () => context.push('/tips'),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryWash,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_book_outlined, color: AppColors.primaryDeep, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('练口语的实用方法', style: AppText.cardTitle),
                    SizedBox(height: 3),
                    Text(
                      '第三方文章全文 · 保留出处与原文链接',
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.minutes,
    required this.turns,
    required this.weekSessions,
    required this.target,
    required this.progress,
  });

  final int minutes;
  final int turns;
  final int weekSessions;
  final int target;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDeep],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                '今日练习',
                style: AppText.caption.copyWith(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '目标 $target 分钟',
                  style: AppText.tag.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$minutes',
                style: AppText.display.copyWith(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 5),
                child: Text(
                  '分钟',
                  style: AppText.body.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ),
              const Spacer(),
              _GoalMetric(label: '本周', value: '$weekSessions 次'),
              const SizedBox(width: 16),
              _GoalMetric(label: '开口轮次', value: '$turns'),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            progress >= 1 ? '今天的练习目标达成啦，真不错。' : '今天再练 ${(target - minutes).clamp(0, target)} 分钟就达成目标。',
            style: AppText.caption.copyWith(color: Colors.white.withValues(alpha: 0.78)),
          ),
        ],
      ),
    );
  }
}

class _GoalMetric extends StatelessWidget {
  const _GoalMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: AppText.h2.copyWith(color: Colors.white, fontSize: 22),
        ),
        Text(
          label,
          style: AppText.caption.copyWith(color: Colors.white.withValues(alpha: 0.72)),
        ),
      ],
    );
  }
}

class _FeatureScenarioCard extends StatelessWidget {
  const _FeatureScenarioCard({required this.scenario});

  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/scenario/${scenario.id}'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ScenarioIcon(scenario: scenario),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(scenario.titleZh, style: AppText.cardTitle.copyWith(fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(
                        scenario.titleEn,
                        style: AppText.caption.copyWith(color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                ),
                AppTag(label: scenario.level, color: AppColors.primaryDeep),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              scenario.userGoal,
              style: AppText.bodySecondary.copyWith(height: 1.55),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _Meta(icon: Icons.schedule_rounded, text: scenario.estimatedMinutes),
                const SizedBox(width: 14),
                _Meta(icon: Icons.forum_outlined, text: '${scenario.expectedTurns} 轮对话'),
                const Spacer(),
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryWash,
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.primaryDeep),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({required this.scenario});

  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/scenario/${scenario.id}'),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _ScenarioIcon(scenario: scenario, tint: AppColors.surfaceTint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        scenario.titleZh,
                        style: AppText.cardTitle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    AppTag(label: scenario.level, color: AppColors.inkSecondary, background: AppColors.surfaceTint),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${scenario.titleEn} · ${scenario.estimatedMinutes}',
                  style: AppText.caption,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
        ],
      ),
    );
  }
}

class _ScenarioIcon extends StatelessWidget {
  const _ScenarioIcon({required this.scenario, this.tint = AppColors.primaryWash});

  final Scenario scenario;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final isCafe = scenario.id.contains('cafe');
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        isCafe ? Icons.local_cafe_rounded : Icons.groups_2_rounded,
        color: isCafe ? AppColors.orange : AppColors.primaryDeep,
        size: 24,
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.inkMuted),
        const SizedBox(width: 4),
        Text(text, style: AppText.caption),
      ],
    );
  }
}

class _LastSessionCard extends StatelessWidget {
  const _LastSessionCard({required this.session, required this.scenarios});

  final SessionRecord session;
  final List<Scenario> scenarios;

  @override
  Widget build(BuildContext context) {
    final scenario = scenarios.where((e) => e.id == session.scenarioId).firstOrNull;
    final completed = session.status == 'completed';
    return AppCard(
      onTap: () => context.push(completed ? '/review/${session.id}' : '/chat/${session.id}'),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.mint.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              completed ? Icons.check_rounded : Icons.play_arrow_rounded,
              color: AppColors.success,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scenario?.titleZh ?? '自由对话', style: AppText.cardTitle),
                const SizedBox(height: 2),
                Text(
                  '${completed ? '已完成' : '未完成'} · ${formatDate(session.startedDate)} · ${session.turnCount} 轮 · ${formatMinutes(session.durationSec)}',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
        ],
      ),
    );
  }
}

class _SetupHint extends StatelessWidget {
  const _SetupHint({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      color: AppColors.warning.withValues(alpha: 0.10),
      shadow: false,
      child: Row(
        children: [
          const Icon(Icons.key_rounded, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '还没填写模型密钥，配置后才能开始对话。',
              style: AppText.caption.copyWith(color: AppColors.ink, fontSize: 12),
            ),
          ),
          Text(
            '去配置',
            style: AppText.caption.copyWith(color: AppColors.primaryDeep, fontWeight: FontWeight.w700),
          ),
          const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primaryDeep),
        ],
      ),
    );
  }
}
