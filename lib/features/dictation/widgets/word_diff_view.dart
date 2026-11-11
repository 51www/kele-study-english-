import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../domain/models/dictation_models.dart';

/// 逐词差异标签：正确 / 漏写 / 多写 / 拼错（UI 规范「二期听写新增组件规格」）。
class WordDiffView extends StatelessWidget {
  const WordDiffView({super.key, required this.diffs});

  final List<WordDiff> diffs;

  @override
  Widget build(BuildContext context) {
    if (diffs.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final diff in diffs) _Chip(diff: diff),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.diff});

  final WordDiff diff;

  @override
  Widget build(BuildContext context) {
    late final Color background;
    late final Color foreground;
    late final String label;
    switch (diff.kind) {
      case 'missing':
        background = AppColors.warning.withValues(alpha: 0.10);
        foreground = AppColors.warning;
        label = '＋ ${diff.word}';
        break;
      case 'extra':
        background = AppColors.error.withValues(alpha: 0.10);
        foreground = AppColors.error;
        label = '− ${diff.word}';
        break;
      case 'misspelled':
        background = AppColors.primaryTint;
        foreground = AppColors.primaryDeep;
        label = diff.word;
        break;
      default:
        background = AppColors.mint.withValues(alpha: 0.28);
        foreground = AppColors.success;
        label = diff.word;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label, style: AppText.tag.copyWith(color: foreground)),
        ),
        if (diff.detail != null) ...[
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(diff.detail!, style: AppText.caption.copyWith(fontSize: 10)),
          ),
        ],
      ],
    );
  }
}
