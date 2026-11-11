import '../../domain/models/models.dart';
import 'llm_models.dart';

class PromptBuilder {
  PromptBuilder._();

  static String chatSystem(Scenario scenario, String level) {
    return '''
You are playing a role in an English speaking practice app. Stay in character at all times.

Scenario: ${scenario.titleZh} / ${scenario.titleEn}
Your role: ${scenario.aiRole}
User goal: ${scenario.userGoal}
Success criteria: ${scenario.successCriteria}
${scenario.branchHint == null ? '' : 'Branch hint: ${scenario.branchHint}'}
${scenario.targetPhrases.isEmpty ? '' : 'Target phrases: ${scenario.targetPhrases.join(' | ')}'}

Rules:
- Reply in natural English only. Never use Chinese unless the user explicitly asks.
- When it fits naturally, elicit or reuse the target phrases; never list them, quiz the user, or force them in.
- Keep every reply to 1-2 short sentences, then ask exactly one question to keep the conversation going.
- Use vocabulary and grammar at $level level. Do not correct the user inside the role-play.
- Never mention that you are an AI, a model, or a prompt.
- If the user is silent or unclear, gently prompt them with a simple question.
'''.trim();
  }

  static List<LlmMessage> chatMessages({
    required Scenario scenario,
    required String level,
    required List<MessageRecord> history,
    int maxTurns = 16,
  }) {
    final recent = history.where((m) => m.status == 'ok' && m.textEn.trim().isNotEmpty).toList();
    final sliced = recent.length > maxTurns ? recent.sublist(recent.length - maxTurns) : recent;
    return [
      LlmMessage.system(chatSystem(scenario, level)),
      for (final message in sliced)
        LlmMessage(
          message.role == 'user' ? 'user' : 'assistant',
          message.textEn,
        ),
    ];
  }

  static List<LlmMessage> reviewMessages({
    required Scenario? scenario,
    required List<MessageRecord> history,
  }) {
    final transcript = StringBuffer();
    for (final message in history) {
      if (message.status != 'ok') continue;
      if (message.isHint) continue;
      transcript.writeln('${message.role == 'user' ? 'User' : 'AI'}: ${message.textEn}');
    }
    return [
      LlmMessage.system(
        'You are a strict but encouraging English speaking coach. '
        'Analyse the learner transcript and reply in Chinese with the exact format below. '
        'Do not use markdown, do not add extra sections.',
      ),
      LlmMessage.user('''
Scenario: ${scenario?.titleZh ?? '自由对话'}
Learner level: ${scenario?.level ?? 'B1'}

Transcript:
$transcript

Reply exactly in this format:
亮点: <one sentence in Chinese>
纠错:
1. <original sentence> || <improved sentence> || <reason in Chinese, max 25 words>
2. ...
表达:
- <one natural English phrase from or for this scenario>
- <another phrase>
下次: <one actionable tip in Chinese>

Rules: at most 4 corrections, at most 5 phrases. If there are no clear mistakes, still give 1 improvement.
'''),
    ];
  }

  /// L2–L4 提示（L1 是重听/慢速，不请求模型）。
  ///
  /// 只用「最近一条 AI 发言 + 本轮指令」组成独立上下文，绝不复用主对话历史。
  /// 一次请求同时返回英文提示与中文对照，避免再单独发一次翻译请求。
  static List<LlmMessage> hintMessages({
    required Scenario? scenario,
    required int level,
    required List<MessageRecord> history,
    String chinese = '',
  }) {
    final lastAi = history.lastWhere(
      (m) => m.role == 'assistant' && !m.isHint,
      orElse: () => const MessageRecord(
        id: 'empty',
        sessionId: '',
        seq: 0,
        role: 'assistant',
        textEn: '',
        createdAt: 0,
      ),
    );
    final instruction = switch (level) {
      2 => 'Give 3-5 English keywords OR one short sentence pattern the learner could use next. '
          'Never give a complete sentence, never explain.',
      3 => 'Give exactly ONE complete natural English sentence the learner could say next. '
          'No alternatives, no quotes, no explanation.',
      4 => 'Translate the learner\'s Chinese idea into exactly ONE natural English sentence '
          'they could say out loud. Output English only.',
      _ => 'Give exactly ONE complete natural English sentence the learner could say next. '
          'No quotes, no explanation.',
    };
    final prompt = level == 4
        ? 'AI just said: "${lastAi.textEn}"\n'
            'Learner wants to say in Chinese: "$chinese"\n$instruction'
        : 'AI just said: "${lastAi.textEn}"\n$instruction';
    return [
      LlmMessage.system(
        'You help a learner continue an English role-play. '
        'Output exactly TWO plain-text lines and nothing else:\n'
        'EN: <the English hint only>\n'
        'ZH: <a concise Simplified Chinese translation of that English hint only>\n'
        'No reasoning, no markdown, no quotes, no extra lines. '
        'Scenario: ${scenario?.titleZh ?? 'daily conversation'}.',
      ),
      LlmMessage.user(prompt),
    ];
  }

