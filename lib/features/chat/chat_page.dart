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
import '../../domain/models/models.dart';
import 'conversation_controller.dart';

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
  }

  void _onUpdate() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onUpdate)
      ..dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    await _controller.sendText(text);
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
    ref.invalidate(homeDataProvider);
    ref.invalidate(recentSessionsProvider);
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
      if (mounted) context.pop();
      return;
    }
    final ok = await showConfirmDialog(
      context,
      title: '退出练习？',
      message: '本次对话会保存为草稿，可以在练习记录里继续查看。',
      confirmLabel: '保存并退出',
    );
    if (!ok || !mounted) return;
    await _controller.endSession();
    ref.invalidate(homeDataProvider);
    ref.invalidate(recentSessionsProvider);
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
                          child: ErrorBanner(
                            message: c.error!,
                            onRetry: c.lastFailedText == null ? null : c.retry,
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
    return ListView.builder(
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
            ),
          ],
        );
      },
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
    this.playing = false,
    this.onPlay,
  });

  final MessageRecord message;
  final bool showTranslation;
  final bool playing;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final hint = message.isHint;
    final bubbleColor = isUser
        ? null
        : hint
            ? AppColors.warning.withValues(alpha: 0.12)
            : AppColors.surfaceTint;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
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
                  if (showTranslation && message.textZh != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      message.textZh!,
                      style: AppText.caption.copyWith(
                        color: isUser ? Colors.white.withValues(alpha: 0.78) : AppColors.inkSecondary,
                      ),
                    ),
                  ],
                  if (!isUser && onPlay != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
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
  });

  final ConversationController controller;
  final TextEditingController textController;
  final VoidCallback onSend;

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
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                else
                  Text(
                    c.asrChecking ? '正在检测语音识别…' : c.asrProviderLabel,
                    style: AppText.caption.copyWith(fontSize: 10, color: AppColors.inkMuted),
                  ),
              ],
            ),
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
