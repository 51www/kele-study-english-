import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/widgets/common.dart';
import '../../../core/formatters.dart';
import '../providers.dart';
import '../repository/material_repository.dart';

/// 二期教材库（`/materials`）：首页栏目进入，不新增底部 Tab。
/// 注：教材「导入」入口暂隐藏（功能保留，路由仍在），UI 只暴露查看与练习。
class MaterialLibraryPage extends ConsumerWidget {
  const MaterialLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(materialLibraryProvider);
    return PageScaffold(
      title: '听写教材',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          Text(
            '把自己准备的音频 / 视频和字幕变成逐句可练的教材。听一句、写一句，当场看到差在哪。',
            style: AppText.bodySecondary.copyWith(height: 1.6),
          ),
          const SizedBox(height: 20),
          SectionTitle(
            title: '我的教材',
            actionLabel: '错句本',
            onAction: () => context.push('/materials/wrong'),
          ),
          const SizedBox(height: 12),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
            error: (error, _) => ErrorBanner(
              message: '加载教材失败：$error',
              onRetry: () => ref.invalidate(materialLibraryProvider),
            ),
            data: (items) {
              if (items.isEmpty) {
                return AppCard(
                  child: EmptyState(
                    icon: Icons.hearing_outlined,
                    title: '还没有教材',
                    message: '教材导入功能暂未开放，已导入的教材仍可在「听写教材」里练习。',
                  ),
                );
              }
              return Column(
                children: [
                  for (final summary in items) ...[
                    _MaterialCard(summary: summary),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const _CopyrightNote(),
        ],
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({required this.summary});

  final MaterialSummary summary;

  @override
  Widget build(BuildContext context) {
    final item = summary.item;
    final stats = summary.stats;
    final seconds = (item.durationMs / 1000).round();
    return AppCard(
      onTap: () => context.push('/materials/${item.id}'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryWash,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.hearing_outlined, size: 20, color: AppColors.primaryDeep),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: AppText.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppTag(label: '${item.segmentCount} 句', color: AppColors.primaryDeep),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${formatDuration(seconds)} · 已练 ${stats.practiced} 句'
            '${stats.practiced == 0 ? '' : ' · 正确率 ${(stats.accuracy * 100).round()}%'}',
            style: AppText.caption,
          ),
          const SizedBox(height: 10),
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
    );
  }
}

class _CopyrightNote extends StatelessWidget {
  const _CopyrightNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        '素材版权归原权利人。本功能只处理你自己选择的本地文件，仅供个人学习使用，不下载、不分享。',
        style: AppText.caption.copyWith(height: 1.6),
        textAlign: TextAlign.center,
      ),
    );
  }
}
