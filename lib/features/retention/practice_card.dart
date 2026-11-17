import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import '../../app/widgets/hold_to_talk_button.dart';
import '../../domain/models/models.dart';
import '../dictation/scoring/dictation_scorer.dart';
import 'review_item.dart';

/// 「今日一条」90 秒开口练习卡。
///
/// 判分复用二期的离线词级 diff，不调用模型；按住麦克风松手即识别，
/// 识别结果回填到两行输入框，可回听原声，也可直接键盘输入。
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
  ScoringResult? _result;

  // 按住说话：按下即起录，松手即定稿，与课前热身保持一致。
  bool _asrReady = false;
  bool _micPressed = false;
  bool _micCancelled = false;
  bool _listening = false;
  bool _stopping = false;
  Future<void>? _starting;
  DateTime? _pressStartedAt;
  Timer? _maxTimer;
  String? _audioPath;
  bool _playingRecording = false;

  @override
  void initState() {
    super.initState();
    // 提前准备识别引擎，按下按钮就能立刻起录，避免漏掉开头半句。
    unawaited(_prewarmAsr());
  }

  @override
  void dispose() {
    _maxTimer?.cancel();
    if (_listening || _starting != null) {
      unawaited(ref.read(asrRouterProvider).cancel());
    }
    if (_playingRecording) unawaited(ref.read(audioPlayerProvider).stop());
    _input.dispose();
    super.dispose();
  }

  Future<void> _prewarmAsr() async {
    try {
      _asrReady = await ref.read(asrRouterProvider).initialize();
    } on Object {
      _asrReady = false;
    }
  }

  Future<double> _threshold() async {
    final raw = await ref
        .read(localStoreProvider)
        .setting(SettingsKeys.reviewSpeakPassThreshold);
    final percent = int.tryParse(raw ?? '80') ?? 80;
    return (percent / 100).clamp(0.0, 1.0);
  }

  /// 按下麦克风：立即起录。引擎已在进卡时预热，这里只做启动。
  void _micDown() {
    if (_starting != null || _listening || _stopping) return;
    _micCancelled = false;
    _pressStartedAt = DateTime.now();
    if (_playingRecording) {
      unawaited(ref.read(audioPlayerProvider).stop());
      _playingRecording = false;
    }
    setState(() => _micPressed = true);
    _starting = _beginListening();
  }

  Future<void> _beginListening() async {
    final engine = ref.read(asrRouterProvider);
    if (!_asrReady) await _prewarmAsr();
    if (!mounted) {
      await engine.cancel();
      return;
    }
    if (!_asrReady) {
      if (mounted) {
        showAppToast(context, '这台设备没有可用的语音识别，直接用键盘写就行', error: true);
      }
      _pressStartedAt = null;
      return;
    }
    try {
      await engine.start();
      if (!mounted || _micCancelled) {
        await engine.cancel();
        return;
      }
      setState(() => _listening = true);
      _maxTimer?.cancel();
      _maxTimer = Timer(const Duration(seconds: 30), () {
        if (_listening) unawaited(_finishListening());
      });
    } on Object {
      if (mounted) {
        showAppToast(context, '没能开始识别，直接用键盘写吧', error: true);
      }
    }
  }

  /// 松开麦克风：短按视为误触，正常按住则结束录音并填入识别文本。
  Future<void> _micUp() async {
    if (!_micPressed) return;
    setState(() => _micPressed = false);
    final startedAt = _pressStartedAt;
    _pressStartedAt = null;
    final starting = _starting;
    if (starting != null) {
      await starting;
      _starting = null;
    }
    if (!mounted || !_listening || _stopping) return;
    final heldMs = startedAt == null
        ? 0
        : DateTime.now().difference(startedAt).inMilliseconds;
    if (heldMs < 400) {
      await _cancelListening();
      return;
    }
    await _finishListening();
  }

  Future<void> _cancelListening() async {
    _micCancelled = true;
    _listening = false;
    _micPressed = false;
    _starting = null;
    _pressStartedAt = null;
    _maxTimer?.cancel();
    await ref.read(asrRouterProvider).cancel();
    if (mounted) setState(() {});
  }

  /// 松手即完成：停止录音，一次性取回整段识别结果，并留下可回放的原声。
  Future<void> _finishListening() async {
    if (_stopping) return;
    _stopping = true;
    _listening = false;
    _micPressed = false;
    _starting = null;
    _maxTimer?.cancel();
    if (mounted) setState(() {});
    final engine = ref.read(asrRouterProvider);
    try {
      final text = await engine.stop();
      if (!mounted) return;
      if (text.isNotEmpty) {
        final current = _input.text.trim();
        _input.text = current.isEmpty ? text : '$current $text';
        final path = engine.lastAudioPath;
        if (path != null && path.isNotEmpty) _audioPath = path;
        _result = null;
      } else {
        showAppToast(context, '没听清，直接用键盘接着写就行', error: true);
      }
    } on Object {
      if (mounted) {
        showAppToast(context, '识别失败，输入内容还在，改用键盘吧', error: true);
      }
    } finally {
      _stopping = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _playRecording() async {
    final path = _audioPath;
    if (path == null || path.isEmpty) return;
    final player = ref.read(audioPlayerProvider);
    if (_playingRecording) {
      await player.stop();
      if (mounted) setState(() => _playingRecording = false);
      return;
    }
    if (mounted) setState(() => _playingRecording = true);
    try {
      await ref.read(audioSessionProvider).preparePlayback();
      await player.playPath(path);
    } on Object {
      if (mounted) {
        showAppToast(context, '原声回放不可用，识别文字仍然保留', error: true);
      }
    } finally {
      if (mounted) setState(() => _playingRecording = false);
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
              const SizedBox(width: AppSpacing.element),
              const Text('今日一条 · 90 秒', style: AppText.cardTitle),
              const Spacer(),
              Text('待复练', style: AppText.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.buttonGap),
          Text('把这句更自然的说法，开口说一遍：', style: AppText.bodySecondary),
          const SizedBox(height: AppSpacing.element),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.cardInner),
            decoration: BoxDecoration(
              color: AppColors.primaryWash,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(item.textEn, style: AppText.body),
          ),
          if (item.textZh != null && item.textZh!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.element),
            Text(item.textZh!, style: AppText.bodySecondary),
          ],
          const SizedBox(height: AppSpacing.buttonGap),
          Text(
            '判分规则：忽略大小写与标点，漏词会标出来；答对进入下一档复练，答错明天再来。',
            style: AppText.caption,
          ),
          const SizedBox(height: AppSpacing.buttonGap),
          AppTextField(
            controller: _input,
            hint: '说出或写出这句英文',
            minLines: 2,
            maxLines: 2,
          ),
          if (_audioPath != null) ...[
            const SizedBox(height: AppSpacing.buttonGap),
            SecondaryButton(
              label: _playingRecording ? '停止回放' : '播放我的声音',
              icon: _playingRecording ? Icons.stop_rounded : Icons.play_arrow_rounded,
              onPressed: _playRecording,
            ),
          ],
          const SizedBox(height: AppSpacing.buttonGap),
          HoldToTalkButton(
            label: _stopping
                ? '识别中…'
                : (_listening
                      ? '松手完成'
                      : (_micPressed ? '正在准备…' : '按住说一遍')),
            active: _listening || _stopping,
            onDown: _micDown,
            onUp: _micUp,
            onCancel: _cancelListening,
          ),
          const SizedBox(height: AppSpacing.buttonGap),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: result == null ? '提交这一遍' : '再说一遍',
              onPressed: () async {
                if (result != null) {
                  if (_playingRecording) {
                    unawaited(ref.read(audioPlayerProvider).stop());
                  }
                  setState(() {
                    _result = null;
                    _input.clear();
                    _audioPath = null;
                    _playingRecording = false;
                  });
                } else {
                  await _submit();
                }
              },
            ),
          ),
          if (result != null) ...[
            const SizedBox(height: AppSpacing.buttonGap),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.buttonGap),
              decoration: BoxDecoration(
                color: result.passed
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.warning.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.sm),
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
