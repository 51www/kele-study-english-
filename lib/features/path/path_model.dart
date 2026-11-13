import 'dart:convert';

import '../../domain/models/models.dart';
import '../me/metrics.dart';

/// M14 学习路径：状态存 `app_meta` 单键，零改表。
/// 所有字段都可空兜底；旧值 / 坏值一律回落到「未配置」，不让页面崩。
const String pathMetaKey = 'learningPath.v1';
const int pathStateVersion = 1;

const List<String> pathGoalKeys = <String>['work', 'travel', 'daily', 'general'];
const Map<String, String> pathGoalLabels = <String, String>{
  'work': '工作沟通',
  'travel': '旅行出行',
  'daily': '日常生活',
  'general': '综合提升',
};

const Map<String, String> pathStatusLabels = <String, String>{
  'pending': '未开始',
  'done': '已完成',
  'consolidating': '待巩固',
  'skipped': '今天跳过',
};

/// 阶段安排里的一条。状态里的 items 只保存「用户显式跳过 / 手工完成」的覆盖项，
/// 基础清单每次按实际场景库动态生成，避免场景扩容后计划失效。
class PathItem {
  const PathItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.reason,
    this.scenarioId,
    this.status = 'pending',
    this.skippedOn = '',
    this.updatedAt = 0,
  });

  final String id;
  final String kind;
  final String title;
  final String reason;
  final String? scenarioId;
  final String status;
  final String skippedOn;
  final int updatedAt;

  String get route => switch (kind) {
        'scene' => '/scenario/${scenarioId ?? ''}',
        'review' => '/retention',
        'material' => '/materials',
        'wrong' => '/materials/wrong',
        _ => '/quick',
      };

  PathItem copyWith({
    String? status,
    String? skippedOn,
    int? updatedAt,
    String? reason,
  }) =>
      PathItem(
        id: id,
        kind: kind,
        title: title,
        reason: reason ?? this.reason,
        scenarioId: scenarioId,
        status: status ?? this.status,
        skippedOn: skippedOn ?? this.skippedOn,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'kind': kind,
        'title': title,
        'reason': reason,
        'scenarioId': scenarioId,
        'status': status,
        'skippedOn': skippedOn,
        'updatedAt': updatedAt,
      };

  static PathItem? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final map = raw.cast<String, Object?>();
    final id = map['id'];
    if (id is! String || id.isEmpty) return null;
    return PathItem(
      id: id,
      kind: map['kind'] is String ? map['kind']! as String : 'quick',
      title: map['title'] is String ? map['title']! as String : '练习',
      reason: map['reason'] is String ? map['reason']! as String : '',
      scenarioId: map['scenarioId'] is String ? map['scenarioId']! as String : null,
      status: map['status'] is String ? map['status']! as String : 'pending',
      skippedOn: map['skippedOn'] is String ? map['skippedOn']! as String : '',
      updatedAt: map['updatedAt'] is int ? map['updatedAt']! as int : 0,
    );
  }
}

class PathStage {
  const PathStage({
    required this.index,
    required this.name,
    required this.goal,
    required this.scope,
    required this.order,
    required this.criteria,
  });

  final int index;
  final String name;
  final String goal;
  final String scope;
  final String order;
  final List<String> criteria;
}

