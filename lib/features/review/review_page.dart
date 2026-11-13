import 'dart:async';

import 'package:dio/dio.dart';
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
import '../../core/logger.dart';
import '../../core/timeouts.dart';
import '../../domain/models/models.dart';
import '../path/next_step_card.dart';
import '../path/path_providers.dart';
import '../retention/practice_card.dart';
import '../retention/review_item.dart';
import 'goal_checklist.dart';
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
  bool _slow = false;
  bool _timedOut = false;
  CancelToken? _cancelToken;
  Timer? _slowTimer;
  Timer? _deadlineTimer;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    _deadlineTimer?.cancel();
    // 离开复盘页时不再让在途请求继续占用连接 / 产生费用。
    _cancelToken?.cancel('page disposed');
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final session = await ref.read(sessionRepositoryProvider).byId(widget.sessionId);
      if (session == null) {
        if (!mounted) return;
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
      // 结束对话后立刻返回时，异步读库可能晚于页面销毁；此时 setState 会抛异常。
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '加载失败：$e';
      });
    }
  }

  Future<void> _generate() async {
    final session = _session;
    final scenario = _scenario;
    if (session == null || _generating) return;
    final token = CancelToken();
    _cancelToken = token;
    _timedOut = false;
    setState(() {
      _generating = true;
      _slow = false;
      _error = null;
    });
    // 单次请求不再叠加客户端自动重试；等待期间给慢提示与可取消出口。
    _slowTimer = Timer(Timeouts.slowNotice, () {
      if (mounted && _generating && !token.isCancelled) {
        setState(() => _slow = true);
      }
    });
    _deadlineTimer = Timer(Timeouts.review, () {
      if (!token.isCancelled) {
        _timedOut = true;
        token.cancel('review deadline');
      }
    });

    String? failure;
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
      final raw = await _requestReview(config, prompt, 0.4, token);
      if (token.isCancelled) return;
      var result = ReviewParser.parse(raw);
      if (result.degraded) {
        // 结构化输出不稳定：退避后只自动重试一次（更低温度）。
        if (token.isCancelled) return;
        await Future<void>.delayed(Timeouts.reviewRetryBackoff);
        if (token.isCancelled) return;
        result = ReviewParser.parse(await _requestReview(config, prompt, 0.2, token));
      }
      if (!mounted || token.isCancelled) return;
      if (result.degraded) {
        // 模型两次都没有按格式返回：显示失败态 + 重试，不展示半截内容。
        failure = '本次未能生成总结，模型返回格式异常，请重试一次。';
        return;
      }
      final takeawayText = result.corrections
              .where((e) => e.improved.trim().isNotEmpty)
              .firstOrNull
              ?.improved
              .trim() ??
          result.phrases.where((e) => e.trim().isNotEmpty).firstOrNull?.trim();
      result = ReviewResult(
        highlight: result.highlight,
        corrections: result.corrections,
        phrases: result.phrases,
        nextTip: result.nextTip,
        promptCount: session.hintCount,
        degraded: false,
        takeawayText: takeawayText,
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
      await _enqueueTakeaway(session.id, result);
      ref.invalidate(homeDataProvider);
      ref.invalidate(recentSessionsProvider);
      ref.invalidate(correctionsForSessionProvider(session.id));
      // 会话完成后阶段进度与下一步要立即重算。
      ref.invalidate(pathPlanProvider);
      if (!mounted) return;
      setState(() {
        _result = result;
        _session = updated;
        _corrections = rows;
        _generating = false;
      });
    } on AppError catch (e) {
      if (!token.isCancelled) failure = e.detail ?? '生成复盘失败';
    } catch (e) {
      if (!token.isCancelled) failure = '生成复盘失败：$e';
    } finally {
      _slowTimer?.cancel();
      _deadlineTimer?.cancel();
      _slowTimer = null;
      _deadlineTimer = null;
      _cancelToken = null;
      if (mounted) {
        setState(() {
          _generating = false;
          _slow = false;
          if (_timedOut) {
            _error = '生成超时，请重试一次。';
          } else if (failure != null) {
            _error = failure;
          }
        });
      }
    }
  }

  /// 单次复盘请求：流式优先（SSE 只收 delta.content，思考内容不会污染正文）；
  /// 接口不支持流式或流里没有正文时，再用一次非流式请求兜底。
  /// 整体超时 / 用户取消都由 [token] 生效，不在这里叠加自动重试。
  Future<String> _requestReview(
    LlmConfig config,
    List<LlmMessage> prompt,
    double temperature,
    CancelToken token,
  ) async {
    final client = ref.read(llmClientProvider);
    final buffer = StringBuffer();
    try {
      await for (final delta in client.streamChat(
        config,
        prompt,
        maxTokens: 900,
        temperature: temperature,
        cancelToken: token,
        maxRetries: 0,
      )) {
        buffer.write(delta);
      }
    } on AppError catch (e) {
      // 鉴权 / 404 / 限流不兜底；服务端异常才换非流式再取一次。
      if (e.kind != AppErrorKind.server || token.isCancelled) rethrow;
      AppLogger.warn('review stream failed, fallback to non-stream: ${e.detail}');
    }
    if (token.isCancelled) return '';
    final streamed = buffer.toString().trim();
    if (streamed.isNotEmpty) return streamed;

    final reply = await client.chat(
      config,
      prompt,
      maxTokens: 900,
      temperature: temperature,
      cancelToken: token,
      receiveTimeout: Timeouts.review,
      maxRetries: 0,
      allowReasoningFallback: false,
    );
    return reply.text;
  }

  void _cancelGeneration() {
    _cancelToken?.cancel('user cancelled');
  }

  /// 把本次复盘的一条重点放进待复练队列（同一会话只入队一次）。
  Future<void> _enqueueTakeaway(String sessionId, ReviewResult result) async {
    final text = result.takeawayText;
    if (text == null || text.trim().isEmpty) return;
    final store = ref.read(localStoreProvider);
    final items = await store.reviewItems();
    if (ReviewScheduler.hasSource(items, 'correction', sessionId)) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await store.upsertReviewItem(
      ReviewScheduler.create(
        id: 'rv_${sessionId}_$now',
        sourceType: 'correction',
        sourceId: sessionId,
        textEn: text.trim(),
        textZh: result.corrections.firstOrNull?.reasonZh,
        nowMs: now,
      ),
    );
    ref.invalidate(reviewItemsProvider);
    ref.invalidate(dueReviewItemsProvider);
    ref.invalidate(todayPlanProvider);
    ref.invalidate(pathPlanProvider);
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
    final takeaway = ref.watch(reviewItemsProvider).asData?.value
        .where((e) => e.sourceType == 'correction' && e.sourceId == _session?.id)
        .firstOrNull;
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
                        slow: _slow,
                        onCancel: _cancelGeneration,
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
                    if (_scenario != null && _result != null) ...[
                      const SizedBox(height: 14),
                      GoalChecklistCard(
                        session: _session!,
                        result: _result!,
                        scenario: _scenario!,
                      ),
                      const SizedBox(height: 14),
                      const ReviewNextStepCard(),
                    ],
                    if (takeaway != null) ...[
                      const SizedBox(height: 14),
                      TakeawayPracticeCard(item: takeaway),
                    ],
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
    required this.slow,
    required this.onCancel,
  });

  final bool generating;
  final bool slow;
  final VoidCallback onGenerate;
  final VoidCallback onCancel;
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
          Text(
            generating
                ? (slow ? '模型还在生成，可继续等待或取消。' : '正在分析这次对话…')
                : message,
            style: AppText.bodySecondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: generating ? '正在分析…' : '生成复盘',
            loading: generating,
            onPressed: generating ? null : onGenerate,
          ),
          if (generating) ...[
            const SizedBox(height: 8),
            SecondaryButton(label: '取消生成', onPressed: onCancel),
          ],
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
    // 数据库为准（删除后不再出现）；扩展字段从 review_json 按原句回填，
    // 这样不改 correction 表也能显示中式成因与两种语体。
    final parsedByOriginal = <String, ReviewCorrection>{
      for (final item in result.corrections)
        item.original.trim().toLowerCase(): item,
    };
    final items = corrections.isNotEmpty
        ? corrections
            .map((e) {
              final parsed = parsedByOriginal[e.original.trim().toLowerCase()];
              return ReviewCorrection(
                original: e.original,
                improved: e.improved,
                reasonZh: e.reasonZh,
                causeZh: parsed?.causeZh,
                casual: parsed?.casual,
                formal: parsed?.formal,
                registerNote: parsed?.registerNote,
              );
            })
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
              if (item.causeZh != null ||
                  item.casual != null ||
                  item.formal != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryWash,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.causeZh != null)
                        Text('为什么会这么说：${item.causeZh}',
                            style: AppText.caption.copyWith(height: 1.5)),
                      if (item.casual != null) ...[
                        const SizedBox(height: 4),
                        Text('日常说法：${item.casual}',
                            style: AppText.bodySecondary.copyWith(height: 1.5)),
                      ],
                      if (item.formal != null) ...[
                        const SizedBox(height: 4),
                        Text('正式说法：${item.formal}',
                            style: AppText.bodySecondary.copyWith(height: 1.5)),
                      ],
                      if (item.registerNote != null) ...[
                        const SizedBox(height: 4),
                        Text(item.registerNote!,
                            style: AppText.caption.copyWith(height: 1.5)),
                      ],
                    ],
                  ),
                ),
              ],
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
