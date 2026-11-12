import '../../domain/models/models.dart';
import '../retention/review_item.dart';

/// M12 只读学习者档案：只从本地既有表的**文本字段**聚合，供主对话 `chatSystem` 使用。
///
/// 硬约束（需求 §0.3 第 8 条）：
/// - 只取尾部 N 次会话；不读 `session.review_json` 全文、不读表达本音频、不调用模型；
/// - 固定 3 类信息：1–2 类常犯错误、最多 3 条已掌握表达、上次话题；
/// - 每段与整块都有长度上限，可在设置里一键关闭；
/// - 结果不写回任何业务表，也绝不进入旁路 `SessionContext`。
const int learnerProfileMaxSessions = 6;
const int learnerProfileMaxWeakSpots = 2;
const int learnerProfileMaxMastered = 3;
const int learnerProfileMaxItemChars = 48;
const int learnerProfileMaxBlockChars = 420;

/// 一键加压的两个显式指令：只影响下一回合，不自动发送、不改已发消息。
const Map<String, String> kPressureOptions = <String, String>{
  'angle': '换个角度追问',
  'harder': '提高难度',
};

const Map<String, String> kPressureInstructions = <String, String>{
  'angle': 'Change the angle: ask about a different aspect of the same situation, '
      'not the same question type again.',
  'harder': 'Raise the difficulty one small step: use one richer expression or '
      'ask for a reason or a detail, but keep the learner level.',
};

class LearnerProfileInput {
  const LearnerProfileInput({
    required this.enabled,
    required this.sessions,
    required this.correctionsBySession,
    required this.reviewItems,
    required this.phrases,
    required this.scenarios,
    required this.currentSessionId,
  });

  /// 设置里的开关；关闭时整个聚合直接返回 null，`chatSystem` 回到 M8 原文。
  final bool enabled;
  final List<SessionRecord> sessions;
  final Map<String, List<Correction>> correctionsBySession;
  final List<ReviewItem> reviewItems;
  final List<Phrase> phrases;
  final List<Scenario> scenarios;
  final String currentSessionId;
}

class LearnerProfile {
  const LearnerProfile({
    required this.weakSpots,
    required this.mastered,
    this.lastTopic,
  });

  final List<String> weakSpots;
  final List<String> mastered;
  final String? lastTopic;

  bool get isEmpty =>
      weakSpots.isEmpty &&
      mastered.isEmpty &&
      (lastTopic == null || lastTopic!.isEmpty);

  String render() {
    final lines = <String>[];
    if (weakSpots.isNotEmpty) {
      lines.add('Recurring weak spots: ${weakSpots.join('; ')}');
    }
    if (mastered.isNotEmpty) {
      lines.add('Expressions already mastered: ${mastered.join(' | ')}');
    }
    if (lastTopic != null && lastTopic!.isNotEmpty) {
      lines.add('Last topic: $lastTopic');
    }
    final out = lines.join('\n');
    return out.length > learnerProfileMaxBlockChars
        ? out.substring(0, learnerProfileMaxBlockChars)
        : out;
  }
}

String _clip(String value) {
  final clean = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  return clean.length > learnerProfileMaxItemChars
      ? clean.substring(0, learnerProfileMaxItemChars)
      : clean;
}

/// 把复盘给过的中文理由归成少量「类型」，避免在 prompt 里塞整句理由或用户原文。
String _weakCategory(String raw) {
  final text = raw.toLowerCase();
  if (text.contains('时态') || text.contains('tense') || text.contains('过去式')) {
    return '时态';
  }
  if (text.contains('介词') || text.contains('preposition')) return '介词';
  if (text.contains('冠词') || text.contains('article')) return '冠词';
  if (text.contains('语序') || text.contains('word order')) return '语序';
  if (text.contains('礼貌') || text.contains('委婉') || text.contains('polite')) {
    return '语气礼貌';
  }
  if (text.contains('中式') || text.contains('直译')) return '中式直译';
  return '更自然的用词';
}

/// 纯函数聚合；不联网、不读模型、不写库。关闭开关时返回 null。
LearnerProfile? buildLearnerProfile(LearnerProfileInput input) {
  if (!input.enabled) return null;

  final sorted = <SessionRecord>[...input.sessions]
    ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  final recent = sorted
      .where((session) => session.id != input.currentSessionId)
      .take(learnerProfileMaxSessions)
      .toList();

  final counts = <String, int>{};
  for (final session in recent) {
    for (final correction
        in input.correctionsBySession[session.id] ?? const <Correction>[]) {
      if (correction.isDeleted) continue;
      if (correction.reasonZh.trim().isEmpty &&
          correction.improved.trim().isEmpty) {
        continue;
      }
      final category = _weakCategory(
        '${correction.reasonZh} ${correction.original} ${correction.improved}',
      );
      counts[category] = (counts[category] ?? 0) + 1;
    }
  }
  final ranked = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final weakSpots = ranked
      .take(learnerProfileMaxWeakSpots)
      .map((entry) => _clip(entry.key))
      .toList();

  final mastered = <String>[];
  final seen = <String>{};
  void add(String text) {
    if (mastered.length >= learnerProfileMaxMastered) return;
    final clean = _clip(text);
    if (clean.isEmpty) return;
    final key = clean.toLowerCase();
    if (!seen.add(key)) return;
    mastered.add(clean);
  }

  final consolidated = <ReviewItem>[
    ...input.reviewItems.where((item) => item.consolidated),
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  for (final item in consolidated) {
    add(item.textEn);
  }
  final masteredPhrases = <Phrase>[
    ...input.phrases.where((phrase) => phrase.mastered),
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  for (final phrase in masteredPhrases) {
    add(phrase.textEn);
  }

  String? lastTopic;
  for (final session in recent) {
    final id = session.scenarioId;
    if (id == null || id.isEmpty) continue;
    for (final scenario in input.scenarios) {
      if (scenario.id == id) {
        lastTopic = _clip('${scenario.titleZh} / ${scenario.titleEn}');
        break;
      }
    }
    if (lastTopic != null) break;
  }

  return LearnerProfile(
    weakSpots: weakSpots,
    mastered: mastered,
    lastTopic: lastTopic,
  );
}
