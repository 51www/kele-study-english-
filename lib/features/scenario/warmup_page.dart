import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import '../../app/widgets/hold_to_talk_button.dart';
import '../../domain/models/models.dart';
import '../../services/tts/tts_speech.dart';

/// 课前 60 秒「打基础」：3 句核心表达，听 → 跟读 → 进对话。
///
/// 跟读支持按麦语音识别或键盘输入，只做「关键词是否说出」的弱判定，不打分、
/// 不评级；TTS 不可用时降级为纯文字，随时可跳过，跳过不影响场景详情页直接开练。
class WarmupPage extends ConsumerStatefulWidget {
  const WarmupPage({super.key, required this.scenarioId});

  final String scenarioId;

  @override
  ConsumerState<WarmupPage> createState() => _WarmupPageState();
}

class _WarmupPageState extends ConsumerState<WarmupPage> {
  final TextEditingController _input = TextEditingController();
  List<String> _sentences = <String>[];
  List<bool> _checked = <bool>[];
  int _index = 0;
  bool? _lastOk;
  bool _loading = true;
  bool _speaking = false;

  // 按住说话：按下即起录，松手即定稿，不再有「说完了」二次确认。
  bool _asrReady = false;
  bool _micPressed = false;
  bool _micCancelled = false;
  bool _listening = false;
  bool _stopping = false;
  Future<void>? _starting;
  DateTime? _pressStartedAt;
  Timer? _maxTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _maxTimer?.cancel();
    if (_listening || _starting != null) {
      unawaited(ref.read(asrRouterProvider).cancel());
    }
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final scenario = await ref
        .read(scenarioRepositoryProvider)
        .byId(widget.scenarioId);
    final sentences = (scenario?.targetPhrases ?? const <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(3)
        .toList();
    if (!mounted) return;
    setState(() {
      _sentences = sentences;
      _checked = List<bool>.filled(sentences.length, false);
      _loading = false;
    });
    // 提前把识别引擎与录音权限准备好，按下按钮就能立刻起录，
    // 避免「先说话才真正开始录音」导致只识别到最后半句。
    unawaited(_prewarmAsr());
  }

  Future<void> _prewarmAsr() async {
    try {
      _asrReady = await ref.read(asrRouterProvider).initialize();
    } on Object {
      _asrReady = false;
    }
  }

  Future<void> _speak() async {
    if (_sentences.isEmpty || _speaking || _listening) return;
    setState(() => _speaking = true);
    try {
      final settings = ref.read(settingsRepositoryProvider);
      await ref
          .read(ttsRouterProvider)
          .speak(
            _sentences[_index],
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

  /// 按下麦克风：立即起录。引擎已在进页时预热，这里只做启动，避免漏掉开头。
  void _micDown() {
    if (_starting != null || _listening || _stopping) return;
    _micCancelled = false;
    _pressStartedAt = DateTime.now();
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
    // 录音与朗读互斥：按下麦克风先停朗读。
    await ref.read(ttsRouterProvider).stop();
    if (!mounted) {
      await engine.cancel();
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
        showAppToast(context, '没能开始识别，改用键盘写吧', error: true);
      }
    }
  }

  /// 松开麦克风：短按视为误触，正常按住则立即结束录音并填入识别文本。
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

  /// 松手即完成：停止录音，一次性取回整段识别结果，不再需要「说完了」二次确认。
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

  List<String> _keywords(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.length > 2)
      .toList();

  /// 弱判定：说出一半以上关键词就算过，不给分数。
  bool _saidIt(String answer) {
    final target = _keywords(_sentences[_index]);
    final spoken = answer.toLowerCase();
    if (target.isEmpty) return answer.trim().isNotEmpty;
    final hits = target.where((word) => spoken.contains(word)).length;
    return hits >= (target.length / 2).ceil();
  }

  void _check() {
    final ok = _saidIt(_input.text);
    if (ok) _checked[_index] = true;
    setState(() => _lastOk = ok);
  }

  void _next() {
    if (_index >= _sentences.length - 1) return;
    setState(() {
      _index++;
      _input.clear();
      _lastOk = null;
    });
  }

  void _openScenario() => context.go('/scenario/${widget.scenarioId}');

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '课前热身',
      showBack: true,
      onBack: _openScenario,
      actions: [
        TextButton(
          onPressed: _openScenario,
          child: const Text('跳过', style: AppText.caption),
        ),
      ],
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _sentences.isEmpty
          ? AppCard(
              child: EmptyState(
                icon: Icons.record_voice_over_rounded,
                title: '这个场景还没有核心表达',
                message: '直接开始对话也一样能练。',
                actionLabel: '去开练',
                action: _openScenario,
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.buttonGap,
                AppSpacing.page,
                AppSpacing.page,
              ),
              children: [
                Text('先过 3 句核心表达，进对话就不容易卡在第一句。', style: AppText.bodySecondary),
                const SizedBox(height: AppSpacing.buttonGap),
                Row(
                  children: [
                    for (var i = 0; i < _sentences.length; i++) ...[
                      Container(
                        width: 24,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _checked[i]
                              ? AppColors.primary
                              : AppColors.line,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      if (i < _sentences.length - 1)
                        const SizedBox(width: AppSpacing.tight),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.cardInner),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '第 ${_index + 1} / ${_sentences.length} 句',
                        style: AppText.caption,
                      ),
                      const SizedBox(height: AppSpacing.element),
                      Text(_sentences[_index], style: AppText.body),
                      const SizedBox(height: AppSpacing.buttonGap),
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
                                      : (_micPressed ? '正在准备…' : '按住说一遍')),
                            active: _listening || _stopping,
                            onDown: _micDown,
                            onUp: _micUp,
                            onCancel: _cancelListening,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.buttonGap),
                      AppTextField(
                        controller: _input,
                        hint: '跟着说一遍，或把句子写出来',
                        minLines: 2,
                        maxLines: 2,
                      ),
                      if (_lastOk != true ||
                          _index < _sentences.length - 1) ...[
                        const SizedBox(height: AppSpacing.buttonGap),
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            label: _lastOk == true ? '说到了 · 下一句' : '检查这一遍',
                            onPressed: () {
                              if (_lastOk == true) {
                                _next();
                              } else {
                                _check();
                              }
                            },
                          ),
                        ),
                      ],
                      if (_lastOk != null) ...[
                        const SizedBox(height: AppSpacing.buttonGap),
                        Text(
                          _lastOk!
                              ? (_index >= _sentences.length - 1
                                    ? '听到了，全部练完了。'
                                    : '听到了，接着下一句。')
                              : '还没说全，再看一眼原句试一次。',
                          style: AppText.caption,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.cardInner),
                if (_checked.every((done) => done))
                  SecondaryButton(
                    label: '3 句都过了 · 去开练',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _openScenario,
                  )
                else
                  SecondaryButton(
                    label: '跳过热身，直接开练',
                    icon: Icons.skip_next_rounded,
                    onPressed: _openScenario,
                  ),
              ],
            ),
    );
  }
}
