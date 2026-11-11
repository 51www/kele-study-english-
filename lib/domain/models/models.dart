import 'dart:convert';

class Scenario {
  const Scenario({
    required this.id,
    required this.titleZh,
    required this.titleEn,
    required this.category,
    required this.level,
    required this.aiRole,
    required this.userGoal,
    required this.openingLine,
    required this.targetPhrases,
    required this.expectedTurns,
    required this.successCriteria,
    this.branchHint,
    this.isBuiltin = true,
    this.sortOrder = 0,
  });

  final String id;
  final String titleZh;
  final String titleEn;
  final String category;
  final String level;
  final String aiRole;
  final String userGoal;
  final String openingLine;
  final List<String> targetPhrases;
  final int expectedTurns;
  final String successCriteria;
  final String? branchHint;
  final bool isBuiltin;
  final int sortOrder;

  String get estimatedMinutes => expectedTurns <= 8 ? '约 5 分钟' : '约 10 分钟';

  Map<String, Object?> toMap() => {
        'id': id,
        'title_zh': titleZh,
        'title_en': titleEn,
        'category': category,
        'level': level,
        'ai_role': aiRole,
        'user_goal': userGoal,
        'opening_line': openingLine,
        'target_phrases': jsonEncode(targetPhrases),
        'expected_turns': expectedTurns,
        'success_criteria': successCriteria,
        'branch_hint': branchHint,
        'is_builtin': isBuiltin ? 1 : 0,
        'sort_order': sortOrder,
      };

