import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

import '../../core/logger.dart';

/// 统一管理音频会话：进入对话页配置为语音通信，离开时释放；
/// 监听来电/其他 App 抢占焦点与耳机拔出（becomingNoisy）。
class AudioSessionManager {
  AudioSession? _session;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  StreamSubscription<void>? _noisySub;
  bool _configured = false;

  /// 播放被系统中断（来电/其他 App 占用）时回调。
  void Function()? onInterrupted;

  /// 音频设备被拔出（耳机/蓝牙断开）时回调。
  void Function()? onDeviceDisconnected;

  bool get configured => _configured;

  Future<void> enterConversation() async {
    if (_configured) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration.speech());
      AppLogger.debug('audio session configured (speech)');
      _session = session;
      _interruptionSub = session.interruptionEventStream.listen((event) {
        if (event.begin) {
          AppLogger.debug('audio interruption begin: ${event.type.name}');
          onInterrupted?.call();
        }
      });
      _noisySub = session.becomingNoisyEventStream.listen((_) {
        AppLogger.debug('audio device disconnected (becoming noisy)');
        onDeviceDisconnected?.call();
      });
      _configured = true;
    } catch (e) {
      // Web / 桌面可能没有音频会话实现，降级为不做焦点管理。
      AppLogger.warn('audio session unavailable: $e');
      _configured = false;
    }
  }

  Future<void> leaveConversation() async {
    await _interruptionSub?.cancel();
    await _noisySub?.cancel();
    _interruptionSub = null;
    _noisySub = null;
    try {
      await _session?.setActive(false);
    } catch (_) {
      // 忽略释放失败
    }
    _session = null;
    _configured = false;
  }

  /// 播放/录音前确保会话处于激活状态。
  Future<void> activate() async {
    try {
      final ok = await _session?.setActive(true);
      AppLogger.debug('audio session activate=$ok configured=$_configured');
    } catch (e) {
      if (!kIsWeb) AppLogger.warn('audio session activate failed: $e');
    }
  }

  /// 朗读播放前切到媒体播放属性，避免沿用录音用的 voiceCommunication
  /// 通道（在 Android 上会被路由到听筒/通话音量，导致外放听不到声音）。
  Future<void> preparePlayback() async {
    final session = _session;
    if (session == null) return;
    try {
      await session.configure(AudioSessionConfiguration.music());
      final ok = await session.setActive(true);
      AppLogger.debug('audio session playback config, active=$ok');
    } catch (e) {
      if (!kIsWeb) AppLogger.warn('audio session playback config failed: $e');
    }
  }

  /// 录音前恢复语音通信属性。
  Future<void> prepareRecording() async {
    final session = _session;
    if (session == null) return;
    try {
      await session.configure(AudioSessionConfiguration.speech());
    } catch (e) {
      if (!kIsWeb) AppLogger.warn('audio session record config failed: $e');
    }
  }
}
