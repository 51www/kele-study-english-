import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_text.dart';
import 'path_model.dart';

/// 学习路径旅程地图（M16）：竖向蛇形节点路，替代表 4 点梯度条。
///
/// 视觉上学「方向感」，机制上不学闯关游戏：全节点可点、不锁定、不置灰、
/// 无锁图标、无分数；点条目进对应练习，点阶段头切换当前阶段。
class PathJourneyMap extends StatelessWidget {
  const PathJourneyMap({
    super.key,
    required this.stages,
    this.nextItemId,
    this.onItemTap,
    this.onStageTap,
  });

  final List<JourneyStage> stages;
  final String? nextItemId;
  final void Function(PathItem item)? onItemTap;
  final void Function(int stageIndex)? onStageTap;

  static const _headerGap = 84.0;
  static const _itemGap = 56.0;

  @override
  Widget build(BuildContext context) {
    if (stages.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final nodes = <_MapNode>[
          for (final stage in stages) ...[
            _MapNode.stage(stage: stage),
            for (final item in stage.items) _MapNode.item(item: item),
          ],
        ];
        // 蛇形摆位：位置是纯计算，不依赖手写坐标。
        var row = 0;
        var y = 24.0;
        final points = <Offset>[];
        for (final node in nodes) {
          final xFrac = 0.5 + 0.32 * math.sin(row * 0.9);
          points.add(Offset(width * xFrac, y));
          y += node.isStage ? _headerGap : _itemGap;
          row += 1;
        }
        return SizedBox(
          height: y + 8,
          width: double.infinity,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _JourneyPainter(
                    points: points,
                    levels: [for (final node in nodes) node.level(nextItemId)],
                  ),
                ),
              ),
              for (var i = 0; i < nodes.length; i++) ...[
                _nodeAt(nodes[i], points[i]),
                _labelAt(nodes[i], points[i], width),
              ],
            ],
          ),
        );
      },
    );
  }

  void _onTap(_MapNode node) {
    final stage = node.stage;
    if (stage != null) {
      onStageTap?.call(stage.stage.index);
      return;
    }
    final item = node.item;
    if (item == null) return;
    onItemTap?.call(item);
  }

  Widget _nodeAt(_MapNode node, Offset point) {
    final active = node.isActive(nextItemId);
    final size = node.isStage ? 44.0 : (active ? 38.0 : 34.0);
    final Color fill;
    final Color border;
    final double borderWidth;
    final IconData icon;
    final double iconSize;
    final Color iconColor;
    final bool glow;
    final stageNode = node.stage;
    if (stageNode != null) {
      final current = stageNode.current;
      fill = current ? AppColors.primaryTint : AppColors.surface;
      border = current ? AppColors.primaryDeep : AppColors.line;
      borderWidth = 2;
      icon = Icons.flag;
      iconSize = 20;
      iconColor = current ? AppColors.primaryDeep : AppColors.inkMuted;
      glow = current;
    } else {
      final item = node.item!;
      if (item.status == 'done') {
        fill = AppColors.primary;
        border = AppColors.primary;
        borderWidth = 0;
        icon = Icons.check;
        iconSize = 18;
        iconColor = AppColors.surface;
        glow = false;
      } else if (active) {
        fill = AppColors.primaryTint;
        border = AppColors.primaryDeep;
        borderWidth = 2;
        icon = _kindIcon(item.kind);
        iconSize = 17;
        iconColor = AppColors.primaryDeep;
        glow = true;
      } else if (item.status == 'consolidating') {
        fill = AppColors.surface;
        border = AppColors.warning;
        borderWidth = 2;
        icon = Icons.refresh;
        iconSize = 15;
        iconColor = AppColors.warning;
        glow = false;
      } else if (item.status == 'skipped') {
        fill = AppColors.surface;
        border = AppColors.line;
        borderWidth = 2;
        icon = Icons.fast_forward;
        iconSize = 15;
        iconColor = AppColors.inkMuted;
        glow = false;
      } else {
        fill = AppColors.surface;
        border = AppColors.line;
        borderWidth = 2;
        icon = _kindIcon(item.kind);
        iconSize = 15;
        iconColor = AppColors.inkMuted;
        glow = false;
      }
    }
    return Positioned(
      left: point.dx - size / 2,
      top: point.dy - size / 2,
      width: size,
      height: size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTap(node),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill,
            border: borderWidth == 0
                ? null
                : Border.all(color: border, width: borderWidth),
            boxShadow: glow ? AppShadows.primary : null,
          ),
          child: Icon(icon, size: iconSize, color: iconColor),
        ),
      ),
    );
  }

  Widget _labelAt(_MapNode node, Offset point, double width) {
    final labelWidth = (width * 0.42).clamp(110.0, 160.0);
    final toRight = point.dx < width * 0.5;
    final left = toRight ? point.dx + 26 : point.dx - 26 - labelWidth;
    final String text;
    final TextStyle style;
    final stageNode = node.stage;
    if (stageNode != null) {
      text = '${stageNode.stage.index} · ${stageNode.stage.name}'
          '（${stageNode.doneCount}/${stageNode.items.length}）';
      style = AppText.caption.copyWith(
        fontSize: 12,
        fontWeight: stageNode.current ? FontWeight.w600 : FontWeight.w500,
        color: stageNode.current ? AppColors.ink : AppColors.inkSecondary,
      );
    } else {
      text = node.item!.title;
      style = AppText.caption.copyWith(
        fontSize: 12,
        fontWeight: node.isActive(nextItemId) ? FontWeight.w600 : FontWeight.w500,
        color: node.item!.status == 'done' ? AppColors.inkSecondary : AppColors.ink,
      );
    }
    return Positioned(
      left: left,
      top: point.dy - 11,
      width: labelWidth,
      height: 22,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTap(node),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: toRight ? TextAlign.left : TextAlign.right,
          style: style,
        ),
      ),
    );
  }
}