  /// 「我想说」：中文 → 一句可直接说的英文（同样走独立上下文）。
  static List<LlmMessage> wantToSayMessages(Scenario? scenario, String chinese) {
    return [
      LlmMessage.system(
        'You are an English speaking coach. Convert the learner\'s Chinese idea into '
        'exactly ONE short, natural English sentence they can say out loud. '
        'Output the English sentence only: no Chinese, no quotes, no explanation. '
        'Scenario: ${scenario?.titleZh ?? 'daily conversation'}.',
      ),
      LlmMessage.user(chinese),
    ];
  }

  /// 回答句「优化句子」：与提示 / 翻译一样走独立上下文，不进主对话历史。
  static List<LlmMessage> improveMessages(String text, Scenario? scenario) {
    return [
      LlmMessage.system(
        'You are a friendly English speaking coach. Rewrite the learner sentence to sound '
        'natural and idiomatic while keeping the exact meaning and roughly the same length. '
        'Output exactly TWO plain-text lines and nothing else:\n'
        'BETTER: <the improved English sentence only>\n'
        'WHY: <one short Simplified Chinese reason, max 25 words>\n'
        'No reasoning, no markdown, no quotes, no extra lines.',
      ),
      LlmMessage.user(
        'Scenario: ${scenario?.titleZh ?? 'daily conversation'}\n'
        'Learner said: "$text"',
      ),
    ];
  }

  static List<LlmMessage> translateMessages(String text) {
    return [
      LlmMessage.system(
        'You are a translation engine. Translate the user English sentence into concise Simplified Chinese. '
        'Output the Chinese translation on the FIRST line only: no reasoning, no English, '
        'no quotes, no markdown, no explanation.',
      ),
      LlmMessage.user(text),
    ];
  }

  /// 翻译旁路结果清洗：取第一行含中文的正文，丢掉思考过程、解释与引号。
  /// 没有中文时返回空串，由调用方给出「重试翻译」，不把英文原文当译文展示。
  static String cleanTranslation(String raw) {
    for (final item in raw.split('\n')) {
      var line = item.trim().replaceAll('**', '').replaceAll('`', '');
      line = line.replaceFirst(RegExp(r'^[-*>]\s+'), '').trim();
      line = line.replaceFirst(RegExp(r'^\d+[.)]\s+'), '').trim();
      line = line.replaceFirst(RegExp(r'^(译文|翻译|中文|译)\s*[:：]\s*'), '').trim();
      if (line.length > 1 && line.startsWith('"') && line.endsWith('"')) {
        line = line.substring(1, line.length - 1).trim();
      }
      if (RegExp(r'[\u4e00-\u9fff]').hasMatch(line)) return line;
    }
    return '';
  }

  static List<LlmMessage> phraseMessages(Scenario? scenario) {
    return [
      LlmMessage.system(
        'You are an English coach. Output exactly one natural, useful English sentence for this scenario. '
        'No Chinese, no quotes, no explanation.',
      ),
      LlmMessage.user('Scenario: ${scenario?.titleZh ?? 'daily conversation'}'),
    ];
  }
}

class ReviewParser {
  ReviewParser._();

  static ReviewResult parse(String raw) {
    final lines = raw.split('\n').map((e) => e.trim()).toList();
    var highlight = '';
    var nextTip = '';
    final corrections = <ReviewCorrection>[];
    final phrases = <String>[];
    var section = '';

    for (final line in lines) {
      if (line.isEmpty) continue;
      final normalized = line.replaceAll('**', '').replaceAll('：', ':');
      if (normalized.startsWith('亮点')) {
        highlight = normalized.split(':').skip(1).join(':').trim();
        section = 'highlight';
        continue;
      }
      if (normalized.startsWith('纠错')) {
        section = 'corrections';
        continue;
      }
      if (normalized.startsWith('表达')) {
        section = 'phrases';
        continue;
      }
      if (normalized.startsWith('下次')) {
        nextTip = normalized.split(':').skip(1).join(':').trim();
        section = 'tip';
        continue;
      }

      if (section == 'corrections') {
        final cleaned = normalized.replaceFirst(RegExp(r'^\d+[\.\)、]\s*'), '');
        final parts = cleaned.split('||');
        if (parts.length >= 3) {
          corrections.add(ReviewCorrection(
            original: _strip(parts[0]),
            improved: _strip(parts[1]),
            reasonZh: _strip(parts.sublist(2).join('||')),
          ));
        }
      } else if (section == 'phrases') {
        final cleaned = normalized.replaceFirst(RegExp(r'^[-*•]\s*'), '').trim();
        if (cleaned.isNotEmpty) phrases.add(cleaned);
      } else if (section == 'highlight') {
        highlight = '$highlight $normalized'.trim();
      } else if (section == 'tip') {
        nextTip = '$nextTip $normalized'.trim();
      }
    }

    if (corrections.isEmpty && raw.trim().isNotEmpty) {
      // 模型可能没有按格式返回：标记 degraded，复盘页显示「未能生成总结 + 重试」。
      return ReviewResult(
        highlight: highlight.isEmpty ? '本次未能生成总结' : highlight,
        corrections: const [],
        phrases: phrases.take(5).toList(),
        nextTip: nextTip.isEmpty ? '可以重试一次，或直接继续下次练习。' : nextTip,
        degraded: highlight.isEmpty || phrases.isEmpty,
      );
    }

    return ReviewResult(
      highlight: highlight.isEmpty ? '你完成了这次练习，继续保持。' : highlight,
      corrections: corrections.take(4).toList(),
      phrases: phrases.take(5).toList(),
      nextTip: nextTip.isEmpty ? '下次练习试着多用今天学到的表达。' : nextTip,
    );
  }

