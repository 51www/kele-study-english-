import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';

class PhrasebookPage extends ConsumerWidget {
  const PhrasebookPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('表达本', style: AppText.h1),
              const SizedBox(height: 4),
              Text('把想说的句子攒起来', style: AppText.bodySecondary),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Expanded(
          child: EmptyState(
            icon: Icons.bookmark_border_rounded,
            title: '表达本还是空的',
            message: '复盘时把好用的句子收藏到这里，下次开口就能用上。',
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
          child: SecondaryButton(
            label: '查看练习记录',
            icon: Icons.history_rounded,
            onPressed: () => context.go('/history'),
          ),
        ),
      ],
    );
  }
}