class _MapNode {
  const _MapNode._({required this.stage, required this.item});

  factory _MapNode.stage({required JourneyStage stage}) =>
      _MapNode._(stage: stage, item: null);

  factory _MapNode.item({required PathItem item}) =>
      _MapNode._(stage: null, item: item);

  final JourneyStage? stage;
  final PathItem? item;

  bool get isStage => stage != null;

  bool isActive(String? nextItemId) =>
      !isStage && item != null && item!.id == nextItemId;

  /// 路径分段配色用：2 = 已完成，1 = 走到 / 正在走，0 = 未到。
  int level(String? nextItemId) {
    if (isStage) {
      final s = stage!;
      if (s.items.isNotEmpty && s.doneCount >= s.items.length) return 2;
      return s.current ? 1 : 0;
    }
    final it = item!;
    if (it.status == 'done') return 2;
    if (isActive(nextItemId) || it.status == 'consolidating') return 1;
    return 0;
  }
}

/// 蛇形曲线：相邻节点用三次贝塞尔连接；分段颜色只用既有 Token。
class _JourneyPainter extends CustomPainter {
  _JourneyPainter({required this.points, required this.levels});

  final List<Offset> points;
  final List<int> levels;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final midY = (a.dy + b.dy) / 2;
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx, midY, b.dx, midY, b.dx, b.dy);
      final level = math.min(levels[i], levels[i + 1]);
      paint.color = level >= 2
          ? AppColors.primary
          : level == 1
              ? AppColors.primaryTint
              : AppColors.line;
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_JourneyPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.levels != levels;
}

IconData _kindIcon(String kind) {
  switch (kind) {
    case 'review':
      return Icons.refresh;
    case 'quick':
      return Icons.timer_outlined;
    case 'material':
      return Icons.headset;
    case 'wrong':
      return Icons.edit;
    default:
      return Icons.chat_bubble_outline;
  }
}