  static String _strip(String value) {
    var out = value.trim();
    if (out.startsWith('"') && out.endsWith('"') && out.length > 1) {
      out = out.substring(1, out.length - 1);
    }
    return out.trim();
  }
}

/// 解析提示旁路的两行输出（EN: / ZH:）。模型没按格式返回时，
/// 退化为「第一行英文、第二行含中文才当译文」，保证旧模型也能用。
class HintParser {
  HintParser._();

  static ({String en, String? zh}) parse(String raw) {
    var en = '';
    var zh = '';
    for (final item in raw.split('\n')) {
      final line = _strip(item);
      if (line.isEmpty || line == '```') continue;
      final labeled = RegExp(r'^(EN|ZH)\s*[:：]\s*(.*)$', caseSensitive: false).firstMatch(line);
      if (labeled != null) {
        final value = _strip(labeled.group(2)!);
        if (labeled.group(1)!.toUpperCase() == 'EN') {
          en = value;
        } else {
          zh = value;
        }
        continue;
      }
      if (en.isEmpty) {
        en = line;
      } else if (zh.isEmpty && _hasChinese(line)) {
        zh = line;
      }
    }
    if (!_hasChinese(zh)) zh = '';
    return (en: en, zh: zh.isEmpty ? null : zh);
  }

  static bool _hasChinese(String value) => RegExp(r'[\u4e00-\u9fff]').hasMatch(value);

  static String _strip(String value) {
    var out = value.trim().replaceAll('**', '').replaceAll('`', '');
    out = out.replaceFirst(RegExp(r'^[-*>]\s+'), '').trim();
    out = out.replaceFirst(RegExp(r'^(译文|翻译|中文|译)\s*[:：]\s*'), '').trim();
    if (out.length > 1 && out.startsWith('"') && out.endsWith('"')) {
      out = out.substring(1, out.length - 1).trim();
    }
    return out;
  }
}

/// 解析「优化句子」旁路的两行输出（BETTER: / WHY:）。
/// 模型没按格式返回时退化为「第一行英文、第二行含中文当理由」，避免整块空白。
class ImprovementParser {
  ImprovementParser._();

  static ({String improved, String reasonZh}) parse(String raw) {
    var improved = '';
    var reason = '';
    for (final item in raw.split('\n')) {
      final line = _strip(item);
      if (line.isEmpty || line == '```') continue;
      final labeled = RegExp(r'^(BETTER|WHY|理由|原因)\s*[:：]\s*(.*)$', caseSensitive: false)
          .firstMatch(line);
      if (labeled != null) {
        final value = _strip(labeled.group(2)!);
        final tag = labeled.group(1)!.toUpperCase();
        if (tag == 'BETTER') {
          improved = value;
        } else {
          reason = value;
        }
        continue;
      }
      if (improved.isEmpty) {
        improved = line;
      } else if (reason.isEmpty && _hasChinese(line)) {
        reason = line;
      }
    }
    if (improved.isEmpty || _hasChinese(improved)) improved = '';
    if (!_hasChinese(reason)) reason = '';
    return (improved: improved, reasonZh: reason);
  }

  static bool _hasChinese(String value) => RegExp(r'[\u4e00-\u9fff]').hasMatch(value);

  static String _strip(String value) {
    var out = value.trim().replaceAll('**', '').replaceAll('`', '');
    out = out.replaceFirst(RegExp(r'^[-*>]\s+'), '').trim();
    out = out.replaceFirst(RegExp(r'^\d+[.)]\s+'), '').trim();
    if (out.length > 1 && out.startsWith('"') && out.endsWith('"')) {
      out = out.substring(1, out.length - 1).trim();
    }
    return out;
  }
}
