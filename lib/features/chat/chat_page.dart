import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import '../../core/formatters.dart';
import '../../core/logger.dart';
import '../../domain/models/models.dart';
import '../../services/tts/tts_engine.dart';
import 'answer_actions.dart';
import 'chat_widgets.dart';
import 'conversation_controller.dart';
import 'learner_profile.dart';
import 'reward_burst.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  late final ConversationController _controller;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _ending = false;
  final Set<String> _expandedCorrections = {};
  String? _playingCorrectionId;

  bool _hintOpen = false;
  final Set<String> _openImprovements = {};
  String? _playingImprovementId;

  // 正向反馈只按「新增用户回答」触发，不能被每秒刷新的计时器反复触发。
  int _rewardTrigger = 0;
  int _lastUserCount = -1;
  int _lastMessageCount = 0;
  String _lastStreamingText = '';

  // 用户主动上滑浏览历史时停止自动跟随，回到最新后恢复。
  bool _followBottom = true;
  // 区分「程序自动滚到底」与「用户自己滚」，避免滚轮 / 惯性滚动被误判。
  bool _autoScrolling = false;

  @override
  void initState() {
    super.initState();
    _controller = ConversationController(
      sessionId: widget.sessionId,
      sessions: ref.read(sessionRepositoryProvider),
      scenarios: ref.read(scenarioRepositoryProvider),
      settings: ref.read(settingsRepositoryProvider),
      llmClient: ref.read(llmClientProvider),
      profiles: ref.read(llmProfileRepositoryProvider),
      keyStore: ref.read(keyStoreProvider),
      asr: ref.read(asrEngineProvider),
      recorder: ref.read(audioRecorderProvider),
      player: ref.read(audioPlayerProvider),
      audioSession: ref.read(audioSessionProvider),
      tts: ref.read(ttsRouterProvider),
    )..addListener(_onUpdate);
    _controller.init();
    unawaited(_loadLearnerProfile());
  }

  /// 只读档案异步聚合，失败也不影响对话；关闭开关时 Provider 返回 null。
  Future<void> _loadLearnerProfile() async {
    try {
      final profile =
          await ref.read(learnerProfileProvider(widget.sessionId).future);
      if (mounted && _controller.learnerProfileEnabled) {
        _controller.learnerProfile = profile;
      }
    } catch (e) {
      AppLogger.warn('learner profile unavailable: $e');
    }
  }

  void _onUpdate() {
    if (!mounted) return;
    final c = _controller;
    final userCount = c.messages.where((m) => m.isUser).length;
    final answered = _lastUserCount >= 0 && userCount > _lastUserCount;
    _lastUserCount = userCount;

    // 只在「对话内容真的变了」且用户没有上滑看历史时才滚到底部。
    // 旧实现每次 notify（含每秒计时器）都 animateTo，导致上滑被强制拉回。
    final contentChanged = c.messages.length != _lastMessageCount ||
        c.streamingText != _lastStreamingText;
    _lastMessageCount = c.messages.length;
    _lastStreamingText = c.streamingText;
    final streaming = c.streamingText.trim().isNotEmpty;

    if (answered) {
      _rewardTrigger++;
      _followBottom = true;
    }
    setState(() {});
    if (contentChanged && _followBottom) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToBottom(animate: !streaming),
      );
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      // 用户一开始拖动就停止跟随，新消息不会再把他拉回底部。
      if (_followBottom) setState(() => _followBottom = false);
    } else if (notification is ScrollUpdateNotification && !_autoScrolling) {
      // 按当前位置判断，覆盖触摸、鼠标滚轮、触控板与惯性滚动；
      // 程序自动滚到底期间跳过，避免把自身动画当成用户操作。
      final metrics = notification.metrics;
      final atBottom = metrics.pixels >= metrics.maxScrollExtent - 24;
      if (!atBottom && _followBottom) {
        setState(() => _followBottom = false);
      } else if (atBottom && !_followBottom) {
        setState(() => _followBottom = true);
      }
    } else if (notification is ScrollEndNotification && !_autoScrolling) {
      final metrics = notification.metrics;
      if (metrics.pixels >= metrics.maxScrollExtent - 24 && !_followBottom) {
        setState(() => _followBottom = true);
      }
    }
    return false;
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scroll.hasClients) return;
    final target = _scroll.position.maxScrollExtent;
    if (animate) {
      _autoScrolling = true;
      unawaited(
        _scroll
            .animateTo(
              target,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
            )
            .then(
              (_) {
                _autoScrolling = false;
              },
              onError: (Object _) {
                _autoScrolling = false;
              },
            ),
      );
    } else {
      _scroll.jumpTo(target);
    }
  }

  void _backToLatest() {
    setState(() => _followBottom = true);
    _scrollToBottom();
  }

  /// 「提示」不再展开 L1–L4 工具项：打开面板即直接要一句 L3 参考回答。
  void _toggleHint() {
    if (_hintOpen) {
      _controller.closeHint();
      setState(() => _hintOpen = false);
      return;
    }
    setState(() => _hintOpen = true);
    if (!_controller.hintLoading) {
      unawaited(_controller.requestHint(3));
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    // 系统返回键 / 侧滑手势不会走 _back()，这里兜底把会话存成可续练状态。
    unawaited(_controller.pauseSession());
    _controller.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _refreshSessions() {
    ref.invalidate(homeDataProvider);
    ref.invalidate(recentSessionsProvider);
    ref.invalidate(monthlyCostProvider);
    ref.invalidate(lastLatencyProvider);
    ref.invalidate(scenarioLibraryProvider);
  }

  Future<void> _send() async {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    await _controller.sendText(text);
  }

  /// 「我想说」只把建议放进输入框，用户必须再按一次发送或麦克风。
  void _applyWantToSay(String text) {
    _input.text = text;
    _input.selection = TextSelection.collapsed(offset: text.length);
    _controller.clearWantToSay();
    setState(() {});
  }

  Future<void> _toggleImprovement(MessageRecord message) async {
    if (_openImprovements.contains(message.id)) {
      _controller.closeImprovement(message.id);
      if (mounted) setState(() => _openImprovements.remove(message.id));
      return;
    }
    // 旁路一次只跑一条；否则第二张卡片会一直停在「正在想…」。
    if (_controller.improvingMessageId != null) {
      showAppToast(context, '上一句还在优化，稍等一下再点');
      return;
    }
    setState(() => _openImprovements.add(message.id));
    await _controller.optimizeSentence(message);
  }

  Future<void> _playOriginal(MessageRecord message) async {
    final path = message.audioPath;
    if (path == null || path.isEmpty) {
      showAppToast(context, '这句是文字输入或系统识别，没有录到原声');
      return;
    }
    await _controller.playOriginal(message);
  }

  Future<void> _playImprovement(String messageId, String text) async {
    if (_playingImprovementId == messageId) {
      await ref.read(ttsRouterProvider).stop();
      if (mounted) setState(() => _playingImprovementId = null);
      return;
    }
    setState(() => _playingImprovementId = messageId);
    try {
      final settings = ref.read(settingsRepositoryProvider);
      await ref.read(ttsRouterProvider).speak(
            text,
            voice: settings.getString(SettingsKeys.ttsVoice, 'en-US-AriaNeural'),
            rate: settings.getDouble(SettingsKeys.ttsRate, fallback: 1.0),
            preferEdge: settings.getString(SettingsKeys.ttsEngine, 'edge') != 'system',
          );
    } on TtsException catch (e) {
      AppLogger.warn('improvement replay failed: ${e.error.detail}');
      if (mounted) showAppToast(context, '朗读暂不可用', error: true);
    } finally {
      if (mounted) setState(() => _playingImprovementId = null);
    }
  }

  Future<void> _saveImprovement(String messageId) async {
    await _controller.saveImprovement(messageId);
    ref.invalidate(phrasesProvider);
    if (mounted) showAppToast(context, '已存入表达本');
  }

  Future<void> _playCorrection(Correction correction) async {
    if (_playingCorrectionId == correction.id) {
      await ref.read(ttsRouterProvider).stop();
      if (mounted) setState(() => _playingCorrectionId = null);
      return;
    }
    setState(() => _playingCorrectionId = correction.id);
    try {
      final settings = ref.read(settingsRepositoryProvider);
      await ref.read(ttsRouterProvider).speak(
            correction.improved,
            voice: settings.getString(SettingsKeys.ttsVoice, 'en-US-AriaNeural'),
            rate: settings.getDouble(SettingsKeys.ttsRate, fallback: 1.0),
            preferEdge: settings.getString(SettingsKeys.ttsEngine, 'edge') != 'system',
          );
    } on TtsException catch (e) {
      AppLogger.warn('correction replay failed: ${e.error.detail}');
      if (mounted) showAppToast(context, '朗读暂不可用', error: true);
    } finally {
      if (mounted) setState(() => _playingCorrectionId = null);
    }
  }

  Future<void> _deleteCorrection(Correction correction) async {
    await ref.read(sessionRepositoryProvider).deleteCorrection(correction.id);
    ref.invalidate(correctionsForSessionProvider(widget.sessionId));
    if (mounted) setState(() => _expandedCorrections.remove(correction.messageId));
  }

  Future<void> _end() async {
    if (_ending) return;
    final ok = await showConfirmDialog(
      context,
      title: '结束这次练习？',
      message: '对话会保存到记录里，随后可以查看本次复盘。',
      confirmLabel: '结束并复盘',
    );
    if (!ok || !mounted) return;
    setState(() => _ending = true);
    final session = await _controller.endSession();
    if (!mounted) return;
    _refreshSessions();
    if (session == null) {
      context.go('/home');
      return;
    }
    context.pushReplacement('/review/${session.id}');
  }

  Future<void> _back() async {
    if (_controller.state == TurnState.thinking) {
      showAppToast(context, '正在等待回复，请稍后再退出');
      return;
    }
    final turns = _controller.session?.turnCount ?? 0;
    if (turns == 0) {
      await _controller.deleteDraft();
      _refreshSessions();
      if (mounted) context.pop();
      return;
    }
    final ok = await showConfirmDialog(
      context,
      title: '先存起来，下次接着聊？',
      message: '这 $turns 轮对话会原样保留。下次可从首页「继续上次」、练习记录，或这个场景的详情页接着往下说。',
      confirmLabel: '保存并退出',
    );
    if (!ok || !mounted) return;
    await _controller.pauseSession();
    _refreshSessions();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _ChatHeader(
                title: c.scenario?.titleZh ?? '自由对话',
                subtitle: c.scenario?.titleEn ?? '正在加载…',
                level: c.scenario?.level,
                elapsed: c.elapsedSec,
                ending: _ending,
                onBack: _back,
                onEnd: _end,
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                    boxShadow: AppShadows.sheet,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Expanded(child: _buildMessages(c)),
                      if (c.resumeNotice != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: AppCard(
                            shadow: false,
                            color: AppColors.primaryWash,
                            padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
                            child: Row(
                              children: [
                                const Icon(Icons.play_circle_outline_rounded,
                                    size: 15, color: AppColors.primaryDeep),
                                const SizedBox(width: 8),
                                Expanded(child: Text(c.resumeNotice!, style: AppText.caption)),
                                TextButton(
                                  onPressed: c.dismissResumeNotice,
                                  child: const Text('知道了'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (c.needsReplyRecovery)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: AppCard(
                            shadow: false,
                            color: AppColors.warning.withValues(alpha: 0.10),
                            padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
                            child: Row(
                              children: [
                                const Icon(Icons.reply_rounded, size: 15, color: AppColors.warning),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '上次这句还没等到 AI 回复，点重试接着聊',
                                    style: AppText.caption,
                                  ),
                                ),
                                TextButton(
                                  onPressed: c.retry,
                                  child: Text(
                                    '重试',
                                    style: AppText.caption.copyWith(color: AppColors.primaryDeep),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (c.offline)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: AppCard(
                            shadow: false,
                            color: AppColors.warning.withValues(alpha: 0.12),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            child: Row(
                              children: [
                                const Icon(Icons.wifi_off_rounded, size: 15, color: AppColors.warning),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '网络不可用，发送可能失败，恢复后再试',
                                    style: AppText.caption.copyWith(fontSize: 11.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (c.slowReply)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: AppCard(
                            shadow: false,
                            color: AppColors.primaryWash,
                            padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
                            child: Row(
                              children: [
                                const Icon(Icons.hourglass_bottom_rounded, size: 15, color: AppColors.primaryDeep),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '网络较慢，AI 仍在生成；可继续等待或取消本次',
                                    style: AppText.caption.copyWith(fontSize: 11.5),
                                  ),
                                ),
                                TextButton(onPressed: c.cancelReply, child: const Text('取消')),
                              ],
                            ),
                          ),
                        ),
                      if (c.error != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: ChatErrorBanner(
                            error: c.error!,
                            kind: c.errorKind,
                            onRetry: c.lastFailedText == null ? null : c.retry,
                            onConfig: () => context.push('/settings/model'),
                            onText: () async {
                              if (c.inputMode != 'text') await c.toggleInputMode();
                            },
                          ),
                        ),
                      if (c.canResume)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: AppCard(
                            shadow: false,
                            color: AppColors.primaryWash,
                            padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
                            child: Row(
                              children: [
                                const Icon(Icons.play_circle_outline_rounded,
                                    size: 16, color: AppColors.primaryDeep),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text('播放已暂停，不会自动续播', style: AppText.caption),
                                ),
                                TextButton(
                                  onPressed: c.resumePlayback,
                                  child: Text('继续播放',
                                      style: AppText.caption
                                          .copyWith(color: AppColors.primaryDeep)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (c.routeNotice != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: AppCard(
                            shadow: false,
                            color: AppColors.primaryWash,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            child: Row(
                              children: [
                                const Icon(Icons.headphones_rounded, size: 15, color: AppColors.primaryDeep),
                                const SizedBox(width: 8),
                                Expanded(child: Text(c.routeNotice!, style: AppText.caption)),
                              ],
                            ),
                          ),
                        ),
                      if (c.translationError != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: ErrorBanner(
                            message: c.translationError!,
                            onRetry: c.canRetryTranslation ? c.retryTranslation : null,
                            retryLabel: '重试翻译',
                            onClose: c.clearTranslationError,
                          ),
                        ),
                      if (_hintOpen)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: InlineHintPanel(
                            controller: c,
                            onClose: () {
                              c.closeHint();
                              setState(() => _hintOpen = false);
                            },
                          ),
                        ),
                      if (c.asrNotice != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: AppCard(
                            shadow: false,
                            color: AppColors.primaryWash,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            child: Row(
                              children: [
                                const Icon(Icons.swap_horiz_rounded, size: 15, color: AppColors.primaryDeep),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    c.asrNotice!,
                                    style: AppText.caption.copyWith(fontSize: 11.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (c.ttsWarning != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: AppCard(
                            shadow: false,
                            color: AppColors.warning.withValues(alpha: 0.12),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            child: Row(
                              children: [
                                const Icon(Icons.volume_off_rounded, size: 15, color: AppColors.warning),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    c.ttsWarning!,
                                    style: AppText.caption.copyWith(fontSize: 11.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (c.hasMissingKey)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: AppCard(
                            shadow: false,
                            color: AppColors.primaryWash,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            onTap: () => context.push('/settings/model'),
                            child: Row(
                              children: [
                                const Icon(Icons.key_rounded, size: 16, color: AppColors.primaryDeep),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '配置模型密钥后即可开始对话',
                                    style: AppText.caption.copyWith(fontSize: 12, color: AppColors.primaryDeep),
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primaryDeep),
                              ],
                            ),
                          ),
                        ),
                      _TalkComposer(
                        controller: c,
                        textController: _input,
                        onSend: _send,
                        onHint: _toggleHint,
                        onWantToSay: () => showWantToSaySheet(
                          context,
                          controller: c,
                          onUse: _applyWantToSay,
                        ),
                        onPressure: c.setPressure,
                        onClearPressure: c.clearPressure,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessages(ConversationController c) {
    if (c.loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (c.messages.isEmpty) {
      return const EmptyState(
        icon: Icons.mic_none_rounded,
        title: '开始你的第一句',
        message: '按住下方麦克风说话，或切换到文字输入。',
      );
    }
    final streaming = c.state == TurnState.thinking && c.streamingText.trim().isNotEmpty;
    final corrections = ref.watch(correctionsForSessionProvider(widget.sessionId)).asData?.value ??
        const <Correction>[];
    final byMessage = <String, List<Correction>>{};
    for (final item in corrections.where((e) => !e.isDeleted && e.messageId.isNotEmpty)) {
      byMessage.putIfAbsent(item.messageId, () => <Correction>[]).add(item);
    }
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onScrollNotification,
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      itemCount: c.messages.length + (streaming || c.state == TurnState.thinking ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= c.messages.length) {
          return streaming ? _StreamingBubble(text: c.streamingText) : const _TypingBubble();
        }
        final message = c.messages[index];
        final previous = index == 0 ? null : c.messages[index - 1];
        final showTime = previous == null ||
            DateTime.fromMillisecondsSinceEpoch(message.createdAt)
                    .difference(DateTime.fromMillisecondsSinceEpoch(previous.createdAt))
                    .inMinutes >=
                5;
        return Column(
          children: [
            if (showTime)
              Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 4),
                child: Text(
                  formatDate(DateTime.fromMillisecondsSinceEpoch(message.createdAt)),
                  style: AppText.caption.copyWith(fontSize: 10),
                ),
              ),
            MessageBubble(
              message: message,
              playing: c.playingMessageId == message.id,
              onPlay: message.isUser ? null : () => c.playMessage(message),
              showTranslation: c.showTranslations,
              translation: c.translationOf(message.id),
              translating: c.isTranslating(message.id),
              onTranslate: c.translateMode == 'tap' && !message.isUser
                  ? () => c.translate(message)
                  : null,
              corrections: byMessage[message.id] ?? const <Correction>[],
              correctionsExpanded: _expandedCorrections.contains(message.id),
              onToggleCorrections: () {
                setState(() {
                  if (_expandedCorrections.contains(message.id)) {
                    _expandedCorrections.remove(message.id);
                  } else {
                    _expandedCorrections.add(message.id);
                  }
                });
              },
              playingCorrectionId: _playingCorrectionId,
              onPlayCorrection: _playCorrection,
              onDeleteCorrection: _deleteCorrection,
              trailing: message.isUser
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnswerActionBar(
                            message: message,
                            optimizing: c.improvingMessageId == message.id,
                            optimizationOpen: _openImprovements.contains(message.id),
                            hasOriginal: message.audioPath?.isNotEmpty == true,
                            originalPlaying: c.playingOriginalId == message.id,
                            ttsPlaying: c.playingMessageId == message.id,
                            onOptimize: () => _toggleImprovement(message),
                            onPlayOriginal: () => _playOriginal(message),
                            onPlayTts: () => c.playMessage(message),
                          ),
                          if (_openImprovements.contains(message.id))
                            ImprovementCard(
                              original: message.textEn,
                              improvement: c.improvements[message.id],
                              error: c.improvementError,
                              playing: _playingImprovementId == message.id,
                              onPlay: () => _playImprovement(
                                message.id,
                                c.improvements[message.id]?.improved ?? message.textEn,
                              ),
                              onSave: () => _saveImprovement(message.id),
                              onClose: () {
                                c.closeImprovement(message.id);
                                setState(() => _openImprovements.remove(message.id));
                              },
                              onRetry: () => c.optimizeSentence(message),
                            ),
                        ],
                      ),
                    )
                  : null,
            ),
          ],
        );
          },
        ),
        ),
        Positioned(
          right: 8,
          bottom: 6,
          child: RewardBurst(trigger: _rewardTrigger),
        ),
        if (!_followBottom)
          Positioned(
            left: 0,
            right: 0,
            bottom: 14,
            child: Center(
              child: GestureDetector(
                onTap: _backToLatest,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: AppShadows.soft,
                    border: Border.all(color: AppColors.primaryTint),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: AppColors.primaryDeep,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '回到最新',
                        style: AppText.caption.copyWith(
                          fontSize: 10,
                          color: AppColors.primaryDeep,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.title,
    required this.subtitle,
    required this.level,
    required this.elapsed,
    required this.ending,
    required this.onBack,
    required this.onEnd,
  });

  final String title;
  final String subtitle;
  final String? level;
  final int elapsed;
  final bool ending;
  final VoidCallback onBack;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: AppColors.ink,
            tooltip: '退出',
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: AppText.section,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (level != null) ...[
                      const SizedBox(width: 6),
                      AppTag(label: level!, color: AppColors.primaryDeep),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  '$subtitle · ${formatDuration(elapsed)}',
                  style: AppText.caption.copyWith(fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: ending ? null : onEnd,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryDeep,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: ending
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : Text('结束', style: AppText.caption.copyWith(color: AppColors.primaryDeep, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.showTranslation = false,
    this.translation,
    this.translating = false,
    this.onTranslate,
    this.playing = false,
    this.onPlay,
    this.corrections = const [],
    this.correctionsExpanded = false,
    this.onToggleCorrections,
    this.playingCorrectionId,
    this.onPlayCorrection,
    this.onDeleteCorrection,
    this.trailing,
  });

  final MessageRecord message;
  final bool showTranslation;
  final String? translation;
  final bool translating;
  final VoidCallback? onTranslate;
  final bool playing;
  final VoidCallback? onPlay;
  final List<Correction> corrections;
  final bool correctionsExpanded;
  final VoidCallback? onToggleCorrections;
  final String? playingCorrectionId;
  final ValueChanged<Correction>? onPlayCorrection;
  final ValueChanged<Correction>? onDeleteCorrection;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final hint = message.isHint;
    final bubbleColor = isUser
        ? null
        : hint
            ? AppColors.warning.withValues(alpha: 0.12)
            : AppColors.surfaceTint;
    final showTranslateButton =
        showTranslation && onTranslate != null && translation == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
            _Avatar(isHint: hint),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primaryDeep],
                      )
                    : null,
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 6),
                  bottomRight: Radius.circular(isUser ? 6 : 18),
                ),
                border: hint ? Border.all(color: AppColors.warning.withValues(alpha: 0.35)) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hint)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '提示 L${message.hintLevel ?? 2}',
                        style: AppText.tag.copyWith(color: AppColors.warning),
                      ),
                    ),
                  Text(
                    message.textEn,
                    style: AppText.body.copyWith(
                      color: isUser ? Colors.white : AppColors.ink,
                      height: 1.5,
                    ),
                  ),
                  if (showTranslation && translation != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      translation!,
                      style: AppText.caption.copyWith(
                        color: isUser ? Colors.white.withValues(alpha: 0.78) : AppColors.inkSecondary,
                      ),
                    ),
                  ],
                  if (corrections.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: onToggleCorrections,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            size: 13,
                            color: isUser ? Colors.white : AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${corrections.length} 处可以更好 · ${correctionsExpanded ? '收起' : '点开看'}',
                            style: AppText.caption.copyWith(
                              fontSize: 10,
                              color: isUser ? Colors.white.withValues(alpha: 0.85) : AppColors.inkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (correctionsExpanded && onPlayCorrection != null && onDeleteCorrection != null)
                      CorrectionPanel(
                        corrections: corrections,
                        playingId: playingCorrectionId,
                        onPlay: onPlayCorrection!,
                        onDelete: onDeleteCorrection!,
                      ),
                  ],
                  // 重听靠左、翻译靠右，中间留弹性空白，避免两个按钮挤在一起误触。
                  if (!isUser && (onPlay != null || showTranslateButton))
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (onPlay != null)
                            Semantics(
                              button: true,
                              label: playing ? '停止朗读' : '播放朗读',
                              child: GestureDetector(
                                onTap: onPlay,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: playing
                                        ? AppColors.primaryWash
                                        : Colors.white.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                    border: Border.all(color: AppColors.divider),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        playing ? Icons.stop_rounded : Icons.volume_up_rounded,
                                        size: 13,
                                        color: playing ? AppColors.primaryDeep : AppColors.inkMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        playing ? '停止' : '重听',
                                        style: AppText.caption.copyWith(
                                          fontSize: 10,
                                          color: playing ? AppColors.primaryDeep : AppColors.inkMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (message.latencyMs != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${(message.latencyMs! / 1000).toStringAsFixed(1)}s',
                              style: AppText.caption.copyWith(fontSize: 9, color: AppColors.inkMuted),
                            ),
                          ],
                          if (showTranslateButton) ...[
                            const Spacer(),
                            Semantics(
                              button: true,
                              label: translating ? '正在翻译' : '翻译这句话',
                              child: GestureDetector(
                                onTap: translating ? null : onTranslate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: translating
                                        ? AppColors.primaryWash
                                        : Colors.white.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                    border: Border.all(color: AppColors.divider),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.translate_rounded,
                                        size: 13,
                                        color: translating ? AppColors.primaryDeep : AppColors.inkMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        translating ? '翻译中…' : '中文',
                                        style: AppText.caption.copyWith(
                                          fontSize: 10,
                                          color: translating ? AppColors.primaryDeep : AppColors.inkMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
              if (isUser) const SizedBox(width: 4),
            ],
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.isHint});

  final bool isHint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isHint ? AppColors.warning.withValues(alpha: 0.18) : AppColors.primaryWash,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isHint ? Icons.lightbulb_outline_rounded : Icons.auto_awesome_rounded,
        size: 16,
        color: isHint ? AppColors.warning : AppColors.primaryDeep,
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const _Avatar(isHint: false),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: const TypingDots(),
          ),
        ],
      ),
    );
  }
}

class _StreamingBubble extends StatelessWidget {
  const _StreamingBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Avatar(isHint: false),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
              decoration: const BoxDecoration(
                color: AppColors.surfaceTint,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Text(
                text,
                style: AppText.body.copyWith(height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TalkComposer extends StatelessWidget {
  const _TalkComposer({
    required this.controller,
    required this.textController,
    required this.onSend,
    required this.onHint,
    required this.onWantToSay,
    required this.onPressure,
    required this.onClearPressure,
  });

  final ConversationController controller;
  final TextEditingController textController;
  final VoidCallback onSend;
  final VoidCallback onHint;
  final VoidCallback onWantToSay;
  final ValueChanged<String> onPressure;
  final VoidCallback onClearPressure;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final voiceMode = c.inputMode == 'voice';
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _ModeChip(
                  icon: voiceMode ? Icons.keyboard_alt_outlined : Icons.mic_none_rounded,
                  label: voiceMode ? '文字输入' : '语音输入',
                  onTap: c.toggleInputMode,
                ),
                const SizedBox(width: 6),
                _ModeChip(
                  icon: Icons.lightbulb_outline_rounded,
                  label: '提示',
                  onTap: onHint,
                ),
                const SizedBox(width: 6),
                _ModeChip(
                  icon: Icons.help_outline_rounded,
                  label: '我想说',
                  onTap: onWantToSay,
                ),
                const Spacer(),
                if (c.state == TurnState.speaking)
                  TextButton.icon(
                    onPressed: c.stopPlayback,
                    icon: const Icon(Icons.stop_circle_outlined, size: 15),
                    label: Text(
                      '停止朗读',
                      style: AppText.caption.copyWith(fontSize: 11, color: AppColors.primaryDeep),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryDeep,
                      minimumSize: const Size(0, 28),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                else
                  Flexible(
                    child: Text(
                      c.asrChecking ? '检测识别…' : c.asrProviderLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(fontSize: 10, color: AppColors.inkMuted),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            TranslateModePicker(
              mode: c.translateMode,
              onChanged: (mode) => c.setTranslateMode(mode),
            ),
            if (c.learnerProfileEnabled) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  for (final entry in kPressureOptions.entries) ...[
                    _ModeChip(
                      icon: entry.key == 'angle'
                          ? Icons.alt_route_rounded
                          : Icons.trending_up_rounded,
                      label: entry.value,
                      onTap: () => onPressure(entry.key),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      c.pendingPressureLabel == null
                          ? '只影响下一回合，不会自动发送'
                          : '下一回合：${c.pendingPressureLabel}（可取消）',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(
                        fontSize: 10,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ),
                  if (c.pendingPressureLabel != null)
                    TextButton(
                      onPressed: onClearPressure,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 28),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '取消',
                        style: AppText.caption.copyWith(
                          fontSize: 10,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            if (voiceMode) _TalkZone(controller: c) else _TextRow(
              controller: textController,
              sending: c.state == TurnState.thinking,
              onSend: onSend,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceTint,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: AppColors.inkSecondary),
              const SizedBox(width: 5),
              Text(label, style: AppText.caption.copyWith(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TalkZone extends StatelessWidget {
  const _TalkZone({required this.controller});

  final ConversationController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final recording = c.state == TurnState.recording;
    final busy = c.state == TurnState.thinking || c.state == TurnState.transcribing;
    final hint = c.state == TurnState.transcribing
        ? '正在识别…'
        : recording
            ? '松开发送 · ${_formatMs(c.recordingMs)}'
            : (c.partialTranscript?.isNotEmpty == true && c.state == TurnState.recording)
                ? c.partialTranscript!
                : c.stateLabel;
    return Column(
      children: [
        SizedBox(
          height: 26,
          child: recording ? const _Waveform() : null,
        ),
        const SizedBox(height: 2),
        _MicButton(controller: c, recording: recording, busy: busy),
        const SizedBox(height: 6),
        Text(
          hint,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.caption.copyWith(
            fontSize: 11,
            color: recording ? AppColors.error : AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: 2),
      ],
    );
  }

  static String _formatMs(int ms) {
    final seconds = (ms / 1000).clamp(0, 30);
    final whole = seconds.floor();
    final tenth = ((seconds - whole) * 10).floor();
    return '0:${whole.toString().padLeft(2, '0')}.$tenth';
  }
}

class _MicButton extends StatefulWidget {
  const _MicButton({
    required this.controller,
    required this.recording,
    required this.busy,
  });

  final ConversationController controller;
  final bool recording;
  final bool busy;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton> {
  bool _cancelled = false;
  double _dragUp = 0;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final recording = c.state == TurnState.recording;
    return Semantics(
      button: true,
      label: recording ? '松开发送' : '按住说话',
      onTap: widget.busy
          ? null
          : () {
              if (c.state == TurnState.recording) {
                _cancelled = false;
                c.stopRecording();
              } else {
                c.startRecording();
              }
            },
      child: Listener(
        onPointerDown: widget.busy
            ? null
            : (_) {
                _cancelled = false;
                _dragUp = 0;
                c.startRecording();
              },
        onPointerMove: widget.busy
            ? null
            : (event) {
                if (c.state != TurnState.recording || _cancelled) return;
                _dragUp -= event.delta.dy;
                if (_dragUp > 60) {
                  _cancelled = true;
                  c.cancelRecording();
                }
              },
        onPointerUp: widget.busy
            ? null
            : (_) {
                if (_cancelled) return;
                if (c.state == TurnState.recording) c.stopRecording();
              },
        onPointerCancel: widget.busy
            ? null
            : (_) {
                if (c.state == TurnState.recording) c.cancelRecording();
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.recording
                  ? const [Color(0xFFFF8E92), AppColors.error]
                  : widget.busy
                      ? [AppColors.inkMuted, AppColors.inkMuted]
                      : [AppColors.primary, AppColors.primaryDeep],
            ),
            shape: BoxShape.circle,
            boxShadow: widget.busy ? null : AppShadows.primary,
          ),
          child: Icon(
            widget.busy ? Icons.hourglass_empty_rounded : Icons.mic_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}

/// 录音波形：仅表示"正在采集"，不依赖真实振幅（Web 与 Android 机型差异大）。
class _Waveform extends StatefulWidget {
  const _Waveform();

  @override
  State<_Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<_Waveform> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(9, (index) {
            final phase = _controller.value * math.pi * 2 + index * 0.45;
            final height = 6 + (math.sin(phase).abs() * 12);
            return Container(
              width: 3,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

class _TextRow extends StatelessWidget {
  const _TextRow({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSend(),
            style: AppText.body,
            decoration: InputDecoration(
              hintText: '用英文输入你想说的话…',
              hintStyle: AppText.bodySecondary.copyWith(color: AppColors.inkMuted, fontSize: 13),
              filled: true,
              fillColor: AppColors.surfaceTint,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          button: true,
          label: '发送',
          child: GestureDetector(
            onTap: sending ? null : onSend,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: sending
                    ? null
                    : const LinearGradient(colors: [AppColors.primary, AppColors.primaryDeep]),
                color: sending ? AppColors.inkMuted.withValues(alpha: 0.4) : null,
                shape: BoxShape.circle,
                boxShadow: sending ? null : AppShadows.primary,
              ),
              child: sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}

/// 供后续里程碑复用的错误文案映射。
String chatErrorText(Object error) => '请求失败：$error';
