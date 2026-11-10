import 'dart:convert';

/// 解析 OpenAI 兼容 SSE 行流。
///
/// GLM-5.3-Flash 会先返回 `reasoning_content`，本解析器只把 `delta.content`
/// 当作正文，思考内容完全忽略。
class SseParser {
  final StringBuffer _buffer = StringBuffer();

  /// 输入任意分片文本，返回本次可解析出的正文增量。
  List<String> feed(String chunk) {
    _buffer.write(chunk);
    final text = _buffer.toString();
    final lines = text.split('\n');
    _buffer.clear();
    // 最后一段可能不完整，留到下次。
    if (!text.endsWith('\n')) {
      _buffer.write(lines.removeLast());
    }
    final deltas = <String>[];
    for (var raw in lines) {
      final line = raw.trimRight();
      if (line.isEmpty || line.startsWith(':')) continue;
      if (!line.startsWith('data:')) continue;
      final payload = line.substring(5).trim();
      if (payload.isEmpty || payload == '[DONE]') continue;
      try {
        final json = jsonDecode(payload);
        if (json is! Map) continue;
        final choices = json['choices'];
        if (choices is! List || choices.isEmpty) continue;
        final delta = (choices.first as Map)['delta'];
        if (delta is! Map) continue;
        final content = delta['content'];
        if (content is String && content.isNotEmpty) deltas.add(content);
      } catch (_) {
        // 忽略不完整或非 JSON 的心跳帧。
      }
    }
    return deltas;
  }

  /// 流结束时把残留缓冲再解析一次。
  List<String> flush() => feed('\n');
}
