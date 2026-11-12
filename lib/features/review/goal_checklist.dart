import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import '../../domain/models/models.dart';
import '../scenario/scenario_goals.dart';

/// 复盘里的「本场目标」自评卡。
///
/// 通关条件绑定沟通目标、不绑定分数；勾选结果写回 `session.review_json`
/// 的 `goalResults`，不改表结构、不需要模型再次请求。
class GoalChecklistCard extends ConsumerStatefulWidget {
  const GoalChecklistCard({
    super.key,
    required this.session,
    required this.result,
    required this.scenario,
  });

  final SessionRecord session;
  final ReviewResult result;
  final Scenario scenario;

  @override
  ConsumerState<GoalChecklistCard> createState() => _GoalChecklistCardState();
}

class _GoalChecklistCardState extends ConsumerState<GoalChecklistCard> {
  late List<String> _goals;
  late List<bool> _done;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _goals = scenarioGoals(widget.scenario);
    _done = List<bool>.generate(
      _goals.length,
      (index) => index < widget.result.goalResults.length &&
          widget.result.goalResults[index] == 'done',
      growable: false,
    );
  }

  Future<void> _toggle(int index) async {
    if (_saving) return;
    setState(() {
      _done[index] = !_done[index];
      _saving = true;
    });
    final updated = ReviewResult(
      highlight: widget.result.highlight,
      corrections: widget.result.corrections,
      phrases: widget.result.phrases,
      nextTip: widget.result.nextTip,
      promptCount: widget.result.promptCount,
      degraded: widget.result.degraded,
      takeawayText: widget.result.takeawayText,
      goalResults:
          _done.map((done) => done ? 'done' : 'todo').toList(),
    );
    try {
      await ref.read(sessionRepositoryProvider).saveSession(
            widget.session.copyWith(reviewJson: updated.encode()),
          );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final achieved = _done.where((done) => done).length;
    final pending = _done.where((done) => !done).length;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('本场目标', style: AppText.cardTitle),
              const Spacer(),
              Text('已达成 $achieved/${_goals.length}',
                  style: AppText.caption),
            ],
          ),
          const SizedBox(height: 6),
          Text('觉得办到了就勾上，没办到的下次再练一遍。',
              style: AppText.caption),
          const SizedBox(height: 10),
          for (var index = 0; index < _goals.length; index++)
            InkWell(
              onTap: () => _toggle(index),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _done[index]
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 18,
                      color: _done[index]
                          ? AppColors.success
                          : AppColors.inkMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _goals[index],
                        style: AppText.bodySecondary.copyWith(
                          height: 1.5,
                          color: _done[index]
                              ? AppColors.inkSecondary
                              : AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (pending > 0) ...[
            const SizedBox(height: 8),
            SecondaryButton(
              label: '还有 $pending 条待练 · 再练一次',
              icon: Icons.replay_rounded,
              onPressed: () => context.push('/scenario/${widget.scenario.id}'),
            ),
          ],
        ],
      ),
    );
  }
}
