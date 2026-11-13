import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// 打卡日历页：月度网格 + 当月统计 + 每日明细（自动活动 + 手动补记）。
/// 纯本地数据，断网可看；不展示分数 / 等级 / 排名（需求 §0.4 红线）。
class CheckinCalendarPage extends ConsumerStatefulWidget {
  const CheckinCalendarPage({super.key});

  @override
  ConsumerState<CheckinCalendarPage> createState() => _CheckinCalendarPageState();
}

class _CheckinCalendarPageState extends ConsumerState<CheckinCalendarPage> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  void _shift(int delta) {
    final now = DateTime.now();
    final next = DateTime(_year, _month + delta, 1);
    // 不允许翻到晚于当前月的未来。
    if (next.year > now.year ||
        (next.year == now.year && next.month > now.month)) {
      return;
    }
    setState(() {
      _year = next.year;
      _month = next.month;
    });
  }

  String get _key => '$_year-$_month';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(checkinMonthProvider(_key));
    final now = DateTime.now();
    return PageScaffold(
      title: '打卡日历',
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('加载失败')),
        data: (month) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _stats(month),
            const SizedBox(height: 16),
            _navBar(now),
            const SizedBox(height: 12),
            _weekHeader(),
            const SizedBox(height: 8),
            _grid(month),
          ],
        ),
      ),
    );
  }

  Widget _stats(CheckinMonth month) => Row(
        children: [
          _stat('本月打卡', '${month.checkedDays} 天'),
          _stat('当前连续', '${month.currentStreak} 天'),
          _stat('最长连续', '${month.longestStreak} 天'),
        ],
      );

  Widget _stat(String label, String value) => Expanded(
        child: AppCard(
          child: Column(
            children: [
              Text(value, style: AppText.h2.copyWith(color: AppColors.primaryDeep)),
              const SizedBox(height: 4),
              Text(label, style: AppText.caption),
            ],
          ),
        ),
      );

  Widget _navBar(DateTime now) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => _shift(-1),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text('$_year 年 $_month 月', style: AppText.section),
          IconButton(
            onPressed:
                (_year == now.year && _month == now.month) ? null : () => _shift(1),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      );

  Widget _weekHeader() => Row(
        children: const ['一', '二', '三', '四', '五', '六', '日']
            .map((d) => Expanded(
                  child: Center(
                    child: Text(d, style: AppText.caption),
                  ),
                ))
            .toList(),
      );

  Widget _grid(CheckinMonth month) {
    final firstWeekday = DateTime(_year, _month, 1).weekday; // 1=Mon
    final daysInMonth = DateTime(_year, _month + 1, 0).day;
    final leading = firstWeekday - 1;
    final now = DateTime.now();
    final cells = <Widget>[];
    for (var i = 0; i < leading; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final isToday =
          _year == now.year && _month == now.month && day == now.day;
      final d = month.days[day];
      final checked = d?.checkedIn ?? false;
      cells.add(
        GestureDetector(
          onTap: () => _openDay(day),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: checked
                  ? AppColors.primary
                  : (isToday
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : Colors.transparent),
              border: isToday && !checked
                  ? Border.all(color: AppColors.primaryDeep, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: AppText.body.copyWith(
                  color: checked
                      ? Colors.white
                      : (isToday ? AppColors.primaryDeep : AppColors.ink),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cells,
    );
  }

  void _openDay(int day) {
    showAppSheet(
      context: context,
      title: '$_month 月 $day 日',
      child: _DaySheet(year: _year, month: _month, day: day, keyMonth: _key),
    );
  }
}

/// 单日明细：自动活动（只读）+ 手动补记勾选 + 备注。
class _DaySheet extends ConsumerWidget {
  const _DaySheet({
    required this.year,
    required this.month,
    required this.day,
    required this.keyMonth,
  });

  final int year;
  final int month;
  final int day;
  final String keyMonth;

  String get _date => '$year-$month-$day';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(checkinMonthProvider(keyMonth));
    return async.when(
      loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
      data: (month) {
        final d = month.days[day];
        final manual = d?.manual;
        final auto = d?.types ?? {};
        final noteCtrl = TextEditingController(text: manual?.note ?? '');
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppTag(
                    label: (d?.checkedIn ?? false) ? '已打卡' : '未打卡',
                    color: (d?.checkedIn ?? false)
                        ? AppColors.primaryDeep
                        : AppColors.inkSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (auto.isNotEmpty) ...[
                Text('当天练习', style: AppText.caption),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: auto.map((t) {
                    final meta = typeMetaLookup(t);
                    return Chip(
                      avatar: Icon(meta.icon, size: 14, color: AppColors.primaryDeep),
                      label: Text(meta.label),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
              Text('补记今天的其它学习（App 外）', style: AppText.caption),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _manualTypes.map((t) {
                  final meta = typeMetaLookup(t);
                  final on = manual?.extraTypes.contains(t) ?? false;
                  return FilterChip(
                    selected: on,
                    avatar: Icon(meta.icon, size: 14),
                    label: Text(meta.label),
                    onSelected: (_) async {
                      await ref
                          .read(checkinRepositoryProvider)
                          .toggleType(_date, t);
                      ref.invalidate(checkinMonthProvider(keyMonth));
                      ref.invalidate(todayCheckinProvider);
                      ref.invalidate(homeDataProvider);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteCtrl,
                decoration: InputDecoration(
                  hintText: '给今天加点备注（可选）',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SecondaryButton(
                  label: '保存备注',
                  onPressed: () async {
                    await ref
                        .read(checkinRepositoryProvider)
                        .setNote(_date, noteCtrl.text.trim());
                    ref.invalidate(checkinMonthProvider(keyMonth));
                    ref.invalidate(todayCheckinProvider);
                    ref.invalidate(homeDataProvider);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

const List<String> _manualTypes = ['vocab', 'shadow', 'other'];

/// 仅用于日历明细页的图标/标签查找（与 checkin_card 的元数据保持一致）。
_TypeMeta typeMetaLookup(String type) {
  switch (type) {
    case 'spoken':
      return const _TypeMeta('口语', Icons.chat_bubble_outline_rounded, false);
    case 'quick':
      return const _TypeMeta('轻量', Icons.flash_on_rounded, false);
    case 'dictation':
      return const _TypeMeta('听写', Icons.graphic_eq_rounded, false);
    case 'vocab':
      return const _TypeMeta('背单词', Icons.menu_book_rounded, true);
    case 'shadow':
      return const _TypeMeta('影子跟读', Icons.record_voice_over_rounded, true);
    default:
      return const _TypeMeta('其它', Icons.more_horiz_rounded, true);
  }
}
