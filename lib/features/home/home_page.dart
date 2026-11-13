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
import '../checkin/checkin_card.dart';
import '../retention/today_card.dart';

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
                const _TopBar(),
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
  const _TopBar();

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CheckinCard(),
        const SizedBox(height: 20),
        const TodayPracticeCard(),
        const SizedBox(height: 20),
        _PracticeGrid(scenarioCount: data.scenarios.length),
        const SizedBox(height: 16),
        const _TipsEntry(),
      ],
    );
  }
}

/// 练习入口一行三卡：场景练习 / 复盘复练 / 3 分钟轻量。
/// 收纳原首页散落的轻量按钮与听写栏目，统一形态、缩短操作路径。
class _PracticeGrid extends StatelessWidget {
  const _PracticeGrid({required this.scenarioCount});

  final int scenarioCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _entryCard(
            context,
            icon: Icons.chat_bubble_outline_rounded,
            tint: AppColors.primaryDeep,
            title: '场景练习',
            subtitle: '$scenarioCount 个内置场景',
            route: '/scenarios',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _entryCard(
            context,
            icon: Icons.refresh_rounded,
            tint: AppColors.mint,
            title: '复盘复练',
            subtitle: '把说错的练熟',
            route: '/retention',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _entryCard(
            context,
            icon: Icons.bolt_rounded,
            tint: AppColors.orange,
            title: '3 分钟轻量',
            subtitle: '碎片时间也能练',
            route: '/quick',
          ),
        ),
      ],
    );
  }

  Widget _entryCard(
    BuildContext context, {
    required IconData icon,
    required Color tint,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return AppCard(
      onTap: () => context.push(route),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: tint, size: 18),
          ),
          const SizedBox(height: 8),
          Text(title, style: AppText.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(subtitle,
              style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
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
