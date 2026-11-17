import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import '../../app/widgets/hold_to_talk_button.dart';
import '../../domain/models/models.dart';
import '../../services/tts/tts_speech.dart';

/// 3 分钟轻量练习：1 条待复练 + 3 句接话 + 1 条重点，全程离线。
///
/// 跟读支持朗读、按住说话松手识别、回听原声，也可直接键盘输入；
/// 判分沿用关键词过半的弱判定，不打分。
/// 会话写回 `session` 表并用 `model_name = quick-3min` 标记（零改表）；
/// 计入今日分钟，但不计入需求 §3.2 的「每周 ≥3 次、每次 ≥8 分钟」有效次数。
class QuickPracticePage extends ConsumerStatefulWidget {
  const QuickPracticePage({super.key});

  @override
  ConsumerState<QuickPracticePage> createState() => _QuickPracticePageState();
}

class _QuickPracticePageState extends ConsumerState<QuickPracticePage> {
  final TextEditingController _input = TextEditingController();
  int _step = 0;
  int _phraseIndex = 0;
  bool? _lastOk;
  bool _loading = true;
  bool _finished = false;
  String _takeaway = '';
  String? _scenarioId;
  List<String> _phrases = <String>[];
  bool _speaking = false;

  // 按住说话：按下即起录，松手即定稿，与课前热身、今日复练保持一致。
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
    _load();
    // 提前准备识别引擎，按下按钮就能立刻起录，避免漏掉开头。
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

  Future<void> _load() async {
    final due = await ref.read(dueReviewItemsProvider.future);
    final home = await ref.read(homeDataProvider.future);
    final scenario = home.scenarios.firstOrNull;
    final phrases = (scenario?.targetPhrases ?? const <String>[])
        .where((e) => e.trim().isNotEmpty)
        .take(3)
        .toList();
    if (!mounted) return;
    setState(() {
      _scenarioId = scenario?.id;
      _phrases = phrases;
      _takeaway = due.firstOrNull?.textEn.trim().isNotEmpty == true
          ? due.first.textEn.trim()
          : (phrases.firstOrNull ?? 'Take your time and speak clearly.');
      _loading = false;
    });
  }

  Future<void> _prewarmAsr() async {
    try {
      _asrReady = await ref.read(asrRouterProvider).initialize();
    } on Object {
      _asrReady = false;
    }
  }

