import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_text.dart';
import '../../domain/models/models.dart';
import 'conversation_controller.dart';

/// 用户回答句下方的三枚简洁图标：优化句子 / 播放原声 / 播放 TTS 朗读。
///
/// 放在气泡外侧、右对齐，不用文字标签，保证对话区依然清爽；
/// 没有录音时「原声」置灰，但仍可点，给出明确原因而不是静默无反应。
class AnswerActionBar extends StatelessWidget {
  const AnswerActionBar({
    super.key,
    required this.message,
    required this.optimizing,
    required this.optimizationOpen,
    required this.hasOriginal,
    required this.originalPlaying,
    required this.ttsPlaying,
    required this.onOptimize,
    required this.onPlayOriginal,
    required this.onPlayTts,
  });

  final MessageRecord message;
  final bool optimizing;
  final bool optimizationOpen;
  final bool hasOriginal;
  final bool originalPlaying;
  final bool ttsPlaying;
  final VoidCallback onOptimize;
  final VoidCallback onPlayOriginal;
  final VoidCallback onPlayTts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionIcon(
            icon: Icons.auto_fix_high_rounded,
            semanticLabel: '优化这句话',
            tooltip: '优化句子',
            active: optimizationOpen || optimizing,
            busy: optimizing,
            onTap: onOptimize,
          ),
          const SizedBox(width: 6),
          _ActionIcon(
            icon: originalPlaying ? Icons.stop_rounded : Icons.mic_rounded,
            semanticLabel: originalPlaying ? '停止播放原声' : '播放我的原声',
            tooltip: hasOriginal ? '播放我的原声' : '这句没有录到原声',
            active: originalPlaying,
            dimmed: !hasOriginal,
            onTap: onPlayOriginal,
          ),
          const SizedBox(width: 6),
          _ActionIcon(
            icon: ttsPlaying ? Icons.stop_rounded : Icons.volume_up_rounded,
            semanticLabel: ttsPlaying ? '停止朗读' : 'TTS 朗读这句',
            tooltip: 'TTS 朗读',
            active: ttsPlaying,
            onTap: onPlayTts,
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.semanticLabel,
    required this.tooltip,
    required this.onTap,
    this.active = false,
    this.dimmed = false,
    this.busy = false,
  });

  final IconData icon;
  final String semanticLabel;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;
  final bool dimmed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? AppColors.primaryDeep
        : dimmed
            ? AppColors.inkMuted.withValues(alpha: 0.55)
            : AppColors.inkSecondary;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: active ? AppColors.primaryWash : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: active ? AppColors.primaryTint : AppColors.divider),
            ),
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(7),
                    child: CircularProgressIndicator(
                      strokeWidth: 1.6,
                      color: AppColors.primaryDeep,
                    ),
                  )
                : Icon(icon, size: 14, color: color),
          ),
        ),
      ),
    );
  }
}

/// 「优化句子」结果：页面内展开，不弹窗、不自动发送、不改写原句。
class ImprovementCard extends StatelessWidget {
  const ImprovementCard({
    super.key,
    required this.original,
    required this.improvement,
    required this.error,
    required this.playing,
    required this.onPlay,
    required this.onSave,
    required this.onClose,
    required this.onRetry,
  });

  final String original;
  final SentenceImprovement? improvement;
  final String? error;
  final bool playing;
  final VoidCallback onPlay;
  final VoidCallback onSave;
  final VoidCallback onClose;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6, right: 4),
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.primaryWash,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.primaryTint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 13, color: AppColors.primaryDeep),
              const SizedBox(width: 5),
              Text(
                '更自然的说法',
                style: AppText.tag.copyWith(color: AppColors.primaryDeep),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close_rounded, size: 15, color: AppColors.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: 7),
          if (error != null) ...[
            Text(error!, style: AppText.caption.copyWith(color: AppColors.error)),
            const SizedBox(height: 6),
            _MiniPill(label: '重试', icon: Icons.refresh_rounded, onTap: onRetry),
          ] else if (improvement == null) ...[
            Row(
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.8, color: AppColors.primary),
                ),
                const SizedBox(width: 7),
                Text('正在想一个更自然的说法…', style: AppText.caption),
              ],
            ),
          ] else ...[
            Text(
              original,
              style: AppText.caption.copyWith(
                decoration: TextDecoration.lineThrough,
                color: AppColors.inkMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              improvement!.improved,
              style: AppText.body.copyWith(color: AppColors.ink, height: 1.5),
            ),
            if (improvement!.reasonZh.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(improvement!.reasonZh, style: AppText.caption.copyWith(height: 1.5)),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                _MiniPill(
                  label: playing ? '停止' : '试听',
                  icon: playing ? Icons.stop_rounded : Icons.volume_up_rounded,
                  onTap: onPlay,
                ),
                const SizedBox(width: 8),
                _MiniPill(
                  label: '存入表达本',
                  icon: Icons.bookmark_add_outlined,
                  onTap: onSave,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.primaryDeep),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppText.caption.copyWith(fontSize: 10, color: AppColors.primaryDeep),
            ),
          ],
        ),
      ),
    );
  }
}
