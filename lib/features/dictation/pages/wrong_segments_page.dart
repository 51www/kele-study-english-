import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/widgets/common.dart';
import '../providers.dart';
import '../repository/material_repository.dart';

/// 二期错句本（`/materials/wrong`）：跨教材汇总最近一次未通过的句子。
class WrongSegmentsPage extends ConsumerWidget {
  const WrongSegmentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(wrongSegmentsProvider);
    return PageScaffold(
      title: '错句本',
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: ErrorBanner(
            message: '加载错句失败：$error',
            onRetry: () => ref.invalidate(wrongSegmentsProvider),
          ),
        ),
        data: (entries) => _Body(entries: entries),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.entries});

  final List<WrongEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = <String, List<WrongEntry>>{};
    final materials = <String, String>{};
    for (final entry in entries) {
      (groups[entry.material.id] ??= <WrongEntry>[]).add(entry);
      materials[entry.material.id] = entry.material.title;
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Text(
          '这里汇总各教材里最近一次没通过的句子。练过通过后会自动从这里移除。',
          style: AppText.bodySecondary.copyWith(height: 1.6),
        ),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          AppCard(
            child: EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: '目前没有错句',
              message: '去教材库听几句，判分没通过的句子会自动收进这里。',
              action: () => context.push('/materials'),
              actionLabel: '去教材库',
            ),
          )
        else ...[
          PrimaryButton(
            label: '只练全部错句（${entries.length} 句）',
            icon: Icons.replay_rounded,
            onPressed: () async {
              await context.push('/materials/wrong/dictation');
              ref.invalidate(wrongSegmentsProvider);
              ref.invalidate(materialLibraryProvider);
            },
          ),
          const SizedBox(height: 24),
          for (final materialId in groups.keys) ...[
            SectionTitle(
              title: materials[materialId] ?? '教材',
              actionLabel: '练这份的错句',
              onAction: () async {
                await context.push('/materials/$materialId/dictation?mode=wrong');
                ref.invalidate(wrongSegmentsProvider);
                ref.invalidate(materialLibraryProvider);
              },
            ),
            const SizedBox(height: 10),
            for (final entry in groups[materialId]!) ...[
              _WrongRow(entry: entry),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
          ],
        ],
      ],
    );
  }
}

class _WrongRow extends StatelessWidget {
  const _WrongRow({required this.entry});

  final WrongEntry entry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.segment.textEn, style: AppText.bodySecondary.copyWith(height: 1.5)),
                const SizedBox(height: 6),
                Text(
                  '最近一次 ${(entry.attempt.accuracy * 100).round()}% · '
                  '${(entry.segment.startMs / 1000).toStringAsFixed(1)}–'
                  '${(entry.segment.endMs / 1000).toStringAsFixed(1)}s',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
