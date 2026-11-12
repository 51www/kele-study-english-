import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/foundation.dart';

import '../../core/errors.dart';
import '../../core/logger.dart';
import '../../core/timeouts.dart';
import '../../data/repositories/repositories.dart';
import '../../data/secure/key_store.dart';
import '../../domain/models/models.dart';
import '../../services/asr/asr_engine.dart';
import '../../services/asr/chat_audio_asr_engine.dart';
import '../../services/asr/http_asr_engine.dart';
import '../../services/asr/system_asr_engine.dart';
import '../../services/audio/audio_player.dart';
import '../../services/audio/audio_recorder.dart';
import '../../services/audio/audio_session_manager.dart';
import '../../services/llm/cost_estimator.dart';
import '../../services/llm/llm_client.dart';
import '../../services/llm/llm_models.dart';
import '../../services/llm/prompt_builder.dart';
import '../../services/tts/tts_engine.dart';
import '../../services/tts/tts_router.dart';

/// 回合状态机：空闲 / 录音 / 识别 / 思考 / 朗读 / 错误。
enum TurnState { idle, recording, transcribing, thinking, speaking, error }

/// 「优化句子」的旁路结果，只放在内存里，不写主对话历史。
class SentenceImprovement {
  const SentenceImprovement({required this.improved, required this.reasonZh});

  final String improved;
  final String reasonZh;
}

class ConversationController extends ChangeNotifier {
  ConversationController({
    required this.sessionId,
    required this.sessions,
    required this.scenarios,
    required this.settings,
    required this.llmClient,
    required this.profiles,
    required this.keyStore,
    required this.asr,
    required this.recorder,
    required this.player,
    required this.audioSession,
    required this.tts,
  });

  final String sessionId;
  final SessionRepository sessions;
  final ScenarioRepository scenarios;
  final SettingsRepository settings;
  final LlmClient llmClient;
  final LlmProfileRepository profiles;
  final KeyStore keyStore;
  final SystemAsrEngine asr;
  final AudioRecorderService recorder;
  final AudioPlayerService player;
  final AudioSessionManager audioSession;
  final TtsRouter tts;

  SessionRecord? session;
  Scenario? scenario;
  List<MessageRecord> messages = [];
  TurnState state = TurnState.idle;
  String streamingText = '';
  String? error;
  String? lastFailedText;
  String? ttsWarning;
  String? asrNotice;
  String? playingMessageId;
  String? playingOriginalId;
  bool loading = true;
  bool asrAvailable = false;
  bool asrChecking = true;
  bool slowReply = false;
  bool offline = false;
  String inputMode = 'voice';
  int elapsedSec = 0;
  int recordingMs = 0;

  /// 翻译三态：off（默认，不显示中文）/ tap（点气泡）/ always（常开字幕）。
  String translateMode = 'off';
  String? translationError;

  /// 提示结果只放内存，不写主对话历史，也绝不自动发送。
  /// `hintTextZh` 常规由同一次旁路请求返回；模型不按格式输出时才补一次翻译。
  int? hintLevel;
  String? hintText;
  String? hintTextZh;
  String? hintError;
  bool hintLoading = false;

  /// 「我想说」：中文 → 一句英文建议，用户必须自己按下说话或发送。
  String? wantToSayText;
  String? wantToSayError;
  bool wantToSayLoading = false;

  /// 用户回答句下方的「优化句子」：按 messageId 缓存，展开/收起由页面控制。
  final Map<String, SentenceImprovement> improvements = {};
  String? improvingMessageId;
  String? improvementError;

  double sessionCost = 0;
  bool costEstimated = false;
  AppErrorKind? errorKind;
  String? resumeText;
  String? routeNotice;

  /// 续练：从已有会话重新进入时的提示，以及「最后一句没等到回复」的恢复态。
  bool resuming = false;
  String? resumeNotice;
  bool needsReplyRecovery = false;

  final Map<String, String> _translations = {};
  final Set<String> _translating = {};
  String? _failedTranslationId;
  String? _currentSpokenText;
  bool _inReply = false;
  bool _ttsWarned = false;

  Timer? _ticker;
  Timer? _recordTicker;
  Timer? _slowTimer;
  CancelToken? _cancelToken;
  CancelToken? _streamToken;
  StreamSubscription<List<ConnectivityResult>>? _netSub;
  DateTime? _recordStartedAt;
  DateTime? _turnStartedAt;
  int? _firstAudioMs;
  int? _firstTokenMs;
  int? _asrMs;
  bool _usingAsr = false;
  bool _usingHttpAsr = false;
  bool _usingChatAudio = false;
  HttpAsrEngine? _httpAsr;
  ChatAudioAsrEngine? _chatAudioAsr;
  String _asrMode = 'system';
  bool _disposed = false;
  bool _finished = false;
  bool _deleted = false;
  String? _missingKeyMessage;
  String _voice = 'en-US-AriaNeural';
  double _rate = 1.0;
  bool _autoPlay = true;
  bool _preferEdge = true;
  String? _partialTranscript;

  Future<void> _speakQueue = Future.value();
  int _ttsToken = 0;

  bool get hasMissingKey => _missingKeyMessage != null;
  bool get sending => state == TurnState.thinking || state == TurnState.speaking;
  String get asrProviderLabel {
    if (!asrAvailable) return '语音识别不可用';
    switch (_asrMode) {
      case 'http':
        return '语音识别可用（接口）';
      case 'chatAudio':
        return '语音识别可用（实验）';
      default:
        return '语音识别可用（系统）';
    }
  }
  bool get recording => state == TurnState.recording;
  bool get isSpeaking => state == TurnState.speaking;
  String? get partialTranscript => _partialTranscript;
  bool get canResume => resumeText != null && resumeText!.isNotEmpty;
  bool get showTranslations => translateMode != 'off';
  String? translationOf(String messageId) => _translations[messageId];
  bool isTranslating(String messageId) => _translating.contains(messageId);
  bool get canRetryTranslation => _failedTranslationId != null;
  bool get hasHint => hintText != null && hintText!.isNotEmpty;
  String? get synthesizedCostLabel =>
      sessionCost > 0 ? '${CostEstimator.format(sessionCost)}${costEstimated ? '（估算）' : ''}' : null;

  String get stateLabel {
    switch (state) {
      case TurnState.idle:
        return '按住说话 · 松开发送';
      case TurnState.recording:
        return '松开发送，上滑取消';
      case TurnState.transcribing:
        return '正在识别…';
      case TurnState.thinking:
        return 'AI 正在回复…';
      case TurnState.speaking:
        return '正在朗读…';
      case TurnState.error:
        return '本回合没有完成，可以重试或改用文字';
    }
  }

