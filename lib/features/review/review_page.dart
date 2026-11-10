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
import '../../services/llm/llm_models.dart';
import '../../services/llm/prompt_builder.dart';

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
      setState(() {
        _session = session;
        _scenario = scenario;
        _messages = messages;
        _result = ReviewResult.tryDecode(session.reviewJson);
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
      final reply = await ref.read(llmClientProvider).chat(
            LlmConfig(baseUrl: profile.baseUrl, apiKey: key, model: profile.model),
            PromptBuilder.reviewMessages(scenario: scenario, history: _messages),
            maxTokens: 900,
            temperature: 0.4,
          );
      final result = ReviewParser.parse(reply.text);
      final updated = session.copyWith(
        reviewJson: result.encode(),
        status: 'completed',
      );
      await ref.read(sessionRepositoryProvider).saveSession(updated);
      ref.invalidate(homeDataProvider);
      ref.invalidate(recentSessionsProvider);
      if (!mounted) return;
      setState(() {
        _result = result;
        _session = updated;
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
              ? Center(child: Text(_error!, style: AppText.bodySecondary))
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
                      _ReviewContent(result: _result!),
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
  const _ReviewContent({required this.result});

  final ReviewResult result;

  @override
  Widget build(BuildContext context) {
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
        if (result.corrections.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SectionTitle(title: '可以更自然的地方'),
          const SizedBox(height: 8),
          ...result.corrections.map(
            (item) => Padding(
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
                  ],
                ),
              ),
            ),
          ),
        ],
        if (result.phrases.isNotEmpty) ...[
          const SizedBox(height: 10),
          const SectionTitle(title: '值得记住的表达'),
          const SizedBox(height: 8),
          ...result.phrases.map(
            (phrase) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryWash,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(phrase, style: AppText.body.copyWith(fontSize: 13, height: 1.5)),
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
