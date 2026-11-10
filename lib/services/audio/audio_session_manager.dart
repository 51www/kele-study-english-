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
      await _session?.setActive(true);
    } catch (e) {
      if (!kIsWeb) AppLogger.warn('audio session activate failed: $e');
    }
  }
}
