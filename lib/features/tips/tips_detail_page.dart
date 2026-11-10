import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import 'tips_repository.dart';

/// 第三方文章的站内全文阅读副本：保留段落小标题、出处与原文链接。
/// 图片不下载，正文里的图片位置统一显示为「[图：说明]」。
class TipsDetailPage extends ConsumerWidget {
  const TipsDetailPage({super.key, required this.articleId});

  final String articleId;

  Future<void> _openOriginal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tipsProvider);
    return PageScaffold(
      title: '技巧详情',
      bottomBar: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        child: SafeArea(
          top: false,
          child: Text(
            '内容版权归原作者，仅作个人学习使用。',
            textAlign: TextAlign.center,
            style: AppText.caption,
          ),
        ),
      ),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: ErrorBanner(message: '文章加载失败：$error'),
        ),
        data: (articles) {
          final article = articles.where((e) => e.id == articleId).firstOrNull;
          if (article == null) {
            return EmptyState(
              icon: Icons.article_outlined,
              title: '没有找到这篇文章',
              message: '它可能已不在本地文章包里，返回列表看看其他方法。',
              actionLabel: '返回列表',
              action: () => context.go('/tips'),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            children: [
              Text(article.title, style: AppText.h2),
              const SizedBox(height: 10),
              Row(
                children: [
                  AppTag(label: article.category, color: AppColors.primaryDeep),
                  const SizedBox(width: 8),
                  Text('${article.source} · ${article.publishedAt}', style: AppText.caption),
                ],
              ),
              const SizedBox(height: 14),
              AppCard(
                color: AppColors.primaryWash,
                shadow: false,
                padding: const EdgeInsets.all(14),
                child: Text(
                  article.summary,
                  style: AppText.bodySecondary.copyWith(color: AppColors.ink, height: 1.6),
                ),
              ),
              const SizedBox(height: 20),
              ..._contentWidgets(article),
              const SizedBox(height: 24),
              _SourceBlock(article: article, onOpen: () => _openOriginal(article.url)),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _contentWidgets(TipArticle article) {
    final widgets = <Widget>[];
    for (final raw in article.displayContent.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 12));
        continue;
      }
      if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(line.substring(3).trim(), style: AppText.section),
        ));
      } else if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(line.substring(2).trim(), style: AppText.h2),
        ));
      } else if (line.startsWith('[图：')) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(line, style: AppText.caption),
          ),
        ));
      } else {
        widgets.add(Text(
          line,
          style: AppText.body.copyWith(height: 1.7),
        ));
      }
    }
    return widgets;
  }
}

class _SourceBlock extends StatelessWidget {
  const _SourceBlock({required this.article, required this.onOpen});

  final TipArticle article;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.source_outlined, size: 16, color: AppColors.primaryDeep),
              const SizedBox(width: 8),
              Text('出处', style: AppText.cardTitle),
            ],
          ),
          const SizedBox(height: 12),
          _SourceRow(label: '原文标题', value: article.title),
          _SourceRow(label: '作者', value: article.author),
          _SourceRow(label: '平台', value: article.source),
          if (article.publishedAt.isNotEmpty)
            _SourceRow(label: '发布时间', value: article.publishedAt),
          if (article.url.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onOpen,
              child: Row(
                children: [
                  const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.primaryDeep),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '原文链接：${article.url}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(color: AppColors.primaryDeep),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(label, style: AppText.caption),
          ),
          Expanded(
            child: Text(value, style: AppText.bodySecondary.copyWith(color: AppColors.ink)),
          ),
        ],
      ),
    );
  }
}
