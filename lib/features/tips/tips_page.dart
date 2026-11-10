import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';

/// 「方法 / 技巧」栏目：首页里的区块入口，不是独立 Tab。
class TipsPage extends ConsumerStatefulWidget {
  const TipsPage({super.key});

  @override
  ConsumerState<TipsPage> createState() => _TipsPageState();
}

class _TipsPageState extends ConsumerState<TipsPage> {
  String _category = '全部';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(tipsProvider);
    return PageScaffold(
      title: '方法 / 技巧',
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: ErrorBanner(
            message: '文章列表加载失败：$error',
            onRetry: () => ref.invalidate(tipsProvider),
          ),
        ),
        data: (articles) {
          if (articles.isEmpty) {
            return const EmptyState(
              icon: Icons.menu_book_outlined,
              title: '还没有文章',
              message: '本地文章包尚未就绪，稍后再来看看。',
            );
          }
          final categories = <String>{
            '全部',
            for (final article in articles) article.category,
          }.toList();
          final shown = _category == '全部'
              ? articles
              : articles.where((e) => e.category == _category).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, AppSpacing.scrollBottom),
            children: [
              Text(
                '别人怎么练口语 · 站内全文阅读，保留出处与原文链接',
                style: AppText.caption,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final item = categories[index];
                    final selected = item == _category;
                    return GestureDetector(
                      onTap: () => setState(() => _category = item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primaryWash : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: selected ? AppColors.primary : AppColors.line,
                          ),
                        ),
                        child: Text(
                          item,
                          style: AppText.caption.copyWith(
                            color: selected ? AppColors.primaryDeep : AppColors.inkSecondary,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ...shown.map(
                (article) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    onTap: () => context.push('/tips/${article.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppTag(label: article.category, color: AppColors.primaryDeep),
                            const Spacer(),
                            Text(article.publishedAt, style: AppText.caption),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          article.title,
                          style: AppText.cardTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          article.summary,
                          style: AppText.bodySecondary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.open_in_new_rounded, size: 12, color: AppColors.inkMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${article.source} · ${article.author}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.caption,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right_rounded,
                                size: 18, color: AppColors.inkMuted),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
