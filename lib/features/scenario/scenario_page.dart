import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import '../../domain/models/models.dart';
import 'scenario_visual.dart';

class ScenarioPage extends ConsumerStatefulWidget {
  const ScenarioPage({super.key, required this.scenarioId});

  final String scenarioId;

  @override
  ConsumerState<ScenarioPage> createState() => _ScenarioPageState();
}

class _ScenarioPageState extends ConsumerState<ScenarioPage> {
  bool _starting = false;

  Future<void> _start(Scenario scenario) async {
    if (_starting) return;
    final profile = await ref.read(profileInfoProvider.future);
    if (!profile.hasKey) {
      if (!mounted) return;
      final go = await showConfirmDialog(
        context,
        title: '还没有配置密钥',
        message: '对话需要模型接口。先去填写接口地址与密钥吗？',
        confirmLabel: '去配置',
      );
      if (go && mounted) context.push('/settings/model');
      return;
    }
    setState(() => _starting = true);
    try {
      final settings = ref.read(settingsControllerProvider);
      final session = await ref.read(sessionRepositoryProvider).createSession(
            scenario: scenario,
            modelName: profile.profile.model,
            ttsEngine: settings[SettingsKeys.ttsEngine] ?? 'edge',
          );
      if (!mounted) return;
      await context.push('/chat/${session.id}');
      ref.invalidate(homeDataProvider);
      ref.invalidate(recentSessionsProvider);
    } catch (e) {
      if (mounted) showAppToast(context, '创建练习失败：$e', error: true);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(scenarioProvider(widget.scenarioId));
    return async.when(
      loading: () => const PageScaffold(
        title: '场景',
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (error, _) => PageScaffold(
        title: '场景',
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ErrorBanner(
            message: '场景加载失败：$error',
            onRetry: () => ref.invalidate(scenarioProvider(widget.scenarioId)),
          ),
        ),
      ),
      data: (scenario) {
        if (scenario == null) {
          return PageScaffold(
            title: '场景',
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: '没有找到这个场景',
              message: '它可能已被删除，回首页选一个场景继续练吧。',
              actionLabel: '回首页',
              action: () => context.go('/home'),
            ),
          );
        }
        return PageScaffold(
          title: '场景详情',
          bottomBar: _StartBar(
            loading: _starting,
            onStart: () => _start(scenario),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Hero(scenario: scenario),
                    const SizedBox(height: 24),
                    SectionTitle(title: '你会练习什么'),
                    const SizedBox(height: 10),
                    _GoalList(scenario: scenario),
                    const SizedBox(height: 22),
                    SectionTitle(title: 'AI 会扮演'),
                    const SizedBox(height: 10),
                    AppCard(
                      shadow: false,
                      color: AppColors.surfaceTint,
                      child: Text(
                        scenario.aiRole,
                        style: AppText.bodySecondary.copyWith(color: AppColors.ink, height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SectionTitle(title: '目标表达'),
                    const SizedBox(height: 10),
                    ...scenario.targetPhrases.map(
                      (phrase) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryWash,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(phrase, style: AppText.body.copyWith(fontSize: 13)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SectionTitle(title: '完成标准'),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            scenario.successCriteria,
                            style: AppText.bodySecondary.copyWith(height: 1.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _Pill(icon: Icons.schedule_rounded, label: scenario.estimatedMinutes),
                        const SizedBox(width: 10),
                        _Pill(icon: Icons.forum_outlined, label: '${scenario.expectedTurns} 轮对话'),
                        const SizedBox(width: 10),
                        _Pill(icon: Icons.signal_cellular_alt_rounded, label: scenario.level),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.scenario});

  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    final visual = scenarioVisual(scenario.category);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7F98FF), Color(0xFF5A74F0)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(visual.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(scenario.titleZh, style: AppText.h1.copyWith(color: Colors.white)),
                    const SizedBox(height: 3),
                    Text(
                      '${scenario.category} · ${scenario.titleEn}',
                      style: AppText.caption.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              AppTag(
                label: scenario.level,
                color: Colors.white,
                background: Colors.white.withValues(alpha: 0.2),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            scenario.userGoal,
            style: AppText.body.copyWith(color: Colors.white.withValues(alpha: 0.92), height: 1.55),
          ),
        ],
      ),
    );
  }
}

class _GoalList extends StatelessWidget {
  const _GoalList({required this.scenario});

  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    final goals = <String>[
      '用英语完成「${scenario.titleZh}」的完整流程',
      '至少说出 ${scenario.targetPhrases.length} 组目标表达',
      '遇到卡壳时使用提示继续，而不是退回中文',
    ];
    return Column(
      children: goals
          .map(
            (goal) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(goal, style: AppText.bodySecondary.copyWith(height: 1.5))),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.inkMuted),
          const SizedBox(width: 4),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }
}

class _StartBar extends StatelessWidget {
  const _StartBar({required this.loading, required this.onStart});

  final bool loading;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: PrimaryButton(
              label: '开始练习',
              icon: Icons.mic_rounded,
              loading: loading,
              onPressed: onStart,
            ),
          ),
        ),
      ),
    );
  }
}
