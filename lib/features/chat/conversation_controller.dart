import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/foundation.dart';

import '../../core/errors.dart';
import '../../core/logger.dart';
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
import '../../services/llm/llm_client.dart';
import '../../services/llm/llm_models.dart';
import '../../services/llm/prompt_builder.dart';
import '../../services/tts/tts_engine.dart';
import '../../services/tts/tts_router.dart';

/// 回合状态机：空闲 / 录音 / 识别 / 思考 / 朗读 / 错误。
enum TurnState { idle, recording, transcribing, thinking, speaking, error }

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
  bool loading = true;
  bool asrAvailable = false;
  bool asrChecking = true;
  bool slowReply = false;
  bool offline = false;
  String inputMode = 'voice';
  int elapsedSec = 0;
  int recordingMs = 0;

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
      scenario = await scenarios.byId(session!.scenarioId ?? '');
      messages = await sessions.messages(sessionId);
      elapsedSec = session!.durationSec > 0
          ? session!.durationSec
          : ((DateTime.now().millisecondsSinceEpoch - session!.startedAt) / 1000).round();
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
      tts.resetCircuit();
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
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSec++;
      notifyListeners();
    });
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
    ttsWarning = null;
    asrNotice = null;
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
    try {
      if (_usingHttpAsr && _httpAsr != null) {
        final path = await _httpAsr!.stopCapture();
        if (path == null || path.isEmpty) {
          transcript = '';
        } else {
          try {
            transcript = await _httpAsr!.transcribe(path).timeout(const Duration(seconds: 20));
          } on AsrException catch (e) {
            // 接口失败（额度/网络/格式）时，若开启了实验引擎，用同一段音频再试一次。
            final fallback = _chatAudioAsr;
            if (fallback == null) rethrow;
            asrNotice = '识别接口不可用（${e.error.detail}），已改用实验引擎重试';
            notifyListeners();
            transcript = await fallback.transcribe(path).timeout(const Duration(seconds: 40));
            _asrMode = 'chatAudio';
          }
        }
      } else if (_usingChatAudio && _chatAudioAsr != null) {
        transcript = await _chatAudioAsr!.stop().timeout(
          const Duration(seconds: 40),
          onTimeout: () => '',
        );
      } else if (_usingAsr) {
        transcript = await asr.stop().timeout(
          const Duration(seconds: 9),
          onTimeout: () => '',
        );
      } else {
        await recorder.stop();
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
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    if (state == TurnState.thinking) return;
    if (state == TurnState.speaking) await stopPlayback();
    final current = session;
    final currentScenario = scenario;
    if (current == null || currentScenario == null) return;

    error = null;
    ttsWarning = null;
    _turnStartedAt = DateTime.now();
    _firstAudioMs = null;
    final seq = messages.isEmpty ? 1 : messages.last.seq + 1;
    final userMessage = MessageRecord(
      id: 'm_${DateTime.now().microsecondsSinceEpoch}_u',
      sessionId: sessionId,
      seq: seq,
      role: 'user',
      textEn: clean,
      asrProvider: asrProvider,
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
    ttsWarning = null;
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
    _startSlowTimer();
    String full = '';
    var usedStream = false;
    try {
      final config = await _config();
      final history = PromptBuilder.chatMessages(
        scenario: currentScenario,
        level: settings.getString(SettingsKeys.level, 'B1'),
        history: messages,
      );

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
        latencyMs: _firstAudioMs ?? (usedStream ? watch.elapsedMilliseconds : null),
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
      lastFailedText = null;
      notifyListeners();

      await _speakQueue;
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
      if (_cancelToken == token) _cancelToken = null;
    }
  }

  /// 15 秒仍无首字时给出可操作提示（弱网 / 模型慢）。
  void _startSlowTimer() {
    _slowTimer?.cancel();
    slowReply = false;
    _slowTimer = Timer(const Duration(seconds: 15), () {
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

    firstTimer = Timer(const Duration(seconds: 6), () async {
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
      _firstAudioMs ??= _turnStartedAt == null
          ? null
          : DateTime.now().difference(_turnStartedAt!).inMilliseconds;
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
        ttsWarning = '朗读暂不可用，已显示文字，可点消息上的播放按钮重试';
        if (!_disposed) notifyListeners();
      }
    }).catchError((Object e) {
      AppLogger.warn('tts queue error: $e');
    });
  }

  Future<void> _failTurn(AppError e) async {
    error = e.detail ?? '回复失败，请稍后重试';
    if (e.kind == AppErrorKind.config) _missingKeyMessage = e.detail;
    state = TurnState.error;
    streamingText = '';
    if (!_disposed) notifyListeners();
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
    unawaited(stopPlayback());
    ttsWarning = '播放已被系统中断，可点播放按钮继续';
    notifyListeners();
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
    if (state != TurnState.speaking) return;
    unawaited(stopPlayback());
    ttsWarning = '音频设备已断开，播放已暂停';
    notifyListeners();
  }

  // ---------------------------------------------------------------- 结束

  Future<SessionRecord?> endSession() async {
    final current = session;
    if (current == null) return null;
    await stopPlayback();
    await cancelRecording();
    await sessions.finishSession(current);
    final updated = await sessions.byId(sessionId);
    session = updated ?? current;
    _ticker?.cancel();
    notifyListeners();
    return session;
  }

  Future<void> deleteDraft() async {
    if ((session?.turnCount ?? 0) == 0) {
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
    super.dispose();
  }
}
