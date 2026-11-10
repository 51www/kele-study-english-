import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/errors.dart';
import '../../core/logger.dart';
import 'edge_socket.dart';
import 'tts_engine.dart';

/// 微软 Edge 在线朗读（非官方接口）。
///
/// 握手依赖 TrustedClientToken + Sec-MS-GEC 签名；接口可能随时变更，
/// 失败时由 [TtsRouter] 切系统 TTS，不阻塞对话。
class EdgeTtsEngine implements TtsEngine {
  static const _endpoint =
      'wss://speech.platform.bing.com/consumer/speech/synthesize/readaloud/edge/v1';
  static const _trustedToken = '6A5AA1D4EAFF4E9FB37E23D68491D6F4';
  static const _gecVersion = '1-130.0.2849.68';
  static const defaultVoice = 'en-US-AriaNeural';

  final _uuid = const Uuid();
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;

  @override
  String get id => 'edge';

  @override
  Future<List<TtsVoice>> voices() async => const [
        TtsVoice(id: 'en-US-AriaNeural', label: 'Aria · 美式女声'),
        TtsVoice(id: 'en-US-GuyNeural', label: 'Guy · 美式男声'),
        TtsVoice(id: 'en-GB-SoniaNeural', label: 'Sonia · 英式女声'),
      ];

  @override
  Future<TtsResult> synthesize(
    String text, {
    required String voice,
    required double rate,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) {
      return const TtsResult(engine: 'edge', bytes: null);
    }
    final connectionId = _uuid.v4().replaceAll('-', '');
    final uri = Uri.parse(
      '$_endpoint?TrustedClientToken=$_trustedToken'
      '&Sec-MS-GEC=${_secMsGec()}'
      '&Sec-MS-GEC-Version=$_gecVersion'
      '&ConnectionId=$connectionId',
    );

    final completer = Completer<TtsResult>();
    final audio = BytesBuilder(copy: false);
    Timer? timeout;
    var finished = false;

    void completeError(String detail) {
      if (finished) return;
      finished = true;
      timeout?.cancel();
      _close();
      if (!completer.isCompleted) {
        completer.completeError(TtsException(
          AppError(kind: AppErrorKind.audio, detail: detail, retryable: true),
        ));
      }
    }

    void completeOk() {
      if (finished) return;
      finished = true;
      timeout?.cancel();
      _close();
      final bytes = audio.takeBytes();
      if (bytes.isEmpty) {
        completeError('Edge 朗读没有返回音频');
        return;
      }
      if (!completer.isCompleted) {
        completer.complete(TtsResult(bytes: bytes, engine: 'edge'));
      }
    }

    try {
      final channel = connectEdgeSocket(uri);
      _channel = channel;
      _sub = channel.stream.listen(
        (data) {
          if (data is List<int>) {
            // 二进制帧：前 2 字节是大端序的头部长度。
            if (data.length < 2) return;
            final headerLength = (data[0] << 8) | data[1];
            final start = 2 + headerLength;
            if (start < data.length) {
              audio.add(data.sublist(start));
            }
          } else if (data is String) {
            if (data.contains('Path:turn.end')) completeOk();
          }
        },
        onError: (Object error) {
          AppLogger.warn('edge tts stream error: $error');
          completeError('Edge 朗读连接中断');
        },
        onDone: () {
          if (!finished) completeError('Edge 朗读连接提前关闭');
        },
        cancelOnError: true,
      );

      channel.sink.add(_configMessage());
      channel.sink.add(_ssmlMessage(clean, voice, rate));
      timeout = Timer(const Duration(seconds: 12), () {
        completeError('Edge 朗读超时');
      });
    } catch (e) {
      completeError('Edge 朗读连接失败：$e');
    }

    return completer.future;
  }

  String _configMessage() {
    final payload = jsonEncode({
      'context': {
        'synthesis': {
          'audio': {
            'metadataoptions': {
              'sentenceBoundaryEnabled': 'false',
              'wordBoundaryEnabled': 'false',
            },
            'outputFormat': 'audio-24khz-48kbitrate-mono-mp3',
          },
        },
      },
    });
    return 'X-Timestamp:${_timestamp()}\r\n'
        'Content-Type:application/json; charset=utf-8\r\n'
        'Path:speech.config\r\n\r\n'
        '$payload';
  }

  String _ssmlMessage(String text, String voice, double rate) {
    final percent = ((rate - 1) * 100).round();
    final rateText = percent >= 0 ? '+$percent%' : '$percent%';
    final escaped = const HtmlEscape(HtmlEscapeMode.element).convert(text);
    final ssml = "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' "
        "xml:lang='en-US'><voice name='${_escapeAttr(voice)}'>"
        "<prosody rate='$rateText' pitch='+0Hz' volume='+0%'>$escaped</prosody>"
        '</voice></speak>';
    return 'X-RequestId:${_uuid.v4().replaceAll('-', '')}\r\n'
        'Content-Type:application/ssml+xml\r\n'
        'X-Timestamp:${_timestamp()}\r\n'
        'Path:ssml\r\n\r\n'
        '$ssml';
  }

  String _escapeAttr(String value) => value.replaceAll("'", '').replaceAll('"', '');

  String _timestamp() {
    return '${DateTime.now().toUtc().toIso8601String().split('.').first}Z';
  }

  /// Sec-MS-GEC：Windows epoch 100ns tick 向下取整到 5 分钟 + Token 的 SHA-256。
  String _secMsGec() {
    const winEpochOffsetSeconds = 11644473600;
    final seconds = DateTime.now().toUtc().millisecondsSinceEpoch / 1000 +
        winEpochOffsetSeconds;
    var ticks = (seconds * 10000000).floor();
    ticks -= ticks % 3000000000;
    final raw = '$ticks$_trustedToken';
    return sha256.convert(utf8.encode(raw)).toString().toUpperCase();
  }

  void _close() {
    _sub?.cancel();
    _sub = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  @override
  Future<void> cancel() async => _close();

  @override
  Future<void> dispose() async => _close();
}
