import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import 'metrics.dart';

/// 「我的」进步轨迹：近 4 周折线 + 每项可展开的口径说明。
///
/// 只呈现事实趋势，不给总分、等级、目标线或任何游戏化元素；
/// 样本不足的点留空，不用 0 分伪造趋势。
class TrendSection extends ConsumerWidget {
  const TrendSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(trendsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: '进步轨迹'),
        const SizedBox(height: 8),
        async.when(
          loading: () => const SizedBox(
            height: 40,
            child: LinearProgressIndicator(minHeight: 3),
          ),
          error: (error, _) => ErrorBanner(
            message: '读取本地练习记录失败：$error',
            onRetry: () => ref.invalidate(trendsProvider),
          ),
          data: (series) {
            // 至少要能连出一段线（两个周点）才展示卡片；单点与 0% 都不是趋势。
            if (!canDrawTrend(series)) {
              return AppCard(
                child: EmptyState(
                  icon: Icons.show_chart_rounded,
                  title: '再练几周就能看到趋势',
                  message: '这里只统计已完成的练习。每周至少 2 次、积累两周后，'
                      '才会显示提示使用率和改法复现率的变化。',
                ),
              );
            }
            return Column(
              children: [
                for (final item in series) ...[
                  _TrendCard(series: item),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.series});

  final TrendSeries series;

  @override
  Widget build(BuildContext context) {
    final latest = series.points.isEmpty ? null : series.points.last.value;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(series.title, style: AppText.cardTitle)),
              Text(
                latest == null
                    ? '本周样本不足'
                    : '本周 ${(latest * 100).round()}%',
                style: AppText.caption,
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 88,
            width: double.infinity,
            child: CustomPaint(painter: _TrendPainter(series.points)),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final point in series.points)
                Text(
                  '${point.weekStart.month}/${point.weekStart.day}',
                  style: AppText.caption,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 4),
              title: const Text('怎么算的', style: AppText.caption),
              children: [
                Text(
                  series.explain,
                  style: AppText.caption.copyWith(height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter(this.points);

  final List<TrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      baseline,
    );
    if (points.isEmpty) return;
    final left = 12.0;
    final usable = size.width - left * 2;
    final xs = List<double>.generate(
      points.length,
      (index) => points.length == 1
          ? left + usable / 2
          : left + usable * index / (points.length - 1),
    );
    final dots = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final value = points[i].value;
      if (value == null) continue;
      dots.add(Offset(xs[i], size.height - 12 - (size.height - 24) * value));
    }
    if (dots.length >= 2) {
      final path = Path()..moveTo(dots.first.dx, dots.first.dy);
      for (final dot in dots.skip(1)) {
        path.lineTo(dot.dx, dot.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.primary
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
    for (final dot in dots) {
      canvas.drawCircle(dot, 3.5, Paint()..color = AppColors.primary);
    }
  }

  @override
  bool shouldRepaint(_TrendPainter oldDelegate) => oldDelegate.points != points;
}
