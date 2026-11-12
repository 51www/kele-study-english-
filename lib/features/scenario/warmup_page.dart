import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import '../../domain/models/models.dart';

/// 课前 60 秒「打基础」：3 句核心表达，听 → 跟读 → 进对话。
///
/// 跟读只做「关键词是否说出」的弱判定，不打分、不评级；TTS 不可用时
/// 降级为纯文字，随时可跳过，跳过不影响场景详情页直接开练。
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final scenario =
        await ref.read(scenarioRepositoryProvider).byId(widget.scenarioId);
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
  }

  Future<void> _speak() async {
    if (_sentences.isEmpty || _speaking) return;
    setState(() => _speaking = true);
    try {
      final settings = ref.read(settingsRepositoryProvider);
      await ref.read(ttsRouterProvider).speak(
            _sentences[_index],
            voice: settings.getString(SettingsKeys.ttsVoice, 'en-US-AriaNeural'),
            rate: settings.getDouble(SettingsKeys.ttsRate, fallback: 1.0),
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  children: [
                    Text('先过 3 句核心表达，进对话就不容易卡在第一句。',
                        style: AppText.bodySecondary),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        for (var i = 0; i < _sentences.length; i++) ...[
                          Container(
                            width: 26,
                            height: 4,
                            decoration: BoxDecoration(
                              color: _checked[i]
                                  ? AppColors.primary
                                  : AppColors.line,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          if (i < _sentences.length - 1) const SizedBox(width: 6),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('第 ${_index + 1} / ${_sentences.length} 句',
                              style: AppText.caption),
                          const SizedBox(height: 8),
                          Text(_sentences[_index], style: AppText.body),
                          const SizedBox(height: 12),
                          SecondaryButton(
                            label: _speaking ? '播放中…' : '听一遍',
                            icon: Icons.volume_up_rounded,
                            onPressed: _speak,
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _input,
                            hint: '跟着说一遍，或把句子写出来',
                          ),
                          const SizedBox(height: 10),
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
                          if (_lastOk != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _lastOk!
                                  ? '听到了，接着下一句。'
                                  : '还没说全，再看一眼原句试一次。',
                              style: AppText.caption,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