  Future<void> _speak() async {
    final sentence = _currentSentence;
    if (sentence.isEmpty || _speaking || _listening) return;
    setState(() => _speaking = true);
    try {
      final settings = ref.read(settingsRepositoryProvider);
      await ref.read(ttsRouterProvider).speak(
            sentence,
            voice: settings.getString(
              SettingsKeys.ttsVoice,
              'en-US-AriaNeural',
            ),
            rate: settings.getDouble(SettingsKeys.ttsRate, fallback: 1.0),
            style: ttsSpeechStyleFrom(
              settings.getString(SettingsKeys.ttsStyle, 'none'),
            ),
            preferEdge:
                settings.getString(SettingsKeys.ttsEngine, 'edge') != 'system',
          );
    } on Object {
      if (mounted) {
        showAppToast(context, '朗读暂不可用，看着文字也能练', error: true);
      }
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  void _resetVoice() {
    _maxTimer?.cancel();
    unawaited(ref.read(ttsRouterProvider).stop());
    if (_playingRecording) unawaited(ref.read(audioPlayerProvider).stop());
    if (_listening || _starting != null) {
      unawaited(ref.read(asrRouterProvider).cancel());
    }
    _listening = false;
    _stopping = false;
    _micPressed = false;
    _micCancelled = true;
    _starting = null;
    _pressStartedAt = null;
    _audioPath = null;
    _playingRecording = false;
    _speaking = false;
  }

  /// 按下麦克风：立即起录。引擎已在进页时预热，这里只做启动。
  void _micDown() {
    if (_starting != null || _listening || _stopping) return;
    _micCancelled = false;
    _pressStartedAt = DateTime.now();
    unawaited(ref.read(ttsRouterProvider).stop());
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
  /// 识别文字直接覆盖输入框（不追加），多次重录只保留最新一次结果；识别为空或失败时保留原内容。
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
        _input.text = text;
        final path = engine.lastAudioPath;
        if (path != null && path.isNotEmpty) _audioPath = path;
        _lastOk = null;
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

  List<String> _keywords(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.length > 2)
      .toList();

  bool _saidIt(String target, String answer) {
    final words = _keywords(target);
    final spoken = answer.toLowerCase();
    if (words.isEmpty) return answer.trim().isNotEmpty;
    final hits = words.where((word) => spoken.contains(word)).length;
    return hits >= (words.length / 2).ceil();
  }

  String get _currentSentence {
    if (_step == 0) return _takeaway;
    if (_step == 1 && _phraseIndex < _phrases.length) {
      return _phrases[_phraseIndex];
    }
    return _takeaway;
  }

  void _advance() {
    _resetVoice();
    if (_step == 0) {
      setState(() {
        _step = _phrases.isEmpty ? 2 : 1;
        _input.clear();
        _lastOk = null;
      });
    } else if (_step == 1) {
      if (_phraseIndex + 1 < _phrases.length) {
        setState(() {
          _phraseIndex++;
          _input.clear();
          _lastOk = null;
        });
      } else {
        setState(() {
          _step = 2;
          _input.clear();
          _lastOk = null;
        });
      }
    }
  }

  Future<void> _finish() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await ref.read(sessionRepositoryProvider).saveSession(
          SessionRecord(
            id: 'quick_$now',
            scenarioId: _scenarioId,
            startedAt: now - 180000,
            endedAt: now,
            durationSec: 180,
            turnCount: 3,
            status: 'completed',
            modelName: quickSessionTag,
            reviewJson: null,
          ),
        );
    ref.invalidate(homeDataProvider);
    ref.invalidate(recentSessionsProvider);
    ref.invalidate(trendsProvider);
    if (mounted) setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '3 分钟轻量练习',
      showBack: true,
      onBack: () => context.go('/home'),
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              children: [
                Text(
                  '低能量日也能练一轮：开口说、接住话、带走一句。',
                  style: AppText.bodySecondary,
                ),
                const SizedBox(height: 8),
                Text(
                  '计入今日分钟，不计入每周 3 次有效练习（每次需 ≥8 分钟）。',
                  style: AppText.caption,
                ),
                const SizedBox(height: 14),
                if (_finished)
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 28, color: AppColors.success),
                        const SizedBox(height: 10),
                        const Text('这一轮练完了', style: AppText.cardTitle),
                        const SizedBox(height: 6),
                        Text('带走这一句：$_takeaway', style: AppText.bodySecondary),
                        const SizedBox(height: 14),
                        PrimaryButton(
                          label: '回首页',
                          onPressed: () => context.go('/home'),
                        ),
                      ],
                    ),
                  )
                else ...[
                  _StepBar(step: _step, total: 3),
                  const SizedBox(height: 14),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _step == 0
                              ? '第 1 步 · 把上次改过的说法再说一遍'
                              : _step == 1
                                  ? '第 2 步 · 接话练习 ${_phraseIndex + 1}/${_phrases.length}'
                                  : '第 3 步 · 带走今天这一句',
                          style: AppText.caption,
                        ),
                        const SizedBox(height: 8),
                        Text(_currentSentence, style: AppText.body),
                        if (_step < 2) ...[
                          const SizedBox(height: 12),
                          AppButtonRow(
                            children: [
                              SecondaryButton(
                                label: _speaking ? '播放中…' : '听一遍',
                                icon: Icons.volume_up_rounded,
                                onPressed: _speak,
                              ),
                              HoldToTalkButton(
                                label: _stopping
                                    ? '识别中…'
                                    : (_listening
                                          ? '松手完成'
                                          : (_micPressed
                                                ? '正在准备…'
                                                : '按住说一遍')),
                                active: _listening || _stopping,
                                onDown: _micDown,
                                onUp: _micUp,
                                onCancel: _cancelListening,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          AppTextField(
                            controller: _input,
                            hint: '说出或写出这句英文',
                            minLines: 2,
                            maxLines: 2,
                          ),
                          if (_audioPath != null) ...[
                            const SizedBox(height: 10),
                            SecondaryButton(
                              label: _playingRecording ? '停止回放' : '播放我的声音',
                              icon: _playingRecording
                                  ? Icons.stop_rounded
                                  : Icons.play_arrow_rounded,
                              onPressed: _playRecording,
                            ),
                          ],
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: PrimaryButton(
                              label: _lastOk == true ? '说到了 · 下一句' : '检查这一遍',
                              onPressed: _stopping
                                  ? null
                                  : () {
                                      if (_lastOk == true) {
                                        _advance();
                                      } else {
                                        final ok =
                                            _saidIt(_currentSentence, _input.text);
                                        setState(() => _lastOk = ok);
                                      }
                                    },
                            ),
                          ),
                          if (_lastOk != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _lastOk! ? '听到了，继续。' : '还没说全，再看一眼原句。',
                              style: AppText.caption,
                            ),
                          ],
                        ] else ...[
                          const SizedBox(height: 14),
                          Text(
                            '把这句记下来，下次遇到同样场景直接用。',
                            style: AppText.bodySecondary,
                          ),
                          const SizedBox(height: 10),
                          SecondaryButton(
                            label: _speaking ? '播放中…' : '听一遍',
                            icon: Icons.volume_up_rounded,
                            onPressed: _speak,
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: PrimaryButton(
                              label: '完成这一轮',
                              icon: Icons.check_rounded,
                              onPressed: _finish,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i <= step ? AppColors.primary : AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (i < total - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}
