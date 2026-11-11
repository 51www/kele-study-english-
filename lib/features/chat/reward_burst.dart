import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_text.dart';

/// 用户完成一次回答后的轻量正向反馈：小烟花 + 一句鼓励。
///
/// - 纯 CustomPainter 粒子，不引入动画依赖、不加载资源；
/// - 只占消息区右下角一小块，不拦截任何点击；
/// - [trigger] 每 +1 重放一次（由页面按「新增用户消息」驱动，
///   不会被每秒刷新的计时器反复触发）。
class RewardBurst extends StatefulWidget {
  const RewardBurst({
    super.key,
    required this.trigger,
    this.label = '说得不错',
  });

  final int trigger;
  final String label;

  @override
  State<RewardBurst> createState() => _RewardBurstState();
}

class _RewardBurstState extends State<RewardBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  late final List<_Particle> _particles = _buildParticles();

  @override
  void initState() {
    super.initState();
    if (widget.trigger > 0) unawaitedForward();
  }

  void unawaitedForward() {
    _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant RewardBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger > 0) {
      unawaitedForward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Particle> _buildParticles() {
    final random = math.Random(7);
    final palette = <Color>[
      AppColors.primary,
      AppColors.primaryLight,
      AppColors.yellow,
      AppColors.mint,
    ];
    return List<_Particle>.generate(20, (index) {
      final angle = (index / 20) * math.pi * 2 + random.nextDouble() * 0.28;
      return _Particle(
        angle: angle,
        distance: 34 + random.nextDouble() * 48,
        radius: 2.2 + random.nextDouble() * 2.6,
        color: palette[index % palette.length],
        delay: random.nextDouble() * 0.12,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isDismissed) return const SizedBox.shrink();
          final t = _controller.value;
          return SizedBox(
            width: 190,
            height: 150,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CustomPaint(
                  painter: _BurstPainter(progress: t, particles: _particles),
                  size: const Size(190, 150),
                ),
                Positioned(
                  right: 6,
                  bottom: 34,
                  child: Opacity(
                    opacity: _badgeOpacity(t),
                    child: Transform.scale(
                      scale: _badgeScale(t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          boxShadow: AppShadows.soft,
                          border: Border.all(color: AppColors.primaryTint),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 13,
                              color: AppColors.primaryDeep,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              widget.label,
                              style: AppText.caption.copyWith(
                                fontSize: 10,
                                color: AppColors.primaryDeep,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  double _badgeOpacity(double t) {
    if (t < 0.08) return t / 0.08;
    if (t > 0.72) return (1 - t) / 0.28;
    return 1;
  }

  double _badgeScale(double t) => 0.78 + 0.22 * Curves.easeOut.transform(
        (t / 0.3).clamp(0.0, 1.0),
      );
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.distance,
    required this.radius,
    required this.color,
    required this.delay,
  });

  final double angle;
  final double distance;
  final double radius;
  final Color color;
  final double delay;
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter({required this.progress, required this.particles});

  final double progress;
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width * 0.68, size.height * 0.72);
    // 中心光晕：前 35% 出现后淡出，避免粒子消失得太突然。
    final halo = (1 - (progress / 0.45).clamp(0.0, 1.0)) * 0.20;
    if (halo > 0) {
      canvas.drawCircle(
        origin,
        12 + progress * 42,
        Paint()..color = AppColors.primary.withValues(alpha: halo),
      );
    }
    for (final particle in particles) {
      final local = ((progress - particle.delay) / (1 - particle.delay))
          .clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      final eased = Curves.easeOutCubic.transform(local);
      final alpha = (1 - Curves.easeIn.transform(local)).clamp(0.0, 1.0);
      final dx = math.cos(particle.angle) * particle.distance * eased;
      // 轻微重力感：后段向下多落一点。
      final dy = math.sin(particle.angle) * particle.distance * eased +
          local * local * 12;
      final center = origin + Offset(dx, dy);
      canvas.drawCircle(
        center,
        particle.radius * (1 - local * 0.45),
        Paint()..color = particle.color.withValues(alpha: alpha * 0.9),
      );
      if (particle.radius > 3.4) {
        canvas.drawLine(
          center - Offset(0, 5 * eased),
          center,
          Paint()
            ..color = particle.color.withValues(alpha: alpha * 0.45)
            ..strokeWidth = 1.4
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.progress != progress;
}
