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

/// 场景库：分类 Chip + 搜索 + 场景列表 +「练过 N 次」。
///
/// 组件规格见《UI 设计规范》§3.4「场景库新增组件规格」。
class ScenarioLibraryPage extends ConsumerStatefulWidget {
  const ScenarioLibraryPage({super.key});

  @override
  ConsumerState<ScenarioLibraryPage> createState() => _ScenarioLibraryPageState();
}

class _ScenarioLibraryPageState extends ConsumerState<ScenarioLibraryPage> {
  final TextEditingController _search = TextEditingController();
  String _category = '全部';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      if (mounted) setState(() => _query = _search.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(scenarioLibraryProvider);
    return PageScaffold(
      title: '场景库',
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: ErrorBanner(
            message: '场景加载失败：$error',
            onRetry: () => ref.invalidate(scenarioLibraryProvider),
          ),
        ),
        data: (data) => _body(data),
      ),
    );
  }

  Widget _body(ScenarioLibraryData data) {
    final categories = scenarioCategoriesOf(data.scenarios.map((e) => e.category));
    final activeCategory = categories.contains(_category) ? _category : '全部';
    final filtered = data.scenarios.where((scenario) {
      final matchCategory = activeCategory == '全部' || scenario.category == activeCategory;
      final matchQuery = _query.isEmpty ||
          scenario.titleZh.toLowerCase().contains(_query) ||
          scenario.titleEn.toLowerCase().contains(_query) ||
          scenario.userGoal.toLowerCase().contains(_query);
      return matchCategory && matchQuery;
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.xs,
        AppSpacing.page,
        AppSpacing.scrollBottom,
      ),
      itemCount: filtered.isEmpty ? 2 : filtered.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _Header(
            total: data.scenarios.length,
            shown: filtered.length,
            categories: categories,
            activeCategory: activeCategory,
            search: _search,
            query: _query,
            onCategory: (value) => setState(() => _category = value),
            onClear: () {
              _search.clear();
              setState(() => _category = '全部');
            },
          );
        }
        if (filtered.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 72),
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: '没有匹配的场景',
              message: '换个关键词，或把分类切回「全部」再看看。',
            ),
          );
        }
        final scenario = filtered[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _ScenarioTile(
            scenario: scenario,
            practiced: data.practiceCounts[scenario.id] ?? 0,
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.total,
    required this.shown,
    required this.categories,
    required this.activeCategory,
    required this.search,
    required this.query,
    required this.onCategory,
    required this.onClear,
  });

  final int total;
  final int shown;
  final List<String> categories;
  final String activeCategory;
  final TextEditingController search;
  final String query;
  final ValueChanged<String> onCategory;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasFilter = activeCategory != '全部' || query.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('共 $total 个场景 · 按分类挑一个，今天就能开口', style: AppText.caption),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          controller: search,
          hint: '搜索场景名或英文标题',
          prefixIcon: Icons.search_rounded,
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final category in categories) ...[
                _CategoryChip(
                  label: category,
                  selected: category == activeCategory,
                  onTap: () => onCategory(category),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Text('场景', style: AppText.section),
            const Spacer(),
            Text('$shown 个', style: AppText.caption),
            if (hasFilter) ...[
              const SizedBox(width: AppSpacing.xs),
              GestureDetector(
                onTap: onClear,
                child: Text(
                  '清除筛选',
                  style: AppText.caption.copyWith(color: AppColors.primaryDeep),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryTint : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.line,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppText.caption.copyWith(
            fontSize: 11,
            color: selected ? AppColors.primaryDeep : AppColors.inkSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ScenarioTile extends StatelessWidget {
  const _ScenarioTile({required this.scenario, required this.practiced});

  final Scenario scenario;
  final int practiced;

  @override
  Widget build(BuildContext context) {
    final visual = scenarioVisual(scenario.category);
    return AppCard(
      onTap: () => context.push('/scenario/${scenario.id}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: visual.tint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(visual.icon, color: visual.accent, size: 24),
          ),
          const SizedBox(width: AppSpacing.sm),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (practiced > 0) ...[
                      const SizedBox(width: 6),
                      AppTag(label: '练过 $practiced 次', color: AppColors.primaryDeep),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  scenario.titleEn,
                  style: AppText.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${scenario.category} · ${scenario.level} · ${scenario.expectedTurns} 轮 · ${scenario.estimatedMinutes}',
                  style: AppText.caption,
                  maxLines: 1,
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
