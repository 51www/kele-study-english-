import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import '../../core/errors.dart';
import '../../core/formatters.dart';
import '../../domain/models/models.dart';
import '../../services/llm/cost_estimator.dart';
import '../../services/llm/llm_models.dart';
import '../../services/llm/prompt_builder.dart';
import '../../services/tts/tts_engine.dart';

class ReviewPage extends ConsumerStatefulWidget {
  const ReviewPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage> {
  SessionRecord? _session;
  Scenario? _scenario;
  List<MessageRecord> _messages = [];
  ReviewResult? _result;
  List<Correction> _corrections = [];
  Set<String> _savedPhraseTexts = {};
  String? _playingId;
  bool _loading = true;
  bool _generating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final session = await ref.read(sessionRepositoryProvider).byId(widget.sessionId);
      if (session == null) {
        setState(() {
          _loading = false;
          _error = '练习记录不存在';
        });
        return;
      }
      final scenario = await ref.read(scenarioRepositoryProvider).byId(session.scenarioId ?? '');
      final messages = await ref.read(sessionRepositoryProvider).messages(session.id);
      final corrections = await ref.read(sessionRepositoryProvider).corrections(session.id);
      final phrases = await ref.read(sessionRepositoryProvider).phrases();
      setState(() {
        _session = session;
        _scenario = scenario;
        _messages = messages;
        _result = ReviewResult.tryDecode(session.reviewJson);
        _corrections = corrections;
        _savedPhraseTexts = phrases.map((e) => e.textEn).toSet();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '加载失败：$e';
      });
    }
  }

  Future<void> _generate() async {
    final session = _session;
    final scenario = _scenario;
    if (session == null) return;
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final repo = ref.read(llmProfileRepositoryProvider);
      final profile = await repo.loadOrCreate();
      final key = await ref.read(keyStoreProvider).read(profile.keyRef);
      if (key == null || key.isEmpty) {
        throw const AppError(
          kind: AppErrorKind.config,
          detail: '还没有配置模型密钥，无法生成复盘。',
        );
      }
      final config = LlmConfig(baseUrl: profile.baseUrl, apiKey: key, model: profile.model);
      final prompt = PromptBuilder.reviewMessages(scenario: scenario, history: _messages);
      final client = ref.read(llmClientProvider);
      var result = ReviewParser.parse(
        (await client.chat(config, prompt, maxTokens: 900, temperature: 0.4)).text,
      );
      if (result.degraded) {
        // 结构化输出不稳定：自动重试一次（更低温度），仍失败才给失败态。
        result = ReviewParser.parse(
          (await client.chat(config, prompt, maxTokens: 900, temperature: 0.2)).text,
        );
      }
      if (!mounted) return;
      if (result.degraded) {
        // 模型两次都没有按格式返回：显示失败态 + 重试，不展示半截内容。
        setState(() {
          _generating = false;
          _error = '本次未能生成总结，模型返回格式异常，请重试一次。';
        });
        return;
      }
      result = ReviewResult(
        highlight: result.highlight,
        corrections: result.corrections,
        phrases: result.phrases,
        nextTip: result.nextTip,
        promptCount: session.hintCount,
        degraded: false,
      );
      // 纠错入库：尽量回链到原文所在的用户消息。
      final now = DateTime.now().microsecondsSinceEpoch;
      final rows = <Correction>[];
      for (var i = 0; i < result.corrections.length; i++) {
        final item = result.corrections[i];
        String messageId = '';
        for (final message in _messages) {
          if (message.isUser &&
              message.textEn.toLowerCase().contains(item.original.toLowerCase())) {
            messageId = message.id;
            break;
          }
        }
        rows.add(Correction(
          id: 'c_${now}_$i',
          sessionId: session.id,
          messageId: messageId,
          original: item.original,
          improved: item.improved,
          reasonZh: item.reasonZh,
          createdAt: now + i,
        ));
      }
      await ref.read(sessionRepositoryProvider).replaceCorrections(session.id, rows);
      final updated = session.copyWith(
        reviewJson: result.encode(),
        status: 'completed',
      );
      await ref.read(sessionRepositoryProvider).saveSession(updated);
      ref.invalidate(homeDataProvider);
      ref.invalidate(recentSessionsProvider);
      ref.invalidate(correctionsForSessionProvider(session.id));
      if (!mounted) return;
      setState(() {
        _result = result;
        _session = updated;
        _corrections = rows;
        _generating = false;
      });
    } on AppError catch (e) {
      if (!mounted) return;
      setState(() {
        _generating = false;
        _error = e.detail ?? '生成复盘失败';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generating = false;
        _error = '生成复盘失败：$e';
      });
    }
  }

  /// 试听改进后的说法。
  Future<void> _playCorrection(Correction correction) async {
    if (_playingId == correction.id) {
      await ref.read(ttsRouterProvider).stop();
      if (mounted) setState(() => _playingId = null);
      return;
    }
    setState(() => _playingId = correction.id);
    try {
      final settings = ref.read(settingsRepositoryProvider);
      await ref.read(ttsRouterProvider).speak(
            correction.improved,
            voice: settings.getString(SettingsKeys.ttsVoice, 'en-US-AriaNeural'),
            rate: settings.getDouble(SettingsKeys.ttsRate, fallback: 1.0),
            preferEdge: settings.getString(SettingsKeys.ttsEngine, 'edge') != 'system',
          );
    } on TtsException {
      if (mounted) showAppToast(context, '朗读暂不可用', error: true);
    } finally {
      if (mounted) setState(() => _playingId = null);
    }
  }

  Future<void> _deleteCorrection(Correction correction) async {
    await ref.read(sessionRepositoryProvider).deleteCorrection(correction.id);
    if (!mounted) return;
    setState(() => _corrections = _corrections.where((e) => e.id != correction.id).toList());
    ref.invalidate(correctionsForSessionProvider(widget.sessionId));
  }

  Future<void> _savePhrase(String phrase) async {
    if (_savedPhraseTexts.contains(phrase)) return;
    final now = DateTime.now();
    await ref.read(sessionRepositoryProvider).savePhrase(Phrase(
          id: 'p_${now.microsecondsSinceEpoch}',
          textEn: phrase,
          sourceSessionId: widget.sessionId,
          sourceScenarioId: _session?.scenarioId,
          createdAt: now.millisecondsSinceEpoch,
        ));
    ref.invalidate(phrasesProvider);
    if (!mounted) return;
    setState(() => _savedPhraseTexts = {..._savedPhraseTexts, phrase});
    showAppToast(context, '已存入表达本');
  }

  Future<void> _practiceAgain() async {
    final scenario = _scenario;
    if (scenario == null) {
      context.go('/home');
      return;
    }
    final profile = await ref.read(profileInfoProvider.future);
    final settings = ref.read(settingsControllerProvider);
    final session = await ref.read(sessionRepositoryProvider).createSession(
          scenario: scenario,
          modelName: profile.profile.model,
          ttsEngine: settings[SettingsKeys.ttsEngine] ?? 'edge',
        );
    if (!mounted) return;
    context.pushReplacement('/chat/${session.id}');
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '本次复盘',
      showBack: true,
      onBack: () => context.go('/home'),
      bottomBar: _loading
          ? null
          : Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: SafeArea(
                top: false,
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: '返回首页',
                            onPressed: () => context.go('/home'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: PrimaryButton(
                            label: '再练一次',
                            onPressed: _practiceAgain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null && _session == null
              ? EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: '没能打开这次复盘',
                  message: _error!,
                  actionLabel: '重新加载',
                  action: _load,
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  children: [
                    _SummaryCard(session: _session!),
                    const SizedBox(height: 18),
                    if (_error != null) ...[
                      ErrorBanner(message: _error!, onRetry: _generate),
                      const SizedBox(height: 14),
                    ],
                    if (_result == null)
                      _GenerateCard(
                        generating: _generating,
                        onGenerate: _generate,
                        message: _messages.length <= 1
                            ? '这次还没有开口，先完成几句对话再来复盘吧。'
                            : '让 AI 帮你找出可以立刻改进的表达。',
                      )
                    else
                      _ReviewContent(
                        result: _result!,
                        corrections: _corrections,
                        savedPhraseTexts: _savedPhraseTexts,
                        playingId: _playingId,
                        onDeleteCorrection: _deleteCorrection,
                        onPlayCorrection: _playCorrection,
                        onSavePhrase: _savePhrase,
                      ),
                    const SizedBox(height: 18),
                    _TranscriptCard(messages: _messages),
                  ],
                ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.session});

  final SessionRecord session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF839AFF), Color(0xFF5A74F0)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text('练习完成', style: AppText.cardTitle.copyWith(color: Colors.white)),
              const Spacer(),
              Text(
                formatDate(session.startedDate),
                style: AppText.caption.copyWith(color: Colors.white.withValues(alpha: 0.75)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Metric(label: '时长', value: formatDuration(session.durationSec)),
              _Metric(label: '开口', value: '${session.turnCount} 轮'),
              _Metric(label: '提示', value: '${session.hintCount} 次'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '有辅助 ${session.assistTurns} 回合 · 翻译 ${session.translateCount} 次'
            '${session.costEstimate == null ? '' : ' · 本次 ${CostEstimator.format(session.costEstimate!)}（估算）'}',
            style: AppText.caption.copyWith(color: Colors.white.withValues(alpha: 0.82)),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppText.h2.copyWith(color: Colors.white, fontSize: 20)),
          Text(label, style: AppText.caption.copyWith(color: Colors.white.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}

class _GenerateCard extends StatelessWidget {
  const _GenerateCard({
    required this.generating,
    required this.onGenerate,
    required this.message,
  });

  final bool generating;
  final VoidCallback onGenerate;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      shadow: false,
      color: AppColors.surfaceTint,
      child: Column(
        children: [
          const Icon(Icons.tips_and_updates_outlined, size: 34, color: AppColors.primary),
          const SizedBox(height: 10),
          Text('生成本次复盘', style: AppText.section),
          const SizedBox(height: 6),
          Text(message, style: AppText.bodySecondary, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          PrimaryButton(
            label: generating ? '正在分析…' : '生成复盘',
            loading: generating,
            onPressed: generating ? null : onGenerate,
          ),
        ],
      ),
    );
  }
}

class _ReviewContent extends StatelessWidget {
  const _ReviewContent({
    required this.result,
    required this.corrections,
    required this.savedPhraseTexts,
    required this.playingId,
    required this.onDeleteCorrection,
    required this.onPlayCorrection,
    required this.onSavePhrase,
  });

  final ReviewResult result;
  final List<Correction> corrections;
  final Set<String> savedPhraseTexts;
  final String? playingId;
  final void Function(Correction) onDeleteCorrection;
  final void Function(Correction) onPlayCorrection;
  final void Function(String) onSavePhrase;

  @override
  Widget build(BuildContext context) {
    // 纠错以数据库为准（删除后不再出现）；老会话没有入库记录时回退到解析结果。
    final items = corrections.isNotEmpty
        ? corrections
            .map((e) => ReviewCorrection(
                  original: e.original,
                  improved: e.improved,
                  reasonZh: e.reasonZh,
                ))
            .toList()
        : result.corrections;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          shadow: false,
          color: AppColors.mint.withValues(alpha: 0.18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.emoji_events_outlined, color: AppColors.success, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('这次做得好的地方', style: AppText.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(result.highlight, style: AppText.body.copyWith(height: 1.55)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SectionTitle(title: '可以更自然的地方'),
          const SizedBox(height: 8),
          ..._buildCorrectionCards(items),
        ],
        if (result.phrases.isNotEmpty) ...[
          const SizedBox(height: 10),
          const SectionTitle(title: '值得记住的表达'),
          const SizedBox(height: 8),
          ...result.phrases.map(
            (phrase) => _PhraseRow(
              phrase: phrase,
              saved: savedPhraseTexts.contains(phrase),
              onSave: () => onSavePhrase(phrase),
            ),
          ),
        ],
        const SizedBox(height: 16),
        AppCard(
          shadow: false,
          color: AppColors.warning.withValues(alpha: 0.1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.arrow_forward_rounded, color: AppColors.warning, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('下次可以试试', style: AppText.caption.copyWith(color: AppColors.warning, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(result.nextTip, style: AppText.bodySecondary.copyWith(color: AppColors.ink)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCorrectionCards(List<ReviewCorrection> items) {
    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final correction = index < corrections.length ? corrections[index] : null;
      final playing = correction != null && playingId == correction.id;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.change_circle_outlined, size: 15, color: AppColors.orange),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      item.original,
                      style: AppText.bodySecondary.copyWith(
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_circle_outline_rounded, size: 15, color: AppColors.success),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      item.improved,
                      style: AppText.body.copyWith(fontWeight: FontWeight.w600, height: 1.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 22),
                child: Text(item.reasonZh, style: AppText.caption.copyWith(height: 1.5)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _MiniAction(
                    icon: playing ? Icons.stop_rounded : Icons.volume_up_rounded,
                    label: playing ? '停止' : '试听',
                    onTap: correction == null ? null : () => onPlayCorrection(correction),
                  ),
                  const SizedBox(width: 8),
                  _MiniAction(
                    icon: Icons.delete_outline_rounded,
                    label: '删除',
                    onTap: correction == null ? null : () => onDeleteCorrection(correction),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surfaceTint,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: AppColors.inkSecondary),
              const SizedBox(width: 4),
              Text(label, style: AppText.caption.copyWith(fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhraseRow extends StatelessWidget {
  const _PhraseRow({
    required this.phrase,
    required this.saved,
    required this.onSave,
  });

  final String phrase;
  final bool saved;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.primaryWash,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(phrase, style: AppText.body.copyWith(fontSize: 13, height: 1.5)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: saved ? null : onSave,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: saved ? Colors.white.withValues(alpha: 0.6) : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: saved ? AppColors.divider : AppColors.primaryDeep,
                ),
              ),
              child: Text(
                saved ? '已存' : '存表达',
                style: AppText.caption.copyWith(
                  fontSize: 10,
                  color: saved ? AppColors.inkMuted : AppColors.primaryDeep,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  const _TranscriptCard({required this.messages});

  final List<MessageRecord> messages;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 12),
          title: Text('查看对话原文', style: AppText.cardTitle),
          iconColor: AppColors.inkMuted,
          collapsedIconColor: AppColors.inkMuted,
          children: messages
              .where((m) => !m.isHint && m.textEn.trim().isNotEmpty)
              .map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 34,
                        child: Text(
                          m.isUser ? '你' : 'AI',
                          style: AppText.caption.copyWith(
                            color: m.isUser ? AppColors.primaryDeep : AppColors.orange,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(child: Text(m.textEn, style: AppText.bodySecondary.copyWith(color: AppColors.ink))),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