  Future<void> init() async {
    try {
      session = await sessions.byId(sessionId);
      if (session == null) {
        error = '练习记录不存在';
        loading = false;
        notifyListeners();
        return;
      }
      final restored = session!;
      scenario = await scenarios.byId(restored.scenarioId ?? '');
      messages = await sessions.messages(sessionId);
      // 重新进入对话页即视为「继续」：除开场白外还有消息，就说明是接着上次聊。
      resuming = messages.length > 1;
      session = await sessions.resumeSession(restored);
      sessionCost = session!.costEstimate ?? 0;
      for (final message in messages) {
        if (message.textZh != null && message.textZh!.isNotEmpty) {
          _translations[message.id] = message.textZh!;
        }
      }
      // 时长取累计秒数；旧数据没落过盘时用「首条→末条消息」的跨度推断，
      // 不用 started_at 到现在的墙钟差（会把几小时前开的会话算成几小时）。
      final span = messages.length > 1
          ? ((messages.last.createdAt - messages.first.createdAt) / 1000).round()
          : 0;
      elapsedSec = restored.durationSec > 0
          ? restored.durationSec
          : span.clamp(0, 1800);
      if (resuming) {
        resumeNotice = '已接上上次的对话（${session!.turnCount} 轮），接着说就行';
      }
      // 上次退出时最后一句用户消息可能没等到 AI 回复，交给用户显式点「重试」。
      if (messages.isNotEmpty && messages.last.isUser) {
        lastFailedText = messages.last.textEn;
        needsReplyRecovery = true;
      }
      _startTicker();
      await settings.load();
      _readSettings();
      final profile = await profiles.loadOrCreate();
      final key = await keyStore.read(profile.keyRef);
      if (key == null || key.isEmpty) {
        _missingKeyMessage = '还没有配置模型密钥，请先到「我的 → 模型配置」填写。';
      }
      await audioSession.enterConversation();
      audioSession.onInterrupted = _handleInterrupted;
      audioSession.onDeviceDisconnected = _handleDeviceDisconnected;
      audioSession.onDeviceChanged = _handleDeviceChanged;
      tts.resetCircuit();
      _ttsWarned = false;
      await tts.disk?.load();
      tts.onPlaybackStart = _markFirstAudio;
      _listenNetwork();
      loading = false;
      notifyListeners();
      _checkAsr();
      _autoPlayOpening();
    } catch (e, s) {
      AppLogger.error('conversation init failed', e, s);
      error = '加载练习失败：$e';
      loading = false;
      notifyListeners();
    }
  }

  void _readSettings() {
    inputMode = settings.getString(SettingsKeys.inputMode, 'voice');
    if (inputMode != 'text' && inputMode != 'voice') inputMode = 'voice';
    _voice = settings.getString(SettingsKeys.ttsVoice, 'en-US-AriaNeural');
    _rate = settings.getDouble(SettingsKeys.ttsRate, fallback: 1.0).clamp(0.7, 1.3).toDouble();
    _autoPlay = settings.getBool(SettingsKeys.ttsAutoPlay, fallback: true);
    _preferEdge = settings.getString(SettingsKeys.ttsEngine, 'edge') != 'system';
    final configured = settings.getString(SettingsKeys.translateDefault, 'off');
    translateMode = switch (configured) {
      'tap' => 'tap',
      'always' || 'on' => 'always',
      _ => 'off',
    };
  }

  /// 「松手 → 首音」：只在音频真正开始播放时打点，不含合成排队时间。
  void _markFirstAudio() {
    if (!_inReply || _turnStartedAt == null || _firstAudioMs != null) return;
    _firstAudioMs = DateTime.now().difference(_turnStartedAt!).inMilliseconds;
  }

  Future<void> _checkAsr() async {
    asrChecking = true;
    notifyListeners();
    final base = settings.getString(SettingsKeys.asrBaseUrl, 'https://api.siliconflow.cn/v1');
    final model = settings.getString(SettingsKeys.asrModel, 'FunAudioLLM/SenseVoiceSmall');
    final key = await keyStore.read(SettingsKeys.asrKeyRef);
    final language = settings.getString(SettingsKeys.asrLanguage, 'en');

    // 实验引擎（默认关闭）：用对话模型做识别，作为最后兜底。
    _chatAudioAsr = null;
    final experimentalOn =
        settings.getString(SettingsKeys.asrExperimentalEnabled, 'false') == 'true';
    if (experimentalOn) {
      final profile = await profiles.loadOrCreate();
      final expKey = await keyStore.read(SettingsKeys.asrExperimentalKeyRef) ??
          await keyStore.read(profile.keyRef);
      if (expKey != null && expKey.isNotEmpty) {
        _chatAudioAsr = ChatAudioAsrEngine(
          config: AsrConfig(
            baseUrl: settings.getString(
              SettingsKeys.asrExperimentalBaseUrl,
              'https://aiping.cn/api/v1',
            ),
            apiKey: expKey,
            model: settings.getString(SettingsKeys.asrExperimentalModel, 'MiMo-V2.6-Flash'),
            language: language,
          ),
          recorder: recorder,
        );
        await _chatAudioAsr!.initialize();
      }
    }

    if (base.isNotEmpty && model.isNotEmpty && key != null && key.isNotEmpty) {
      // 已配置独立识别接口：优先走 HTTP 识别。
      _httpAsr = HttpAsrEngine(
        config: AsrConfig(baseUrl: base, apiKey: key, model: model, language: language),
        recorder: recorder,
      );
      asrAvailable = await _httpAsr!.initialize();
      _asrMode = 'http';
    } else if (_chatAudioAsr != null) {
      // 未配置识别接口但显式开启了实验开关：用对话模型识别。
      _httpAsr = null;
      _asrMode = 'chatAudio';
      asrAvailable = _chatAudioAsr!.available;
    } else {
      // 未配置识别接口：退回系统识别。
      _httpAsr = null;
      _asrMode = 'system';
      asrAvailable = await asr.initialize();
    }
    asrChecking = false;
    AppLogger.debug('asr mode=$_asrMode available=$asrAvailable experimental=${_chatAudioAsr != null}');
    notifyListeners();
  }