/// 四阶段是「导航」，不是关卡：不设固定周数，按完成标准推进。
const List<PathStage> kPathStages = <PathStage>[
  PathStage(
    index: 1,
    name: '开口起步',
    goal: '开场不卡，能独立说满一次完整对话。',
    scope: '难度较低、回合较短的日常类场景；每场 5 条目标表达与 3 件小事；课前 60 秒热身可选；翻译默认关，卡住先用重听 / 关键词台阶。',
    order: '热身（可跳过）→ 10 分钟对话 → 复盘只挑 1 个重点 → 90 秒开口 → 次日复练。',
    criteria: <String>[
      '连续 3 次会话都达到 ≥8 回合、提示 ≤3 次、3 件小事里 ≥2 件达成',
      '复练队列里至少 3 条进入「已巩固」',
      '表达本存下至少 6 条',
    ],
  ),
  PathStage(
    index: 2,
    name: '稳定表达',
    goal: '不依赖翻译和参考答案把熟悉的场景聊完，上次改过的说法能再用出来。',
    scope: '同一批场景的第二次练习 + 与目标相关的工作 / 社交场景；意外追问、提高难度、换角度追问。',
    order: '先清到期复练 → 同场景再练一次并加压 → 复盘对比上次 → 把改法送回复练队列。',
    criteria: <String>[
      '最近 3 次翻译查看 ≤30%、参考回答 / 中→英 ≤1 次、3 件小事里 ≥2 件达成',
      '本周有效练习 ≥3 次、每次 ≥8 分钟',
      '上次的改法在后续对话里用对（样本不足时显示「样本不足」）',
    ],
  ),
  PathStage(
    index: 3,
    name: '场景拓展',
    goal: '把同一能力迁到不同场合，并开始听懂真实语速。',
    scope: '按目标筛出的多个分类场景 + 教材库听写 + 错句本「只练错句」+ 3 分钟轻量日。',
    order: '新场景 → 复盘 → 表达本 → 一段教材 → 错句复练 → 换分类。',
    criteria: <String>[
      '目标相关的分类都练过，每个场景 3 件小事里 ≥2 件达成',
      '教材 / 错句本有二次通过的练习记录',
      '近 4 周「提示使用率 / 改法复现率」趋势稳定向好',
    ],
  ),
  PathStage(
    index: 4,
    name: '自主运用',
    goal: '自己定场合、撑住长回合，并能说清薄弱项、自己安排巩固。',
    scope: '自建 / 一句话生成的场景、真实语速教材、深一层追问、低能量日 3 分钟轻量。',
    order: '自己挑本周重点 → 长回合对话 → 复盘只留 1 条重点 → 巩固 → 阶段回顾。',
    criteria: <String>[
      '高难场景连续达标、3 件小事全部达成、提示 ≤1 次',
      '薄弱项有「再练对」的证据',
      '月度自评「敢开口」≥4/5',
    ],
  ),
];

class LearningPathState {
  const LearningPathState({
    this.configured = false,
    this.goal = 'general',
    this.specificGoal = '',
    this.level = 'B1',
    this.targetMinutes = 10,
    this.sessionsPerWeek = 3,
    this.stage = 1,
    this.items = const <PathItem>[],
    this.alternativeIndex = 0,
    this.confidence = 3,
    this.createdAt = 0,
    this.updatedAt = 0,
  });

  final bool configured;
  final String goal;
  final String specificGoal;
  final String level;
  final int targetMinutes;
  final int sessionsPerWeek;
  final int stage;
  final List<PathItem> items;
  final int alternativeIndex;
  final int confidence;
  final int createdAt;
  final int updatedAt;

  String get goalLabel => pathGoalLabels[goal] ?? pathGoalLabels['general']!;

  LearningPathState copyWith({
    bool? configured,
    String? goal,
    String? specificGoal,
    String? level,
    int? targetMinutes,
    int? sessionsPerWeek,
    int? stage,
    List<PathItem>? items,
    int? alternativeIndex,
    int? confidence,
    int? createdAt,
    int? updatedAt,
  }) =>
      LearningPathState(
        configured: configured ?? this.configured,
        goal: goal ?? this.goal,
        specificGoal: specificGoal ?? this.specificGoal,
        level: level ?? this.level,
        targetMinutes: targetMinutes ?? this.targetMinutes,
        sessionsPerWeek: sessionsPerWeek ?? this.sessionsPerWeek,
        stage: stage ?? this.stage,
        items: items ?? this.items,
        alternativeIndex: alternativeIndex ?? this.alternativeIndex,
        confidence: confidence ?? this.confidence,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'version': pathStateVersion,
        'configured': configured,
        'goal': goal,
        'specificGoal': specificGoal,
        'level': level,
        'targetMinutes': targetMinutes,
        'sessionsPerWeek': sessionsPerWeek,
        'stage': stage,
        'items': items.map((e) => e.toJson()).toList(),
        'alternativeIndex': alternativeIndex,
        'confidence': confidence,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  String encode() => jsonEncode(toJson());

  static LearningPathState decode(String? raw) {
    if (raw == null || raw.isEmpty) return const LearningPathState();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const LearningPathState();
      final map = decoded.cast<String, Object?>();
      final rawItems = map['items'];
      final items = <PathItem>[];
      if (rawItems is List) {
        for (final entry in rawItems) {
          final item = PathItem.fromJson(entry);
          if (item != null) items.add(item);
        }
      }
      return LearningPathState(
        configured: map['configured'] == true,
        goal: map['goal'] is String ? map['goal']! as String : 'general',
        specificGoal:
            map['specificGoal'] is String ? map['specificGoal']! as String : '',
        level: map['level'] is String ? map['level']! as String : 'B1',
        targetMinutes: map['targetMinutes'] is int ? map['targetMinutes']! as int : 10,
        sessionsPerWeek:
            map['sessionsPerWeek'] is int ? map['sessionsPerWeek']! as int : 3,
        stage: map['stage'] is int
            ? (map['stage']! as int).clamp(1, kPathStages.length)
            : 1,
        items: items,
        alternativeIndex:
            map['alternativeIndex'] is int ? map['alternativeIndex']! as int : 0,
        confidence: map['confidence'] is int
            ? (map['confidence']! as int).clamp(1, 5)
            : 3,
        createdAt: map['createdAt'] is int ? map['createdAt']! as int : 0,
        updatedAt: map['updatedAt'] is int ? map['updatedAt']! as int : 0,
      );
    } catch (_) {
      return const LearningPathState();
    }
  }
}

