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
import '../scenario/scenario_visual.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recentSessionsProvider);
    final scenarios = ref.watch(homeDataProvider).asData?.value.scenarios ?? const <Scenario>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('练习记录', style: AppText.h1),
              const SizedBox(height: 4),
              Text('每一次开口都算数', style: AppText.bodySecondary),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ErrorBanner(
                  message: '加载记录失败：$error',
                  onRetry: () => ref.invalidate(recentSessionsProvider),
                ),
              ),
            ),
            data: (sessions) {
              if (sessions.isEmpty) {
                return SingleChildScrollView(
                  padding: shellPagePadding,
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 260,
                    child: EmptyState(
                      icon: Icons.history_rounded,
                      title: '还没有练习记录',
                      message: '完成一次场景对话后，这里会留下你的复盘与进步。',
                      actionLabel: '去练习',
                      action: () => context.go('/home'),
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: shellPagePadding,
                itemCount: sessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  final scenario = scenarios.where((e) => e.id == session.scenarioId).firstOrNull;
                  return Dismissible(
                    key: ValueKey(session.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                    ),
                    confirmDismiss: (_) => showConfirmDialog(
                      context,
                      title: '删除这条练习？',
                      message: '会话、对话原文、本条纠错与从这次练习存下的表达会一并删除，不可恢复。',
                      confirmLabel: '删除',
                    ),
                    onDismissed: (_) async {
                      await ref.read(sessionRepositoryProvider).deleteSession(session.id);
                      ref.invalidate(recentSessionsProvider);
                      ref.invalidate(homeDataProvider);
                      ref.invalidate(phrasesProvider);
                      ref.invalidate(monthlyCostProvider);
                      ref.invalidate(scenarioLibraryProvider);
                      if (context.mounted) showAppToast(context, '已删除该条练习');
                    },
                    child: _HistoryCard(
                      session: session,
                      scenario: scenario,
                      onTap: () => context.push(
                            session.status == 'completed'
                                ? '/review/${session.id}'
                                : '/chat/${session.id}',
                          ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.session, required this.scenario, required this.onTap});

  final SessionRecord session;
  final Scenario? scenario;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (session.status) {
      'completed' => '已完成',
      'in_progress' => '进行中',
      _ => '草稿',
    };
    final statusColor = session.status == 'completed' ? AppColors.success : AppColors.warning;
    final resumable = session.status != 'completed' && session.turnCount > 0;
    final visual = scenarioVisual(scenario?.category);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: visual.tint,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(visual.icon, color: visual.accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        scenario?.titleZh ?? '自由对话',
                        style: AppText.cardTitle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        statusLabel,
                        style: AppText.tag.copyWith(color: statusColor, fontSize: 9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${formatDate(session.startedDate)} · ${session.turnCount} 轮 · ${formatMinutes(session.durationSec)}',
                  style: AppText.caption,
                ),
                if (resumable) ...[
                  const SizedBox(height: 2),
                  Text(
                    '点按继续这段对话',
                    style: AppText.caption.copyWith(color: AppColors.primaryDeep),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
        ],
      ),
    );
  }
}
