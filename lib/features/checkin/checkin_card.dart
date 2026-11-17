import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import '../../domain/models/checkin_models.dart';

/// 打卡类型元数据：标签 / 图标 / 是否手动补记（可点按切换）。
class _TypeMeta {
  const _TypeMeta(this.label, this.icon, this.manual);
  final String label;
  final IconData icon;
  final bool manual;
}

const Map<String, _TypeMeta> _typeMeta = {
  'spoken': _TypeMeta('口语', Icons.chat_bubble_outline_rounded, false),
  'vocab': _TypeMeta('背单词', Icons.menu_book_rounded, true),
  // 材料练习（听写）即影子跟读学习，由练习耗时自动点亮，不再手动补记。
  'shadow': _TypeMeta('影子跟读', Icons.record_voice_over_rounded, false),
};

/// 首页「今日」主卡：打卡状态 + 连续天数 + 学习构成 + 目标进度 + 入口。
/// 自动类型（口语 / 影子跟读）由会话与材料练习聚合；手动类型（背单词）可点按补记。
/// 学习构成按内容自然排列：空间够时同一行，不足时换行，不压缩文字。
class CheckinCard extends ConsumerWidget {
  const CheckinCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeDataProvider);
    final today = ref.watch(todayCheckinProvider);
    return home.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) => today.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (checkin) => _build(context, ref, data, checkin),
      ),
    );
  }

  Widget _build(
    BuildContext context,
    WidgetRef ref,
    HomeData data,
    TodayCheckin checkin,
  ) {
    final checked = checkin.checkedIn;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('今日打卡', style: AppText.cardTitle.copyWith(color: Colors.white)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text('连续 ${data.streakDays} 天',
                        style: AppText.caption.copyWith(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            checked ? '今天已经打卡' : '今天还没打卡',
            style: AppText.h2.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.buttonGap),
          Wrap(
            spacing: AppSpacing.element,
            runSpacing: AppSpacing.element,
            children: _typeMeta.entries
                .map((e) => _chip(e, checkin, ref))
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('今日 ${data.todayMinutes} / ${data.targetMinutes} 分钟',
                  style: AppText.caption.copyWith(color: Colors.white)),
              const Spacer(),
              Text('本周 ${data.weekSessions} 次',
                  style: AppText.caption.copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: data.targetMinutes > 0
                  ? (data.todayMinutes / data.targetMinutes).clamp(0.0, 1.0)
                  : 0.0,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          if (checked)
            TextButton(
              onPressed: () => context.push('/checkin'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('查看打卡日历'),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            )
          else
            SecondaryButton(
              label: '开始今日学习',
              icon: Icons.play_arrow_rounded,
              onPressed: () => context.push('/scenarios'),
            ),
        ],
      ),
    );
  }

  Widget _chip(
    MapEntry<String, _TypeMeta> entry,
    TodayCheckin checkin,
    WidgetRef ref,
  ) {
    final meta = entry.value;
    final active = checkin.allTypes.contains(entry.key);
    final chip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.element,
        vertical: AppSpacing.tight,
      ),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: active ? null : Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(meta.icon, size: 14, color: active ? AppColors.primaryDeep : Colors.white),
          const SizedBox(width: AppSpacing.tight),
          Text(
            meta.label,
            style: AppText.caption.copyWith(
              color: active ? AppColors.primaryDeep : Colors.white,
            ),
          ),
        ],
      ),
    );
    if (!meta.manual) return chip;
    return GestureDetector(
      onTap: () => _toggleManual(ref, checkin.date, entry.key),
      child: chip,
    );
  }

  Future<void> _toggleManual(WidgetRef ref, String date, String type) async {
    await ref.read(checkinRepositoryProvider).toggleType(date, type);
    final now = DateTime.now();
    ref.invalidate(todayCheckinProvider);
    ref.invalidate(checkinMonthProvider('${now.year}-${now.month}'));
    ref.invalidate(homeDataProvider);
  }
}