/// 纯计算的输入快照：全部来自既有本地数据，无任何网络请求。
class PathSnapshot {
  const PathSnapshot({
    required this.sessions,
    required this.scenarios,
    required this.practiceCounts,
    required this.hintByScenario,
    required this.lastCompletedAtByScenario,
    required this.trends,
    required this.now,
    this.phrasesCount = 0,
    this.masteredCount = 0,
    this.dueCount = 0,
    this.consolidatedCount = 0,
    this.weekSessions = 0,
    this.todayMinutes = 0,
    this.materialCount = 0,
    this.materialPracticedCount = 0,
    this.levelSetting = 'B1',
  });

  final List<SessionRecord> sessions;
  final List<Scenario> scenarios;
  final Map<String, int> practiceCounts;
  final Map<String, int> hintByScenario;
  final Map<String, int> lastCompletedAtByScenario;
  final List<TrendSeries> trends;
  final DateTime now;
  final int phrasesCount;
  final int masteredCount;
  final int dueCount;
  final int consolidatedCount;
  final int weekSessions;
  final int todayMinutes;
  final int materialCount;
  final int materialPracticedCount;
  final String levelSetting;
}

class StageEvaluation {
  const StageEvaluation({
    required this.complete,
    required this.evidence,
    required this.pending,
  });

  /// 只表示「可以建议往前走」，不是分数。
  final bool complete;
  final List<String> evidence;
  final List<String> pending;
}

class PathPlan {
  const PathPlan({
    required this.configured,
    required this.state,
    required this.stage,
    required this.items,
    required this.scopeScenarioIds,
    required this.evaluation,
    required this.nextReason,
    required this.daysSinceLast,
    required this.dueCount,
    required this.weekSessions,
    required this.todayMinutes,
    this.next,
  });

  final bool configured;
  final LearningPathState state;
  final PathStage stage;
  final List<PathItem> items;
  final Set<String> scopeScenarioIds;
  final StageEvaluation evaluation;
  final PathItem? next;
  final String nextReason;
  final int daysSinceLast;
  final int dueCount;
  final int weekSessions;
  final int todayMinutes;

  int get doneCount => items.where((e) => e.status == 'done').length;
  int get pendingCount => items.where((e) => e.status == 'pending').length;
  String get nextRoute => next?.route ?? '/scenarios';
  String get nextTitle => next?.title ?? '今天先随便来一段';

  static PathPlan unconfigured(LearningPathState state) => PathPlan(
        configured: false,
        state: state,
        stage: kPathStages.first,
        items: const <PathItem>[],
        scopeScenarioIds: const <String>{},
        evaluation: const StageEvaluation(
          complete: false,
          evidence: <String>[],
          pending: <String>[],
        ),
        nextReason: '设定起点后，这里会给出今天该练什么。',
        daysSinceLast: 0,
        dueCount: 0,
        weekSessions: 0,
        todayMinutes: 0,
      );
}