  factory Scenario.fromMap(Map<String, Object?> map) {
    return Scenario(
      id: map['id'] as String,
      titleZh: (map['title_zh'] ?? '') as String,
      titleEn: (map['title_en'] ?? '') as String,
      category: (map['category'] ?? '') as String,
      level: (map['level'] ?? 'B1') as String,
      aiRole: (map['ai_role'] ?? '') as String,
      userGoal: (map['user_goal'] ?? '') as String,
      openingLine: (map['opening_line'] ?? '') as String,
      targetPhrases: ((jsonDecode((map['target_phrases'] ?? '[]') as String)) as List)
          .map((e) => e.toString())
          .toList(),
      expectedTurns: (map['expected_turns'] as num?)?.toInt() ?? 8,
      successCriteria: (map['success_criteria'] ?? '') as String,
      branchHint: map['branch_hint'] as String?,
      isBuiltin: ((map['is_builtin'] as num?)?.toInt() ?? 1) == 1,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

class SessionRecord {
  const SessionRecord({
    required this.id,
    this.scenarioId,
    required this.startedAt,
    this.endedAt,
    this.durationSec = 0,
    this.turnCount = 0,
    this.hintCount = 0,
    this.assistTurns = 0,
    this.translateCount = 0,
    this.status = 'draft',
    this.modelName,
    this.ttsEngine,
    this.reviewJson,
    this.costEstimate,
  });

  final String id;
  final String? scenarioId;
  final int startedAt;
  final int? endedAt;
  final int durationSec;
  final int turnCount;
  final int hintCount;
  final int assistTurns;
  final int translateCount;
  final String status;
  final String? modelName;
  final String? ttsEngine;
  final String? reviewJson;
  final double? costEstimate;

  DateTime get startedDate => DateTime.fromMillisecondsSinceEpoch(startedAt);

  SessionRecord copyWith({
    String? scenarioId,
    int? endedAt,
    int? durationSec,
    int? turnCount,
    int? hintCount,
    int? assistTurns,
    int? translateCount,
    String? status,
    String? modelName,
    String? ttsEngine,
    String? reviewJson,
    double? costEstimate,
    bool clearEndedAt = false,
    bool clearReviewJson = false,
  }) {
    return SessionRecord(
      id: id,
      scenarioId: scenarioId ?? this.scenarioId,
      startedAt: startedAt,
      endedAt: clearEndedAt ? null : (endedAt ?? this.endedAt),
      durationSec: durationSec ?? this.durationSec,
      turnCount: turnCount ?? this.turnCount,
      hintCount: hintCount ?? this.hintCount,
      assistTurns: assistTurns ?? this.assistTurns,
      translateCount: translateCount ?? this.translateCount,
      status: status ?? this.status,
      modelName: modelName ?? this.modelName,
      ttsEngine: ttsEngine ?? this.ttsEngine,
      reviewJson: clearReviewJson ? null : (reviewJson ?? this.reviewJson),
      costEstimate: costEstimate ?? this.costEstimate,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'scenario_id': scenarioId,
        'started_at': startedAt,
        'ended_at': endedAt,
        'duration_sec': durationSec,
        'turn_count': turnCount,
        'hint_count': hintCount,
        'assist_turns': assistTurns,
        'translate_count': translateCount,
        'status': status,
        'model_name': modelName,
        'tts_engine': ttsEngine,
        'review_json': reviewJson,
        'cost_estimate': costEstimate,
      };

  factory SessionRecord.fromMap(Map<String, Object?> map) {
    return SessionRecord(
      id: map['id'] as String,
      scenarioId: map['scenario_id'] as String?,
      startedAt: (map['started_at'] as num?)?.toInt() ?? 0,
      endedAt: (map['ended_at'] as num?)?.toInt(),
      durationSec: (map['duration_sec'] as num?)?.toInt() ?? 0,
      turnCount: (map['turn_count'] as num?)?.toInt() ?? 0,
      hintCount: (map['hint_count'] as num?)?.toInt() ?? 0,
      assistTurns: (map['assist_turns'] as num?)?.toInt() ?? 0,
      translateCount: (map['translate_count'] as num?)?.toInt() ?? 0,
      status: (map['status'] ?? 'draft') as String,
      modelName: map['model_name'] as String?,
      ttsEngine: map['tts_engine'] as String?,
      reviewJson: map['review_json'] as String?,
      costEstimate: (map['cost_estimate'] as num?)?.toDouble(),
    );
  }
}

class MessageRecord {
  const MessageRecord({
    required this.id,
    required this.sessionId,
    required this.seq,
    required this.role,
    required this.textEn,
    this.textZh,
    this.audioPath,
    this.asrProvider,
    this.latencyMs,
    this.isHint = false,
    this.hintLevel,
    this.status = 'ok',
    required this.createdAt,
  });

  final String id;
  final String sessionId;
  final int seq;
  final String role;
  final String textEn;
  final String? textZh;
  final String? audioPath;
  final String? asrProvider;
  final int? latencyMs;
  final bool isHint;
  final int? hintLevel;
  final String status;
  final int createdAt;

  bool get isUser => role == 'user';

  MessageRecord copyWith({
    String? textEn,
    String? textZh,
    String? audioPath,
    String? asrProvider,
    int? latencyMs,
    bool? isHint,
    int? hintLevel,
    String? status,
  }) {
    return MessageRecord(
      id: id,
      sessionId: sessionId,
      seq: seq,
      role: role,
      textEn: textEn ?? this.textEn,
      textZh: textZh ?? this.textZh,
      audioPath: audioPath ?? this.audioPath,
      asrProvider: asrProvider ?? this.asrProvider,
      latencyMs: latencyMs ?? this.latencyMs,
      isHint: isHint ?? this.isHint,
      hintLevel: hintLevel ?? this.hintLevel,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'session_id': sessionId,
        'seq': seq,
        'role': role,
        'text_en': textEn,
        'text_zh': textZh,
        'audio_path': audioPath,
        'asr_provider': asrProvider,
        'latency_ms': latencyMs,
        'is_hint': isHint ? 1 : 0,
        'hint_level': hintLevel,
        'status': status,
        'created_at': createdAt,
      };

  factory MessageRecord.fromMap(Map<String, Object?> map) {
    return MessageRecord(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      seq: (map['seq'] as num?)?.toInt() ?? 0,
      role: (map['role'] ?? 'assistant') as String,
      textEn: (map['text_en'] ?? '') as String,
      textZh: map['text_zh'] as String?,
      audioPath: map['audio_path'] as String?,
      asrProvider: map['asr_provider'] as String?,
      latencyMs: (map['latency_ms'] as num?)?.toInt(),
      isHint: ((map['is_hint'] as num?)?.toInt() ?? 0) == 1,
      hintLevel: (map['hint_level'] as num?)?.toInt(),
      status: (map['status'] ?? 'ok') as String,
      createdAt: (map['created_at'] as num?)?.toInt() ?? 0,
    );
  }
}

class Correction {
  const Correction({
    required this.id,
    required this.sessionId,
    required this.messageId,
    required this.original,
    required this.improved,
    required this.reasonZh,
    this.audioPath,
    this.isDeleted = false,
    required this.createdAt,
  });

  final String id;
  final String sessionId;
  final String messageId;
  final String original;
  final String improved;
  final String reasonZh;
  final String? audioPath;
  final bool isDeleted;
  final int createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'session_id': sessionId,
        'message_id': messageId,
        'original': original,
        'improved': improved,
        'reason_zh': reasonZh,
        'audio_path': audioPath,
        'is_deleted': isDeleted ? 1 : 0,
        'created_at': createdAt,
      };

  factory Correction.fromMap(Map<String, Object?> map) => Correction(
        id: map['id'] as String,
        sessionId: map['session_id'] as String,
        messageId: (map['message_id'] ?? '') as String,
        original: (map['original'] ?? '') as String,
        improved: (map['improved'] ?? '') as String,
        reasonZh: (map['reason_zh'] ?? '') as String,
        audioPath: map['audio_path'] as String?,
        isDeleted: ((map['is_deleted'] as num?)?.toInt() ?? 0) == 1,
        createdAt: (map['created_at'] as num?)?.toInt() ?? 0,
      );
}

class Phrase {
  const Phrase({
    required this.id,
    required this.textEn,
    this.textZh,
    this.sourceSessionId,
    this.sourceScenarioId,
    this.audioPath,
    this.mastered = false,
    required this.createdAt,
  });

  final String id;
  final String textEn;
  final String? textZh;
  final String? sourceSessionId;
  final String? sourceScenarioId;
  final String? audioPath;
  final bool mastered;
  final int createdAt;

  Phrase copyWith({
    String? textEn,
    String? textZh,
    bool? mastered,
    int? createdAt,
  }) => Phrase(
        id: id,
        textEn: textEn ?? this.textEn,
        textZh: textZh ?? this.textZh,
        sourceSessionId: sourceSessionId,
        sourceScenarioId: sourceScenarioId,
        audioPath: audioPath,
        mastered: mastered ?? this.mastered,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'text_en': textEn,
        'text_zh': textZh,
        'source_session_id': sourceSessionId,
        'source_scenario_id': sourceScenarioId,
        'audio_path': audioPath,
        'mastered': mastered ? 1 : 0,
        'created_at': createdAt,
      };

  factory Phrase.fromMap(Map<String, Object?> map) => Phrase(
        id: map['id'] as String,
        textEn: (map['text_en'] ?? '') as String,
        textZh: map['text_zh'] as String?,
        sourceSessionId: map['source_session_id'] as String?,
        sourceScenarioId: map['source_scenario_id'] as String?,
        audioPath: map['audio_path'] as String?,
        mastered: ((map['mastered'] as num?)?.toInt() ?? 0) == 1,
        createdAt: (map['created_at'] as num?)?.toInt() ?? 0,
      );
}

class LlmProfile {
  const LlmProfile({
    required this.id,
    this.name = '主力模型',
    required this.baseUrl,
    required this.model,
    required this.keyRef,
    this.extraJson,
    this.lastCheckStatus = 'never',
    this.lastCheckMessage,
    this.lastCheckedAt,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String baseUrl;
  final String model;
  final String keyRef;
  final String? extraJson;
  final String lastCheckStatus;
  final String? lastCheckMessage;
  final int? lastCheckedAt;
  final bool isActive;

  LlmProfile copyWith({
    String? name,
    String? baseUrl,
    String? model,
    String? keyRef,
    String? lastCheckStatus,
    String? lastCheckMessage,
    int? lastCheckedAt,
    bool? isActive,
  }) {
    return LlmProfile(
      id: id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      keyRef: keyRef ?? this.keyRef,
      extraJson: extraJson,
      lastCheckStatus: lastCheckStatus ?? this.lastCheckStatus,
      lastCheckMessage: lastCheckMessage ?? this.lastCheckMessage,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'base_url': baseUrl,
        'model': model,
        'key_ref': keyRef,
        'extra_json': extraJson,
        'last_check_status': lastCheckStatus,
        'last_check_message': lastCheckMessage,
        'last_checked_at': lastCheckedAt,
        'is_active': isActive ? 1 : 0,
      };

  factory LlmProfile.fromMap(Map<String, Object?> map) => LlmProfile(
        id: map['id'] as String,
        name: (map['name'] ?? '主力模型') as String,
        baseUrl: (map['base_url'] ?? '') as String,
        model: (map['model'] ?? '') as String,
        keyRef: (map['key_ref'] ?? '') as String,
        extraJson: map['extra_json'] as String?,
        lastCheckStatus: (map['last_check_status'] ?? 'never') as String,
        lastCheckMessage: map['last_check_message'] as String?,
        lastCheckedAt: (map['last_checked_at'] as num?)?.toInt(),
        isActive: ((map['is_active'] as num?)?.toInt() ?? 1) == 1,
      );
}

class TtsCacheEntry {
  const TtsCacheEntry({
    required this.hash,
    required this.engine,
    required this.voice,
    required this.rate,
    required this.filePath,
    required this.bytes,
    required this.createdAt,
    required this.lastUsedAt,
  });

  final String hash;
  final String engine;
  final String voice;
  final double rate;
  final String filePath;
  final int bytes;
  final int createdAt;
  final int lastUsedAt;

  Map<String, Object?> toMap() => {
        'hash': hash,
        'engine': engine,
        'voice': voice,
        'rate': rate,
        'file_path': filePath,
        'bytes': bytes,
        'created_at': createdAt,
        'last_used_at': lastUsedAt,
      };

  factory TtsCacheEntry.fromMap(Map<String, Object?> map) => TtsCacheEntry(
        hash: map['hash'] as String,
        engine: (map['engine'] ?? '') as String,
        voice: (map['voice'] ?? '') as String,
        rate: (map['rate'] as num?)?.toDouble() ?? 1.0,
        filePath: (map['file_path'] ?? '') as String,
        bytes: (map['bytes'] as num?)?.toInt() ?? 0,
        createdAt: (map['created_at'] as num?)?.toInt() ?? 0,
        lastUsedAt: (map['last_used_at'] as num?)?.toInt() ?? 0,
      );
}

class SettingsKeys {
  SettingsKeys._();

  static const ttsEngine = 'tts.engine';
  static const ttsVoice = 'tts.voice';
  static const ttsRate = 'tts.rate';
  static const ttsAutoPlay = 'tts.autoPlay';
  static const level = 'practice.level';
  static const correctionMode = 'practice.correctionMode';
  static const translateDefault = 'practice.translateDefault';
  static const inputMode = 'practice.inputMode';
  static const targetMinutes = 'practice.targetMinutes';
  static const cacheLimitMb = 'data.cacheLimitMb';
  static const monthlyBudget = 'cost.monthlyBudget';
  // 语音识别配置，与对话模型配置完全独立
  static const asrBaseUrl = 'asr.baseUrl';
  static const asrModel = 'asr.model';
  static const asrLanguage = 'asr.language';
  static const asrKeyRef = 'asr_api_key';
  // 实验：用对话模型（input_audio）做识别，默认关闭
  static const asrExperimentalEnabled = 'asr.experimental.enabled';
  static const asrExperimentalBaseUrl = 'asr.experimental.baseUrl';
  static const asrExperimentalModel = 'asr.experimental.model';
  static const asrExperimentalKeyRef = 'asr_experimental_api_key';
  // 二期：单句听写判分与播放（判分不依赖网络与模型）
  static const dictationPassThreshold = 'dictation.passThreshold';
  static const dictationContractionEquivalent = 'dictation.contractionEquivalent';
  static const dictationNumberEquivalent = 'dictation.numberEquivalent';
  static const dictationSpeed = 'dictation.speed';
  // B 站导入：配套服务地址（局域网 Python 服务）与用户自己的 B 站 Cookie
  static const dictationCompanionUrl = 'dictation.companionUrl';
  static const dictationBiliCookie = 'dictation.biliCookie';
}

class ReviewCorrection {
  const ReviewCorrection({
    required this.original,
    required this.improved,
    required this.reasonZh,
  });

  final String original;
  final String improved;
  final String reasonZh;

  Map<String, Object?> toJson() => {
        'original': original,
        'improved': improved,
        'reason': reasonZh,
      };

  factory ReviewCorrection.fromJson(Map<String, Object?> json) => ReviewCorrection(
        original: (json['original'] ?? '') as String,
        improved: (json['improved'] ?? '') as String,
        reasonZh: (json['reason'] ?? '') as String,
      );
}

class ReviewResult {
  const ReviewResult({
    required this.highlight,
    required this.corrections,
    required this.phrases,
    required this.nextTip,
    this.promptCount = 0,
    this.degraded = false,
  });

  final String highlight;
  final List<ReviewCorrection> corrections;
  final List<String> phrases;
  final String nextTip;
  final int promptCount;

  /// 模型没有按约定格式返回时的兜底标记；复盘页据此显示「重试」。
  final bool degraded;

  Map<String, Object?> toJson() => {
        'highlight': highlight,
        'corrections': corrections.map((e) => e.toJson()).toList(),
        'phrases': phrases,
        'nextTip': nextTip,
        'promptCount': promptCount,
        if (degraded) 'degraded': true,
      };

  String encode() => jsonEncode(toJson());

  factory ReviewResult.fromJson(Map<String, Object?> json) => ReviewResult(
        highlight: (json['highlight'] ?? '') as String,
        corrections: ((json['corrections'] as List?) ?? const [])
            .map((e) => ReviewCorrection.fromJson((e as Map).cast<String, Object?>()))
            .toList(),
        phrases: ((json['phrases'] as List?) ?? const []).map((e) => e.toString()).toList(),
        nextTip: (json['nextTip'] ?? '') as String,
        promptCount: (json['promptCount'] as num?)?.toInt() ?? 0,
        degraded: json['degraded'] == true,
      );

  static ReviewResult? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is Map) return ReviewResult.fromJson(map.cast<String, Object?>());
    } catch (_) {
      return null;
    }
    return null;
  }
}
