class LlmMessage {
  const LlmMessage(this.role, this.content);

  final String role;
  final String content;

  Map<String, Object?> toJson() => {'role': role, 'content': content};

  factory LlmMessage.system(String content) => LlmMessage('system', content);
  factory LlmMessage.user(String content) => LlmMessage('user', content);
  factory LlmMessage.assistant(String content) => LlmMessage('assistant', content);
}

class LlmUsage {
  const LlmUsage({this.promptTokens = 0, this.completionTokens = 0, this.totalTokens = 0});

  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  factory LlmUsage.fromJson(Map<String, Object?>? json) {
    if (json == null) return const LlmUsage();
    return LlmUsage(
      promptTokens: (json['prompt_tokens'] as num?)?.toInt() ?? 0,
      completionTokens: (json['completion_tokens'] as num?)?.toInt() ?? 0,
      totalTokens: (json['total_tokens'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toJson() => {
        'prompt_tokens': promptTokens,
        'completion_tokens': completionTokens,
        'total_tokens': totalTokens,
      };
}

class LlmReply {
  const LlmReply({
    required this.text,
    required this.usage,
    required this.latencyMs,
    this.usedStream = false,
    this.model,
  });

  final String text;
  final LlmUsage usage;
  final int latencyMs;
  final bool usedStream;
  final String? model;
}

class LlmConfig {
  const LlmConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
  });

  final String baseUrl;
  final String apiKey;
  final String model;

  String get chatUrl {
    final base = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return '$base/chat/completions';
  }

  String get modelsUrl {
    final base = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return '$base/models';
  }
}
