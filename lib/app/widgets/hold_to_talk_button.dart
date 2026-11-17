import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';
import '../theme/app_text.dart';

/// 外观沿用 `SecondaryButton`，交互改为「按住起录、松手定稿」。
///
/// 课前热身与今日复练共用，保证两处录音手感一致。
class HoldToTalkButton extends StatelessWidget {
  const HoldToTalkButton({
    super.key,
    required this.label,
    required this.active,
    required this.onDown,
    required this.onUp,
    required this.onCancel,
  });

  final String label;
  final bool active;
  final VoidCallback onDown;
  final Future<void> Function() onUp;
  final Future<void> Function() onCancel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => onDown(),
        onPointerUp: (_) => unawaited(onUp()),
        onPointerCancel: (_) => unawaited(onCancel()),
        child: SizedBox(
          width: double.infinity,
          height: AppLayout.buttonHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: active ? AppColors.primaryWash : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: active ? AppColors.primary : AppColors.primaryTint,
                width: 1.4,
              ),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppLayout.buttonHorizontalPadding,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        active ? Icons.stop_rounded : Icons.mic_rounded,
                        size: AppLayout.buttonIconSize,
                        color: AppColors.primaryDeep,
                      ),
                      const SizedBox(width: AppLayout.buttonIconGap),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.button.copyWith(
                          color: AppColors.primaryDeep,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