  void _autoPlayOpening() {
    if (!_autoPlay || messages.isEmpty) return;
    final last = messages.last;
    if (last.isUser) return;
    // 只在开场白（会话首条）时自动朗读，避免回看旧会话时突然出声。
    if (messages.length == 1) {
      unawaited(playMessage(last));
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    var ticks = 0;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSec++;
      // 进程被杀也能保住已练时长与进度，每 15 秒落一次盘。
      if (++ticks % 15 == 0) unawaited(_persistElapsed());
      notifyListeners();
    });
  }

  Future<void> _persistElapsed() async {
    final current = session;
    if (_disposed || _finished || _deleted || current == null) return;
    session = current.copyWith(durationSec: elapsedSec);
    await sessions.saveSession(session!);
  }

  Future<LlmConfig> _config() async {
    final profile = await profiles.loadOrCreate();
    final key = await keyStore.read(profile.keyRef);
    if (key == null || key.isEmpty) {
      throw const AppError(
        kind: AppErrorKind.config,
        detail: '还没有配置模型密钥，请先到「我的 → 模型配置」填写。',
      );
    }
    _missingKeyMessage = null;
    return LlmConfig(baseUrl: profile.baseUrl, apiKey: key, model: profile.model);
  }

  // ---------------------------------------------------------------- 录音

  Future<void> startRecording() async {
    if (state == TurnState.recording || state == TurnState.transcribing) return;
    if (state == TurnState.thinking) return;
    await stopPlayback();
    error = null;
    errorKind = null;
    ttsWarning = null;
    asrNotice = null;
    routeNotice = null;
    resumeText = null;
    _partialTranscript = null;
    _recordStartedAt = DateTime.now();
    _turnStartedAt = DateTime.now();
    _firstAudioMs = null;
    recordingMs = 0;
    state = TurnState.recording;
    notifyListeners();
    _recordTicker?.cancel();
    _recordTicker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (_recordStartedAt == null) return;
      recordingMs = DateTime.now().difference(_recordStartedAt!).inMilliseconds;
      if (recordingMs >= 30000) {
        unawaited(stopRecording());
      } else {
        notifyListeners();
      }
    });

    try {
      await audioSession.prepareRecording();
      await audioSession.activate();
      _usingHttpAsr = false;
      _usingAsr = false;
      _usingChatAudio = false;
      if (_asrMode == 'http' && _httpAsr != null) {
        await _httpAsr!.start();
        _usingHttpAsr = true;
      } else if (_asrMode == 'chatAudio' && _chatAudioAsr != null) {
        await _chatAudioAsr!.start();
        _usingChatAudio = true;
      } else if (asrAvailable) {
        await asr.start();
        asr.onPartial = (text) {
          _partialTranscript = text;
          if (!_disposed) notifyListeners();
        };
        _usingAsr = true;
      } else {
        final granted = await recorder.hasPermission();
        if (!granted) {
          throw const AsrException(
            AppError(kind: AppErrorKind.permission, detail: '麦克风权限被拒绝'),
          );
        }
        await recorder.start();
      }
    } on AsrException catch (e) {
      await _failRecording(e.error);
    } catch (e) {
      await _failRecording(
        AppError(kind: AppErrorKind.audio, detail: '录音启动失败：$e'),
      );
    }
  }

  Future<void> _failRecording(AppError appError) async {
    _recordTicker?.cancel();
    _recordStartedAt = null;
    recordingMs = 0;
    await asr.cancel();
    await _httpAsr?.cancel();
    await _chatAudioAsr?.cancel();
    await recorder.cancel();
    error = appError.detail ?? '录音失败';
    errorKind = appError.kind;
    state = TurnState.error;
    // 麦克风不可用时自动切换到文字输入，会话不中断。
    inputMode = 'text';
    unawaited(settings.set(SettingsKeys.inputMode, 'text'));
    notifyListeners();
  }

  /// 松手：结束录音并进入识别。
  Future<void> stopRecording() async {
    if (state != TurnState.recording) return;
    final started = _recordStartedAt;
    _recordTicker?.cancel();
    final durationMs =
        started == null ? 0 : DateTime.now().difference(started).inMilliseconds;
    _recordStartedAt = null;
    if (durationMs < 400) {
      // 误触：直接回空闲，不产生回合。
      await asr.cancel();
      await recorder.cancel();
      state = TurnState.idle;
      recordingMs = 0;
      notifyListeners();
      return;
    }

    state = TurnState.transcribing;
    notifyListeners();
    final releaseAt = DateTime.now();
    String transcript = '';
    String? recordedPath;
    try {
      if (_usingHttpAsr && _httpAsr != null) {
        final path = await _httpAsr!.stopCapture();
        recordedPath = path;
        if (path == null || path.isEmpty) {
          transcript = '';
        } else {
          try {
            transcript = await _httpAsr!.transcribe(path).timeout(Timeouts.asrHttp);
          } on AsrException catch (e) {
            // 接口失败（额度/网络/格式）时，若开启了实验引擎，用同一段音频再试一次。
            final fallback = _chatAudioAsr;
            if (fallback == null) rethrow;
            asrNotice = '识别接口不可用（${e.error.detail}），已改用实验引擎重试';
            notifyListeners();
            transcript = await fallback.transcribe(path).timeout(Timeouts.asrExperimental);
            _asrMode = 'chatAudio';
          }
        }
      } else if (_usingChatAudio && _chatAudioAsr != null) {
        recordedPath = await _chatAudioAsr!.stopCapture();
        if (recordedPath != null && recordedPath.isNotEmpty) {
          transcript = await _chatAudioAsr!.transcribe(recordedPath).timeout(
            Timeouts.asrExperimental,
            onTimeout: () => '',
          );
        }
      } else if (_usingAsr) {
        // 系统识别独占麦克风，没有可回放的录音文件；该句只保留文字。
        transcript = await asr.stop().timeout(
          Timeouts.asrSystem,
          onTimeout: () => '',
        );
      } else {
        recordedPath = await recorder.stop();
      }
    } on AsrException catch (e) {
      await _failRecording(e.error);
      return;
    } catch (e) {
      AppLogger.warn('stop recording failed: $e');
    }

    if (transcript.isEmpty) {
      error = (_usingAsr || _usingHttpAsr || _usingChatAudio)
          ? '没听清，再说一次？'
          : '当前设备不支持语音识别，已切换到文字输入';
      errorKind = AppErrorKind.audio;
      state = TurnState.error;
      if (!_usingAsr && !_usingHttpAsr && !_usingChatAudio) {
        inputMode = 'text';
        unawaited(settings.set(SettingsKeys.inputMode, 'text'));
      }
      notifyListeners();
      return;
    }

    _asrMs = DateTime.now().difference(releaseAt).inMilliseconds;
    AppLogger.debug('latency asr=${_asrMs}ms mode=$_asrMode');

    await sendText(
      transcript,
      asrProvider: _usingAsr
          ? asr.provider
          : _usingHttpAsr
              ? _httpAsr?.provider
              : _usingChatAudio
                  ? _chatAudioAsr?.provider
                  : null,
      fromVoice: true,
      asrMs: _asrMs,
      audioPath: recordedPath,
    );
  }

  Future<void> cancelRecording() async {
    if (state != TurnState.recording) return;
    _recordTicker?.cancel();
    _recordStartedAt = null;
    recordingMs = 0;
    await asr.cancel();
    await _httpAsr?.cancel();
    await _chatAudioAsr?.cancel();
    await recorder.cancel();
    state = TurnState.idle;
    notifyListeners();
  }

  Future<void> toggleInputMode() async {
    if (state == TurnState.recording) await cancelRecording();
    inputMode = inputMode == 'voice' ? 'text' : 'voice';
    await settings.set(SettingsKeys.inputMode, inputMode);
    notifyListeners();
  }

  // ---------------------------------------------------------------- 对话

  Future<void> sendText(
    String text, {
    String? asrProvider,
    bool fromVoice = false,
    int? asrMs,
    String? audioPath,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    if (state == TurnState.thinking) return;
    if (state == TurnState.speaking) await stopPlayback();
    final current = session;
    final currentScenario = scenario;
    if (current == null || currentScenario == null) return;

    error = null;
    errorKind = null;
    ttsWarning = null;
    translationError = null;
    hintText = null;
    hintTextZh = null;
    hintError = null;
    hintLevel = null;
    wantToSayText = null;
    wantToSayError = null;
    resumeText = null;
    needsReplyRecovery = false;
    _turnStartedAt = DateTime.now();
    _firstAudioMs = null;
    _firstTokenMs = null;
    final seq = messages.isEmpty ? 1 : messages.last.seq + 1;
    final userMessage = MessageRecord(
      id: 'm_${DateTime.now().microsecondsSinceEpoch}_u',
      sessionId: sessionId,
      seq: seq,
      role: 'user',
      textEn: clean,
      audioPath: audioPath,
      asrProvider: asrProvider,
      latencyMs: asrMs,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    messages = [...messages, userMessage];
    lastFailedText = clean;
    state = TurnState.thinking;
    streamingText = '';
    notifyListeners();
    await sessions.saveMessage(userMessage);

    final userTurns = messages.where((m) => m.role == 'user').length;
    session = current.copyWith(
      turnCount: userTurns,
      status: 'in_progress',
      modelName: (await profiles.loadOrCreate()).model,
    );
    await sessions.saveSession(session!);
    notifyListeners();

    await _requestReply();
  }

  Future<void> retry() async {
    if (state == TurnState.thinking) return;
    error = null;
    errorKind = null;
    ttsWarning = null;
    needsReplyRecovery = false;
    _turnStartedAt = DateTime.now();
    _firstAudioMs = null;
    state = TurnState.thinking;
    streamingText = '';
    notifyListeners();
    await _requestReply();
  }

  Future<void> _requestReply() async {
    final currentScenario = scenario;
    if (currentScenario == null) return;
    final watch = Stopwatch()..start();
    final token = CancelToken();
    _cancelToken = token;
    _firstTokenMs = null;
    _inReply = true;
    _startSlowTimer();
    String full = '';
    var usedStream = false;
    LlmUsage? usage;
    try {
      final config = await _config();
      final history = PromptBuilder.chatMessages(
        scenario: currentScenario,
        level: settings.getString(SettingsKeys.level, 'B1'),
        history: messages,
      );
      final promptChars = history.fold<int>(0, (sum, m) => sum + m.content.length);

      final streamed = await _consumeStream(config, history, watch, (delta) {
        full += delta;
        streamingText = full;
        notifyListeners();
      });
      usedStream = streamed;
      if (!streamed) {
        // 6 秒没有首字：转非流式请求。
        AppLogger.debug('stream first-token timeout, fallback to non-stream');
        final reply = await llmClient.chat(
          config,
          history,
          maxTokens: 700,
          cancelToken: token,
        );
        full = reply.text;
        usage = reply.usage;
        streamingText = '';
      }
      watch.stop();
      _slowTimer?.cancel();
      slowReply = false;
      if (full.trim().isEmpty) {
        throw const AppError(
          kind: AppErrorKind.server,
          detail: '模型没有返回内容，请重试',
          retryable: true,
        );
      }
      streamingText = '';
      final seq = messages.isEmpty ? 1 : messages.last.seq + 1;
      final assistant = MessageRecord(
        id: 'm_${DateTime.now().microsecondsSinceEpoch}_a',
        sessionId: sessionId,
        seq: seq,
        role: 'assistant',
        textEn: full.trim(),
        latencyMs: _firstAudioMs ?? _firstTokenMs ?? (usedStream ? watch.elapsedMilliseconds : null),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      messages = [...messages, assistant];
      await sessions.saveMessage(assistant);
      final current = session;
      if (current != null) {
        session = current.copyWith(modelName: config.model);
        await sessions.saveSession(session!);
      }
      error = null;
      errorKind = null;
      lastFailedText = null;
      notifyListeners();

      await _accumulateCost(promptChars: promptChars, output: full, usage: usage);
      if (translateMode == 'always') unawaited(translate(assistant));

      await _speakQueue;
      if (_firstAudioMs != null && assistant.latencyMs != _firstAudioMs) {
        final updated = assistant.copyWith(latencyMs: _firstAudioMs);
        final index = messages.indexWhere((e) => e.id == assistant.id);
        if (index >= 0) {
          final next = [...messages];
          next[index] = updated;
          messages = next;
        }
        await sessions.saveMessage(updated);
      }
      await _recordLatency();
      AppLogger.debug(
        'latency turn asr=${_asrMs ?? '-'}ms firstToken=${_firstTokenMs ?? '-'}ms '
        'firstAudio=${_firstAudioMs ?? '-'}ms total=${watch.elapsedMilliseconds}ms',
      );
      if (!_disposed &&
          (state == TurnState.thinking ||
              (state == TurnState.speaking && playingMessageId == null))) {
        state = TurnState.idle;
        notifyListeners();
      }
    } on AppError catch (e) {
      _slowTimer?.cancel();
      slowReply = false;
      if (token.isCancelled || e.detail == '已取消本次请求') {
        AppLogger.debug('reply canceled by user');
        streamingText = '';
        if (!_disposed) {
          state = TurnState.idle;
          error = null;
          notifyListeners();
        }
        return;
      }
      AppLogger.warn('conversation reply failed: ${e.debugLabel} ${e.detail}');
      await _failTurn(e);
    } catch (e, s) {
      _slowTimer?.cancel();
      slowReply = false;
      AppLogger.error('conversation reply unknown error', e, s);
      await _failTurn(
        AppError(kind: AppErrorKind.server, detail: '回复失败：$e', retryable: true),
      );
    } finally {
      watch.stop();
      _inReply = false;
      if (_cancelToken == token) _cancelToken = null;
    }
  }

  /// 15 秒仍无首字时给出可操作提示（弱网 / 模型慢）。
  void _startSlowTimer() {
    _slowTimer?.cancel();
    slowReply = false;
    _slowTimer = Timer(Timeouts.slowNotice, () {
      if (_disposed) return;
      if (state == TurnState.thinking && _firstTokenMs == null) {
        slowReply = true;
        AppLogger.warn('llm slow: no first token after 15s');
        notifyListeners();
      }
    });
  }

  /// 取消当前等待中的回复。
  Future<void> cancelReply() async {
    if (state != TurnState.thinking) return;
    _streamToken?.cancel('user canceled');
    _streamToken = null;
    _cancelToken?.cancel('user canceled');
    _cancelToken = null;
    _slowTimer?.cancel();
    slowReply = false;
    _ttsToken++;
    try {
      await tts.stop();
    } catch (_) {}
    streamingText = '';
    error = null;
    errorKind = null;
    state = TurnState.idle;
    if (!_disposed) notifyListeners();
  }

  /// 消费流式回复；返回 true 表示正常完成，false 表示首字超时需降级。
  Future<bool> _consumeStream(
    LlmConfig config,
    List<LlmMessage> history,
    Stopwatch watch,
    void Function(String delta) onDelta,
  ) async {
    final completer = Completer<bool>();
    StreamSubscription<String>? sub;
    Timer? firstTimer;
    var gotFirst = false;
    final buffer = StringBuffer();
    // 流式请求单独持有一个 CancelToken：首字超时降级时取消它，
    // 让旧请求真正中止（不影响后续非流式请求共用的 cancelToken）。
    final streamToken = CancelToken();
    _streamToken = streamToken;

    firstTimer = Timer(Timeouts.firstToken, () async {
      if (gotFirst || completer.isCompleted) return;
      AppLogger.warn('llm stream first token timeout after 6s');
      streamToken.cancel('first token timeout');
      await sub?.cancel();
      if (!completer.isCompleted) completer.complete(false);
    });

    try {
      sub = llmClient
          .streamChat(config, history, maxTokens: 700, cancelToken: streamToken)
          .listen(
            (delta) {
              if (delta.isEmpty) return;
              if (!gotFirst) {
                gotFirst = true;
                firstTimer?.cancel();
                _firstTokenMs ??= watch.elapsedMilliseconds;
                _slowTimer?.cancel();
                if (slowReply) {
                  slowReply = false;
                  if (!_disposed) notifyListeners();
                }
              }
              onDelta(delta);
              buffer.write(delta);
              _drainSentences(buffer);
            },
            onError: (Object e, StackTrace st) {
              firstTimer?.cancel();
              if (!completer.isCompleted) completer.completeError(e, st);
            },
            onDone: () {
              firstTimer?.cancel();
              if (!completer.isCompleted) {
                completer.complete(gotFirst);
              }
              _drainSentences(buffer, flush: true);
            },
            cancelOnError: true,
          );
    } catch (e, s) {
      firstTimer.cancel();
      if (!completer.isCompleted) completer.completeError(e, s);
    }

    try {
      return await completer.future;
    } finally {
      firstTimer.cancel();
      await sub?.cancel();
      if (_streamToken == streamToken) _streamToken = null;
    }
  }

  /// 句末切分：遇 . ? ! 且长度 ≥8，或累计 ≥120 字符，切句送朗读。
  void _drainSentences(StringBuffer buffer, {bool flush = false}) {
    var text = buffer.toString();
    while (text.isNotEmpty) {
      var cut = -1;
      for (var i = 0; i < text.length; i++) {
        if ('.!?'.contains(text[i]) && i + 1 >= 8) {
          cut = i + 1;
          break;
        }
      }
      if (cut < 0 && text.length >= 120) cut = text.length;
      if (cut < 0) break;
      final sentence = text.substring(0, cut).trim();
      text = text.substring(cut);
      if (sentence.isNotEmpty) _enqueueSpeech(sentence);
    }
    buffer.clear();
    if (text.isNotEmpty) buffer.write(text);
    if (flush) {
      final rest = buffer.toString().trim();
      buffer.clear();
      if (rest.isNotEmpty) _enqueueSpeech(rest);
    }
  }

  void _enqueueSpeech(String sentence) {
    if (!_autoPlay) return;
    final token = _ttsToken;
    _speakQueue = _speakQueue.then((_) async {
      if (_disposed || token != _ttsToken) return;
      _currentSpokenText = sentence;
      if (state == TurnState.thinking) {
        state = TurnState.speaking;
        if (!_disposed) notifyListeners();
      }
      try {
        await audioSession.preparePlayback();
        await tts.speak(
          sentence,
          voice: _voice,
          rate: _rate,
          preferEdge: _preferEdge,
        );
      } on TtsException catch (e) {
        AppLogger.warn('tts failed: ${e.error.detail}');
        // 整场只提示一次，避免每句都弹同一条降级提示。
        if (!_ttsWarned) {
          _ttsWarned = true;
          ttsWarning = '朗读暂不可用，本场改用系统语音，只提示这一次；文字不受影响';
          if (!_disposed) notifyListeners();
        }
      }
    }).catchError((Object e) {
      AppLogger.warn('tts queue error: $e');
    });
  }

  Future<void> _failTurn(AppError e) async {
    error = e.detail ?? '回复失败，请稍后重试';
    errorKind = e.kind;
    if (e.kind == AppErrorKind.config) _missingKeyMessage = e.detail;
    state = TurnState.error;
    streamingText = '';
    if (!_disposed) notifyListeners();
  }

  // ------------------------------------------------- 翻译 / 提示 / 我想说

  /// 会话内切换翻译三态：off / tap / always，并持久化到设置。
  Future<void> setTranslateMode(String mode) async {
    final next = switch (mode) {
      'tap' => 'tap',
      'always' => 'always',
      _ => 'off',
    };
    translateMode = next;
    translationError = null;
    await settings.set(SettingsKeys.translateDefault, next);
    notifyListeners();
    if (next == 'always') {
      final latest = messages.lastWhere(
        (e) => !e.isUser,
        orElse: () => const MessageRecord(
          id: '',
          sessionId: '',
          seq: 0,
          role: 'assistant',
          textEn: '',
          createdAt: 0,
        ),
      );
      if (latest.id.isNotEmpty && !_translations.containsKey(latest.id)) {
        unawaited(translate(latest));
      }
    }
  }

  /// 点按翻译：与对话共用同一个 LlmConfig（地址 / 模型 / 密钥），
  /// 只是独立上下文、默认非流式、低 temperature；非流式取不到正文时由
  /// `_sideChat` 降级到流式。结果写入 text_zh 缓存，不进主历史。
  Future<void> translate(MessageRecord message) async {
    if (translateMode == 'off') return;
    if (_translations.containsKey(message.id) || _translating.contains(message.id)) return;
    final text = message.textEn.trim();
    if (text.isEmpty) return;
    _translating.add(message.id);
    translationError = null;
    _failedTranslationId = null;
    notifyListeners();
    try {
      // 思考型模型会先把 token 花在 reasoning 上，160 太容易让正文为空。
      final reply = await _sideChat(PromptBuilder.translateMessages(text), maxTokens: 512);
      final zh = PromptBuilder.cleanTranslation(reply.text);
      if (zh.isEmpty) {
        translationError = '这次没拿到中文，可以再点一次翻译';
        _failedTranslationId = message.id;
      } else {
        _translations[message.id] = zh;
        final updated = message.copyWith(textZh: zh);
        final index = messages.indexWhere((e) => e.id == message.id);
        if (index >= 0) {
          final next = [...messages];
          next[index] = updated;
          messages = next;
        }
        await sessions.saveMessage(updated);
        await _incrementCounters(translate: 1);
      }
    } on AppError catch (e) {
      translationError = e.detail ?? '翻译失败，可以重试';
      _failedTranslationId = message.id;
    } catch (e) {
      AppLogger.warn('translate failed: $e');
      translationError = '翻译失败，可以重试';
      _failedTranslationId = message.id;
    } finally {
      _translating.remove(message.id);
      if (!_disposed) notifyListeners();
    }
  }

  /// 翻译失败后重试同一条消息，英文原文始终保留。
  void retryTranslation() {
    final id = _failedTranslationId;
    if (id == null) return;
    for (final message in messages) {
      if (message.id == id) {
        unawaited(translate(message));
        return;
      }
    }
  }

  void clearTranslationError() {
    translationError = null;
    _failedTranslationId = null;
    if (!_disposed) notifyListeners();
  }

  /// L1–L4 提示阶梯。结果只在页面内存里展示，绝不写入 messages，也绝不自动发送。
  Future<void> requestHint(int level, {String chinese = ''}) async {
    final chosen = level.clamp(1, 4);
    hintLevel = chosen;
    hintText = null;
    hintTextZh = null;
    hintError = null;
    hintLoading = chosen != 1;
    notifyListeners();

    if (chosen == 1) {
      // L1 不给答案：慢速重听最近一句 AI 的话，朗读不可用时仍保留文字。
      // 重听在后台进行，不让 TTS 合成/降级耗时卡住提示弹层的关闭。
      hintText = '已慢速重听上一句；听清后自己开口说，AI 会等你。';
      await _incrementCounters(hint: 1);
      hintLoading = false;
      if (!_disposed) notifyListeners();
      unawaited(_replaySlow());
      return;
    }
    if (chosen == 4 && chinese.trim().isEmpty) {
      hintError = '先写一句中文想说的话，再点「中→英」';
      hintLoading = false;
      notifyListeners();
      return;
    }
    try {
      final reply = await _sideChat(
        PromptBuilder.hintMessages(
          context: SessionContext(scenario: scenario, history: messages),
          level: chosen,
          chinese: chinese.trim(),
        ),
        maxTokens: 384,
      );
      // 一次请求返回英文提示 + 中文对照；L4 直接用用户写的中文兜底。
      final parsed = HintParser.parse(reply.text);
      hintTextZh = parsed.zh ?? (chosen == 4 ? chinese.trim() : null);
      if (parsed.en.isEmpty) {
        hintText = '这次没拿到提示，可以再试一次';
      } else {
        hintText = parsed.en;
        if (hintTextZh == null) {
          // 模型没按 EN:/ZH: 两行输出时补一次翻译，保证提示有中文对照；
          // 补翻失败也不影响英文提示本身。
          try {
            final zhReply =
                await _sideChat(PromptBuilder.translateMessages(parsed.en), maxTokens: 512);
            final zh = PromptBuilder.cleanTranslation(zhReply.text);
            if (zh.isNotEmpty) hintTextZh = zh;
          } catch (e) {
            AppLogger.warn('hint zh fallback failed: $e');
          }
        }
      }
      // L3 / L4 属于「有辅助」的回合，复盘里要能识别。
      await _incrementCounters(hint: 1, assist: chosen >= 3 ? 1 : 0);
    } on AppError catch (e) {
      hintError = e.detail ?? '提示请求失败，可以重试';
    } catch (e) {
      AppLogger.warn('hint failed: $e');
      hintError = '提示请求失败，可以重试';
    } finally {
      hintLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _replaySlow() async {
    final lastAi = messages.lastWhere(
      (e) => !e.isUser && !e.isHint && e.textEn.trim().isNotEmpty,
      orElse: () => const MessageRecord(
        id: '',
        sessionId: '',
        seq: 0,
        role: 'assistant',
        textEn: '',
        createdAt: 0,
      ),
    );
    if (lastAi.id.isEmpty) return;
    await stopPlayback();
    _currentSpokenText = lastAi.textEn;
    state = TurnState.speaking;
    notifyListeners();
    try {
      await audioSession.preparePlayback();
      await tts.speak(
        lastAi.textEn,
        voice: _voice,
        rate: _rate,
        preferEdge: _preferEdge,
        playbackSpeed: 0.8,
      );
    } on TtsException catch (e) {
      AppLogger.warn('slow replay failed: ${e.error.detail}');
      ttsWarning = '朗读暂不可用，已保留上一句文字，可点播放按钮重试';
    } finally {
      if (!_disposed && state == TurnState.speaking) {
        state = TurnState.idle;
        notifyListeners();
      }
    }
  }

  /// 「我想说」：中文 → 一句英文建议。用户要自己按下麦克风或点发送。
  Future<void> requestWantToSay(String chinese) async {
    final clean = chinese.trim();
    if (clean.isEmpty) return;
    wantToSayLoading = true;
    wantToSayError = null;
    wantToSayText = null;
    notifyListeners();
    try {
      final reply = await _sideChat(
        PromptBuilder.wantToSayMessages(scenario, clean),
        maxTokens: 384,
      );
      final text = _firstLine(reply.text);
      wantToSayText = text.isEmpty ? null : text;
      if (wantToSayText == null) wantToSayError = '这次没生成建议，可以再试一次';
      await _incrementCounters(assist: 1);
    } on AppError catch (e) {
      wantToSayError = e.detail ?? '生成失败，可以重试';
    } catch (e) {
      AppLogger.warn('want-to-say failed: $e');
      wantToSayError = '生成失败，可以重试';
    } finally {
      wantToSayLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  void closeHint() {
    hintText = null;
    hintTextZh = null;
    hintError = null;
    hintLevel = null;
    hintLoading = false;
    notifyListeners();
  }

  void clearWantToSay() {
    wantToSayText = null;
    wantToSayError = null;
    notifyListeners();
  }

  // ------------------------------------------------- 回答句操作栏

  /// 「优化句子」：旁路请求一句更自然的说法 + 中文理由；不进主历史、不自动发送。
  Future<void> optimizeSentence(MessageRecord message) async {
    final text = message.textEn.trim();
    if (text.isEmpty || improvingMessageId != null) return;
    improvingMessageId = message.id;
    improvementError = null;
    notifyListeners();
    try {
      final reply = await _sideChat(
        PromptBuilder.improveMessages(
          text,
          SessionContext(scenario: scenario, history: messages),
        ),
        maxTokens: 256,
      );
      final parsed = ImprovementParser.parse(reply.text);
      if (parsed.improved.isEmpty) {
        improvementError = '这次没拿到优化建议，可以再试一次';
      } else {
        improvements[message.id] = SentenceImprovement(
          improved: parsed.improved,
          reasonZh: parsed.reasonZh,
        );
      }
      await _incrementCounters(assist: 1);
    } on AppError catch (e) {
      improvementError = e.detail ?? '优化失败，可以重试';
    } catch (e) {
      AppLogger.warn('improve sentence failed: $e');
      improvementError = '优化失败，可以重试';
    } finally {
      improvingMessageId = null;
      if (!_disposed) notifyListeners();
    }
  }

  void closeImprovement(String messageId) {
    improvements.remove(messageId);
    improvementError = null;
    if (!_disposed) notifyListeners();
  }

  /// 把优化后的说法收进表达本（表达本的手工添加入口之外的数据来源）。
  Future<void> saveImprovement(String messageId) async {
    final item = improvements[messageId];
    if (item == null) return;
    final now = DateTime.now();
    await sessions.savePhrase(Phrase(
      id: 'p_${now.microsecondsSinceEpoch}',
      textEn: item.improved,
      sourceSessionId: sessionId,
      sourceScenarioId: scenario?.id,
      createdAt: now.millisecondsSinceEpoch,
    ));
  }

  /// 回放用户这句的录音。系统识别 / 文字输入没有录音文件，按钮在页面里会置灰。
  Future<void> playOriginal(MessageRecord message) async {
    final path = message.audioPath;
    if (path == null || path.isEmpty) return;
    if (playingOriginalId == message.id) {
      await stopOriginal();
      return;
    }
    await stopPlayback();
    playingOriginalId = message.id;
    notifyListeners();
    try {
      await audioSession.preparePlayback();
      await player.playPath(path);
    } catch (e) {
      AppLogger.warn('play original audio failed: $e');
      ttsWarning = '这句原声已不可用，文字仍然保留';
    } finally {
      if (!_disposed && playingOriginalId == message.id) {
        playingOriginalId = null;
        notifyListeners();
      }
    }
  }

  Future<void> stopOriginal() async {
    playingOriginalId = null;
    await player.stop();
    if (!_disposed) notifyListeners();
  }

  /// 旁路请求：提示 / 翻译 /「我想说」走独立消息数组；提示与优化只读地携带
  /// 当前会话快照，旁路结果绝不写回主历史，也不自动发送。
  ///
  /// 与对话共用 `_config()`（同一地址 / 模型 / 密钥）；默认非流式，但思考型模型
  /// 常把非流式的 token 预算耗在 reasoning 上导致正文为空，此时降级到与对话
  /// 相同的流式路径再取一次，避免「对话正常、翻译一直报错」。
  Future<LlmReply> _sideChat(List<LlmMessage> prompt, {int maxTokens = 512}) async {
    final config = await _config();
    final chars = prompt.fold<int>(0, (sum, m) => sum + m.content.length);
    try {
      final reply = await _sideChatOnce(config, prompt, maxTokens);
      await _accumulateCost(promptChars: chars, output: reply.text, usage: reply.usage);
      return reply;
    } on TimeoutException {
      throw const AppError(
        kind: AppErrorKind.network,
        detail: '请求超时，请检查网络后重试',
        retryable: true,
      );
    }
  }

  Future<LlmReply> _sideChatOnce(
    LlmConfig config,
    List<LlmMessage> prompt,
    int maxTokens,
  ) async {
    final watch = Stopwatch()..start();
    try {
      return await llmClient
          .chat(config, prompt, maxTokens: maxTokens, temperature: 0.3)
          .timeout(Timeouts.sideRequest);
    } on AppError catch (e) {
      // 只在「服务端 / 模型没给出正文」时降级；鉴权、404、限流重试也无解。
      if (e.kind != AppErrorKind.server) rethrow;
      AppLogger.warn('side chat non-stream failed (${e.detail}), fallback to stream');
    }
    final buffer = StringBuffer();
    await for (final delta in llmClient
        .streamChat(config, prompt, maxTokens: maxTokens, temperature: 0.3)
        .timeout(Timeouts.sideRequest)) {
      buffer.write(delta);
    }
    final text = buffer.toString().trim();
    if (text.isEmpty) {
      throw const AppError(
        kind: AppErrorKind.server,
        detail: '模型没有返回正文内容，可以重试',
        retryable: true,
      );
    }
    watch.stop();
    return LlmReply(
      text: text,
      usage: const LlmUsage(),
      latencyMs: watch.elapsedMilliseconds,
      usedStream: true,
      model: config.model,
    );
  }

  Future<void> _accumulateCost({
    required int promptChars,
    required String output,
    LlmUsage? usage,
  }) async {
    final sample = CostEstimator.estimate(
      promptChars: promptChars,
      output: output,
      usage: usage,
    );
    sessionCost += sample.cny;
    if (sample.estimated) costEstimated = true;
    final current = session;
    if (current != null) {
      session = current.copyWith(costEstimate: sessionCost);
      await sessions.saveSession(session!);
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> _incrementCounters({int hint = 0, int assist = 0, int translate = 0}) async {
    final current = session;
    if (current == null) return;
    session = current.copyWith(
      hintCount: current.hintCount + hint,
      assistTurns: current.assistTurns + assist,
      translateCount: current.translateCount + translate,
    );
    await sessions.saveSession(session!);
  }

  /// 分阶段延迟落 app_meta，供「我的」页查看最近一回合的口径。
  Future<void> _recordLatency() async {
    await sessions.setMeta(
      'latency.lastTurn',
      jsonEncode({
        'asr': _asrMs ?? 0,
        'firstToken': _firstTokenMs ?? 0,
        'firstAudio': _firstAudioMs ?? 0,
        'at': DateTime.now().millisecondsSinceEpoch,
      }),
    );
  }

  static String _firstLine(String raw) {
    final lines = raw
        .split('\n')
        .map((e) => e.trim().replaceAll(RegExp(r'^[-*>]\s*'), ''))
        .where((e) => e.isNotEmpty)
        .toList();
    if (lines.isEmpty) return '';
    var out = lines.first.replaceAll('**', '').trim();
    if (out.startsWith('"') && out.endsWith('"') && out.length > 1) {
      out = out.substring(1, out.length - 1).trim();
    }
    return out;
  }

  // ---------------------------------------------------------------- 播放

  Future<void> playMessage(MessageRecord message) async {
    final text = message.textEn.trim();
    if (text.isEmpty) return;
    if (playingMessageId == message.id) {
      await stopPlayback();
      return;
    }
    await stopPlayback();
    _currentSpokenText = text;
    ttsWarning = offline && !tts.hasCached(text, voice: _voice, rate: _rate)
        ? '网络不可用：这句没有缓存，将尝试系统语音；文字仍可读'
        : null;
    playingMessageId = message.id;
    state = TurnState.speaking;
    notifyListeners();
    try {
      await audioSession.preparePlayback();
      await tts.speak(text, voice: _voice, rate: _rate, preferEdge: _preferEdge);
    } on TtsException catch (e) {
      AppLogger.warn('replay failed: ${e.error.detail}');
      ttsWarning = '朗读暂不可用，已显示文字';
    } finally {
      _currentSpokenText = null;
      if (!_disposed && playingMessageId == message.id) {
        playingMessageId = null;
        state = TurnState.idle;
        notifyListeners();
      }
    }
  }

  Future<void> stopPlayback() async {
    _ttsToken++;
    playingMessageId = null;
    playingOriginalId = null;
    resumeText = null;
    _currentSpokenText = null;
    try {
      await tts.stop();
    } catch (_) {}
    if (!_disposed && (state == TurnState.speaking)) {
      state = TurnState.idle;
      notifyListeners();
    }
  }

  void _handleInterrupted() {
    if (state != TurnState.speaking) return;
    final pending = _currentSpokenText;
    unawaited(stopPlayback());
    resumeText = pending;
    ttsWarning = '播放已被系统中断，点「继续播放」可重听，不会自动续播';
    notifyListeners();
  }

  /// 中断后由用户显式点「继续播放」才续播，避免来电结束突然出声。
  Future<void> resumePlayback() async {
    final text = resumeText?.trim();
    if (text == null || text.isEmpty) return;
    resumeText = null;
    ttsWarning = null;
    _currentSpokenText = text;
    state = TurnState.speaking;
    notifyListeners();
    try {
      await audioSession.preparePlayback();
      await tts.speak(text, voice: _voice, rate: _rate, preferEdge: _preferEdge);
    } on TtsException catch (e) {
      AppLogger.warn('resume playback failed: ${e.error.detail}');
      ttsWarning = '朗读暂不可用，已保留文字';
    } finally {
      _currentSpokenText = null;
      if (!_disposed && state == TurnState.speaking) {
        state = TurnState.idle;
        notifyListeners();
      }
    }
  }

  /// 监听网络状态；离线时对话页显示提示条，发送失败由请求层照常报错。
  void _listenNetwork() {
    try {
      _netSub = Connectivity().onConnectivityChanged.listen(
        (results) {
          final off = results.isEmpty || results.every((r) => r == ConnectivityResult.none);
          if (off == offline) return;
          offline = off;
          AppLogger.debug('network offline=$off');
          if (!_disposed) notifyListeners();
        },
        onError: (Object e) => AppLogger.warn('connectivity listen failed: $e'),
      );
    } catch (e) {
      AppLogger.warn('connectivity unavailable: $e');
    }
  }

  void _handleDeviceDisconnected() {
    final pending = _currentSpokenText;
    if (state == TurnState.speaking) unawaited(stopPlayback());
    if (pending != null) resumeText = pending;
    ttsWarning = '音频设备已断开，播放已暂停，可点「继续播放」';
    notifyListeners();
  }

  void _handleDeviceChanged(bool connected) {
    routeNotice = connected
        ? '检测到耳机/蓝牙接入，下一句会走新设备'
        : null;
    notifyListeners();
  }

  // ---------------------------------------------------------------- 结束

  /// 用户显式点「结束并复盘」：只有这条路径会把会话标成 completed。
  Future<SessionRecord?> endSession() async {
    final current = session;
    if (current == null) return null;
    _finished = true;
    _ticker?.cancel();
    await stopPlayback();
    await cancelRecording();
    await sessions.finishSession(current, durationSec: elapsedSec);
    final updated = await sessions.byId(sessionId);
    session = updated ?? current;
    notifyListeners();
    return session;
  }

  /// 半路退出 / 系统返回 / 进程切后台：保存为可续练状态，不生成复盘。
  /// 由对话页在 pop 前与 dispose 时各调一次，靠状态位保证幂等、不会覆盖已完成会话。
  Future<SessionRecord?> pauseSession() async {
    final current = session;
    if (_finished || _deleted || current == null) return current;
    _ticker?.cancel();
    session = await sessions.pauseSession(current, durationSec: elapsedSec);
    return session;
  }

  void dismissResumeNotice() {
    resumeNotice = null;
    notifyListeners();
  }

  Future<void> deleteDraft() async {
    if ((session?.turnCount ?? 0) == 0) {
      _deleted = true;
      _ticker?.cancel();
      await sessions.deleteSession(sessionId);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _recordTicker?.cancel();
    _slowTimer?.cancel();
    _cancelToken?.cancel('page disposed');
    unawaited(_netSub?.cancel());
    asr.onPartial = null;
    unawaited(audioSession.leaveConversation());
    // 服务实例由 Provider 持有，控制器只负责停止本次会话的播放与录音。
    unawaited(asr.cancel());
    unawaited(_httpAsr?.cancel());
    unawaited(_chatAudioAsr?.cancel());
    unawaited(recorder.cancel());
    unawaited(tts.stop());
    tts.onPlaybackStart = null;
    super.dispose();
  }
}
