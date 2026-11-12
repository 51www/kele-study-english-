import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import '../../domain/models/models.dart';
import '../dictation/scoring/dictation_scorer.dart';
import 'review_item.dart';

/// 「今日一条」90 秒开口练习卡。
///
/// 判分复用二期的离线词级 diff，不调用模型；ASR 失败可直接切键盘。
/// 结果写回待复练队列，答对顺延、答错缩短间隔。
class TakeawayPracticeCard extends ConsumerStatefulWidget {
  const TakeawayPracticeCard({
    super.key,
    required this.item,
    this.onCompleted,
  });

  final ReviewItem item;
  final ValueChanged<bool>? onCompleted;

  @override
  ConsumerState<TakeawayPracticeCard> createState() => _TakeawayPracticeCardState();
}

class _TakeawayPracticeCardState extends ConsumerState<TakeawayPracticeCard> {
  final TextEditingController _input = TextEditingController();
  bool _listening = false;
  bool _keyboard = false;
  ScoringResult? _result;

  @override
  void dispose() {
    _input.dispose();
    if (_listening) ref.read(asrEngineProvider).cancel();
    super.dispose();
  }

  Future<double> _threshold() async {
    final raw = await ref
        .read(localStoreProvider)
        .setting(SettingsKeys.reviewSpeakPassThreshold);
    final percent = int.tryParse(raw ?? '80') ?? 80;
    return (percent / 100).clamp(0.0, 1.0);
  }

  Future<void> _toggleMic() async {
    final engine = ref.read(asrEngineProvider);
    if (_listening) {
      try {
        final text = await engine.stop();
        if (text.isNotEmpty) {
          final current = _input.text.trim();
          _input.text = current.isEmpty ? text : '$current $text';
        } else if (mounted) {
          showAppToast(context, '没听清，直接用键盘接着写就行', error: true);
        }
      } on Object {
        if (mounted) {
          showAppToast(context, '识别失败，输入内容还在，改用键盘吧', error: true);
        }
      }
      if (mounted) setState(() => _listening = false);
      return;
    }
    final available = await engine.initialize();
    if (!available) {
      if (mounted) {
        showAppToast(context, '这台设备没有可用的语音识别，直接用键盘写就行', error: true);
        setState(() => _keyboard = true);
      }
      return;
    }
    try {
      await engine.start();
      if (mounted) setState(() => _listening = true);
    } on Object {
      if (mounted) {
        showAppToast(context, '没能开始识别，改用键盘写吧', error: true);
        setState(() => _keyboard = true);
      }
    }
  }

  Future<void> _submit() async {
    final answer = _input.text.trim();
    if (answer.isEmpty) {
      showAppToast(context, '先说一遍或把句子写出来', error: true);
      return;
    }
    final options = ScoringOptions(passThreshold: await _threshold());
    final scoring = DictationScorer.score(
      widget.item.textEn,
      answer,
      options: options,
    );
    final updated = ReviewScheduler.applyResult(
      widget.item,
      passed: scoring.passed,
      nowMs: DateTime.now().millisecondsSinceEpoch,
    );
    await ref.read(localStoreProvider).upsertReviewItem(updated);
    // 先把结果交给页面，刷新 provider 后练习卡可能立刻被卸载。
    widget.onCompleted?.call(scoring.passed);
    if (mounted) setState(() => _result = scoring);
    ref.invalidate(reviewItemsProvider);
    ref.invalidate(dueReviewItemsProvider);
    ref.invalidate(todayPlanProvider);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final result = _result;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('今日一条 · 90 秒', style: AppText.cardTitle),
              const Spacer(),
              Text('待复练', style: AppText.caption),
            ],
          ),
          const SizedBox(height: 12),
          Text('把这句更自然的说法，开口说一遍：', style: AppText.bodySecondary),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryWash,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(item.textEn, style: AppText.body),
          ),
          if (item.textZh != null && item.textZh!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(item.textZh!, style: AppText.bodySecondary),
          ],
          const SizedBox(height: 12),
          Text(
            '判分规则：忽略大小写与标点，漏词会标出来；答对进入下一档复练，答错明天再来。',
            style: AppText.caption,
          ),
          const SizedBox(height: 12),
          if (_keyboard || _listening)
            TextField(
              controller: _input,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '说出或写出这句英文',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          if (_keyboard || _listening) const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: _listening ? '说完了' : '按麦说一遍',
                  icon: _listening ? Icons.stop_rounded : Icons.mic_rounded,
                  onPressed: _toggleMic,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SecondaryButton(
                  label: _keyboard ? '隐藏键盘' : '改用键盘',
                  icon: Icons.keyboard_rounded,
                  onPressed: () => setState(() => _keyboard = !_keyboard),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: result == null ? '提交这一遍' : '再说一遍',
              onPressed: () async {
                if (result != null) {
                  setState(() {
                    _result = null;
                    _input.clear();
                  });
                } else {
                  await _submit();
                }
              },
            ),
          ),
          if (result != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: result.passed
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.warning.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.passed ? '已过 · 下次复练顺延' : '还没说全 · 明天再来一次',
                    style: AppText.cardTitle,
                  ),
                  const SizedBox(height: 4),
                  Text('${result.accuracyLabel} · ${result.explanation}',
                      style: AppText.bodySecondary),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
