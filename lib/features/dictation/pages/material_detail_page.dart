import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_metrics.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/widgets/common.dart';
import '../../../core/formatters.dart';
import '../../../domain/models/dictation_models.dart';
import '../align/segment_splitter.dart';
import '../providers.dart';
import '../repository/material_repository.dart';

/// 教材详情（`/materials/:id`）：句子列表 + 状态 + 手动修正时间轴。
class MaterialDetailPage extends ConsumerWidget {
  const MaterialDetailPage({super.key, required this.materialId});

  final String materialId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(materialDetailProvider(materialId));
    return PageScaffold(
      title: '教材详情',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/materials');
        }
      },
      actions: [
        IconButton(
          tooltip: '删除教材',
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
          onPressed: () async {
            final detail = async.asData?.value;
            if (detail == null) return;
            await _deleteMaterial(context, ref, detail);
          },
        ),
      ],
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: ErrorBanner(
            message: '加载教材失败：$error',
            onRetry: () => ref.invalidate(materialDetailProvider(materialId)),
          ),
        ),
        data: (detail) {
          if (detail == null) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                AppCard(
                  child: EmptyState(
                    icon: Icons.folder_off_outlined,
                    title: '教材不存在',
                    message: '这份教材可能已被删除，返回教材库重新导入一份吧。',
                  ),
                ),
              ],
            );
          }
          return _Body(materialId: materialId, detail: detail);
        },
      ),
    );
  }

  Future<void> _deleteMaterial(
    BuildContext context,
    WidgetRef ref,
    MaterialDetail detail,
  ) async {
    final ok = await showConfirmDialog(
      context,
      title: '删除这份教材？',
      message: '会一起删除它的全部句子、听写记录与本机音频副本；视频源文件仍保留在原处。',
      confirmLabel: '删除',
      danger: true,
    );
    if (!ok) return;
    await ref.read(materialRepositoryProvider).deleteMaterial(
          detail.material,
          ref.read(materialImportServiceProvider),
        );
    ref.invalidate(materialLibraryProvider);
    ref.invalidate(materialDetailProvider(materialId));
    ref.invalidate(wrongSegmentsProvider);
    if (context.mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/materials');
      }
    }
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.materialId, required this.detail});

  final String materialId;
  final MaterialDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = detail.material;
    final stats = detail.stats;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: AppText.h2),
              const SizedBox(height: 6),
              Text(
                '共 ${item.segmentCount} 句 · ${formatDuration((item.durationMs / 1000).round())}'
                ' · 已通过 ${stats.passed} 句 / 有错 ${stats.wrong} 句',
                style: AppText.caption,
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: stats.progress,
                  minHeight: 3,
                  backgroundColor: AppColors.line,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: '开始听写',
          icon: Icons.hearing_outlined,
          onPressed: () async {
            await context.push('/materials/$materialId/dictation');
            ref.invalidate(materialDetailProvider(materialId));
            ref.invalidate(materialLibraryProvider);
            ref.invalidate(wrongSegmentsProvider);
          },
        ),
        if (stats.wrong > 0) ...[
          const SizedBox(height: 10),
          SecondaryButton(
            label: '只练错句（${stats.wrong} 句）',
            icon: Icons.replay_rounded,
            onPressed: () async {
              await context.push('/materials/$materialId/dictation?mode=wrong');
              ref.invalidate(materialDetailProvider(materialId));
              ref.invalidate(materialLibraryProvider);
              ref.invalidate(wrongSegmentsProvider);
            },
          ),
        ],
        const SizedBox(height: 24),
        const SectionTitle(title: '句子'),
        const SizedBox(height: 8),
        Text(
          '每句右侧菜单可合并、拆分、微调起止时间或标记「太难」。修改立即生效，不用重新导入。',
          style: AppText.caption.copyWith(height: 1.6),
        ),
        const SizedBox(height: 12),
        if (detail.segments.isEmpty)
          AppCard(
            child: EmptyState(
              icon: Icons.notes_rounded,
              title: '没有可练的句子',
              message: '字幕可能被过滤光了，重新导入一份带对白的字幕吧。',
            ),
          )
        else
          for (var i = 0; i < detail.segments.length; i++) ...[
            _SegmentTile(
              materialId: materialId,
              detail: detail,
              index: i,
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _SegmentTile extends ConsumerWidget {
  const _SegmentTile({
    required this.materialId,
    required this.detail,
    required this.index,
  });

  final String materialId;
  final MaterialDetail detail;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segment = detail.segments[index];
    final attempt = detail.latestBySegment[segment.id];
    final status = attempt == null ? '未练' : (attempt.passed ? '已通过' : '有错');
    final color = attempt == null
        ? AppColors.inkMuted
        : (attempt.passed ? AppColors.success : AppColors.warning);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '${index + 1}'.padLeft(2, '0'),
              style: AppText.caption,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(segment.textEn, style: AppText.bodySecondary.copyWith(height: 1.5)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$status · ${_timeRange(segment)}'
                          '${segment.isHard ? ' · 太难' : ''}',
                      style: AppText.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded, size: 20, color: AppColors.inkMuted),
            tooltip: '调整这句',
            onSelected: (value) async {
              switch (value) {
                case 'merge':
                  await _merge(ref, index);
                  break;
                case 'split':
                  await _split(ref, index);
                  break;
                case 'adjust':
                  await _adjust(context, ref, index);
                  break;
                case 'hard':
                  await ref.read(materialRepositoryProvider).setHard(
                        segment.id,
                        !segment.isHard,
                        detail.segments,
                      );
                  _invalidate(ref);
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'merge', child: Text('与下一句合并')),
              PopupMenuItem(value: 'split', child: Text('把这句拆成两句')),
              PopupMenuItem(value: 'adjust', child: Text('微调起止时间')),
              PopupMenuItem(value: 'hard', child: Text('标记 / 取消「太难」')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _merge(WidgetRef ref, int index) async {
    final segments = detail.segments;
    if (index + 1 >= segments.length) return;
    final a = segments[index];
    final b = segments[index + 1];
    final text = '${a.textEn} ${b.textEn}';
    final merged = a.copyWith(
      textEn: text,
      endMs: b.endMs,
      wordCount: countWords(text),
      isHard: a.isHard || b.isHard,
    );
    final next = [...segments]..removeAt(index + 1);
    next[index] = merged;
    await ref.read(materialRepositoryProvider).saveSegments(materialId, next);
    _invalidate(ref);
  }

  Future<void> _split(WidgetRef ref, int index) async {
    final segment = detail.segments[index];
    final words = segment.textEn.split(RegExp(r'\s+'));
    if (words.length < 4) return;
    final cut = words.length ~/ 2;
    final leftText = words.take(cut).join(' ');
    final rightText = words.skip(cut).join(' ');
    final middle =
        segment.startMs + ((segment.endMs - segment.startMs) * cut / words.length).round();
    final left = segment.copyWith(
      textEn: leftText,
      endMs: middle,
      wordCount: countWords(leftText),
    );
    final right = MaterialSegment(
      id: const Uuid().v4(),
      materialId: segment.materialId,
      seq: segment.seq,
      textEn: rightText,
      startMs: middle,
      endMs: segment.endMs,
      wordCount: countWords(rightText),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    final next = [...detail.segments]..insert(index + 1, right);
    next[index] = left;
    await ref.read(materialRepositoryProvider).saveSegments(materialId, next);
    _invalidate(ref);
  }

  Future<void> _adjust(BuildContext context, WidgetRef ref, int index) async {
    final segment = detail.segments[index];
    final startController = TextEditingController(
      text: (segment.startMs / 1000).toStringAsFixed(2),
    );
    final endController = TextEditingController(
      text: (segment.endMs / 1000).toStringAsFixed(2),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text('微调起止时间', style: AppText.h2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('单位是秒，例如 12.40。前后各留一点余量更不容易切掉首尾音。',
                style: AppText.caption.copyWith(height: 1.6)),
            const SizedBox(height: 12),
            TextField(
              controller: startController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '起点（秒）'),
            ),
            TextField(
              controller: endController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '终点（秒）'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('取消', style: AppText.bodySecondary),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('保存', style: AppText.button.copyWith(color: AppColors.primaryDeep)),
          ),
        ],
      ),
    );
    if (ok != true) {
      startController.dispose();
      endController.dispose();
      return;
    }
    final start = (double.tryParse(startController.text.trim()) ?? segment.startMs / 1000) * 1000;
    final end = (double.tryParse(endController.text.trim()) ?? segment.endMs / 1000) * 1000;
    startController.dispose();
    endController.dispose();
    if (end.round() <= start.round()) return;
    final next = [...detail.segments];
    next[index] = segment.copyWith(startMs: start.round(), endMs: end.round());
    await ref.read(materialRepositoryProvider).saveSegments(materialId, next);
    _invalidate(ref);
  }

  void _invalidate(WidgetRef ref) {
    ref.invalidate(materialDetailProvider(materialId));
    ref.invalidate(materialLibraryProvider);
    ref.invalidate(wrongSegmentsProvider);
  }

  String _timeRange(MaterialSegment segment) =>
      '${(segment.startMs / 1000).toStringAsFixed(1)}–'
      '${(segment.endMs / 1000).toStringAsFixed(1)}s';
}
