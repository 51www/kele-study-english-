import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import 'practice_card.dart';
import 'review_item.dart';

/// 复练中心：到期的复练项按确定性顺序排列，第一条直接可练。
class RetentionPage extends ConsumerStatefulWidget {
  const RetentionPage({super.key});

  @override
  ConsumerState<RetentionPage> createState() => _RetentionPageState();
}

class _RetentionPageState extends ConsumerState<RetentionPage> {
  bool? _lastPassed;

  @override
  Widget build(BuildContext context) {
    final due = ref.watch(dueReviewItemsProvider);
    final all = ref.watch(reviewItemsProvider);
    return PageScaffold(
      title: '今日复练',
      showBack: true,
      onBack: () => context.go('/home'),
      child: due.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => ErrorBanner(
          message: '读取复练队列失败：$error',
          onRetry: () => ref.invalidate(reviewItemsProvider),
        ),
        data: (items) => ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            if (_lastPassed != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _lastPassed!
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.warning.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _lastPassed!
                      ? '已过 · 这条进入下一档，隔几天再回来。'
                      : '还没说全 · 这条明天还会回来找你。',
                  style: AppText.body,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              '上次的错会自己回来，一次只练一条。',
              style: AppText.bodySecondary,
            ),
            const SizedBox(height: 14),
            if (items.isEmpty)
              AppCard(
                child: EmptyState(
                  icon: Icons.check_circle_outline_rounded,
                  title: '今天没有到期的复练',
                  message: '练完一次对话并复盘后，重点句子会在第二天回来找你。',
                  actionLabel: '去挑个场景',
                  action: () => context.push('/scenarios'),
                ),
              )
            else ...[
              TakeawayPracticeCard(
                item: items.first,
                onCompleted: (passed) {
                  if (mounted) setState(() => _lastPassed = passed);
                },
              ),
              if (items.length > 1) ...[
                const SizedBox(height: 20),
                Text('接下来还有 ${items.length - 1} 条', style: AppText.cardTitle),
                const SizedBox(height: 8),
                for (final item in items.skip(1)) _QueueTile(item: item),
              ],
            ],
            const SizedBox(height: 16),
            SecondaryButton(
              label: '从表达本 / 错句本补充',
              icon: Icons.playlist_add_rounded,
              onPressed: () async {
                final count =
                    await syncRetentionSources(ref.read(localStoreProvider));
                ref.invalidate(reviewItemsProvider);
                ref.invalidate(dueReviewItemsProvider);
                ref.invalidate(todayPlanProvider);
                if (context.mounted) {
                  showAppToast(
                    context,
                    count == 0
                        ? '表达本和错句本里的句子都已在队列'
                        : '补充了 $count 条复练',
                  );
                }
              },
            ),
            const SizedBox(height: 24),
            all.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (rows) => Text(
                '队列共 ${rows.length} 条 · 已巩固 ${rows.where((e) => e.consolidated).length} 条',
                style: AppText.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({required this.item});

  final ReviewItem item;

  @override
  Widget build(BuildContext context) {
    final d = DateTime.fromMillisecondsSinceEpoch(item.dueAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.schedule_rounded,
                size: 18, color: AppColors.inkMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.textEn, style: AppText.body, maxLines: 2),
                  const SizedBox(height: 3),
                  Text(
                    '第 ${item.stage + 1} 档 · ${d.month}/${d.day} 到期',
                    style: AppText.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
