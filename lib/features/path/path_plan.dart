import '../../app/providers.dart' show quickSessionTag;
import '../../domain/models/models.dart';
import 'path_model.dart';

/// 四阶段计划的纯计算：不联网、不调模型、不写库。
/// 输入只有既有本地数据，输出可直接渲染的 [PathPlan]。
const Map<String, List<String>> kGoalCategories = <String, List<String>>{
  'work': <String>['工作', '观点', '数码线上', '政务金融'],
  'travel': <String>['旅行', '日常', '消费服务', '健康'],
  'daily': <String>['日常', '社交', '消费服务', '居住家政', '关系情绪'],
  // 综合：留空表示按场景库实际分类全取，不写死数量。
  'general': <String>[],
};

String dayKey(DateTime time) => '${time.year}-${time.month}-${time.day}';

int levelRank(String level) => switch (level.toUpperCase()) {
      'A2' => 0,
      'B1' => 1,
      'B2' => 2,
      'C1' => 3,
      _ => 1,
    };

/// 起点只由自评水平 + 历史练习量粗分，不做测评、不出等级。
/// 用户可在「改起点」里随时覆盖。
int suggestStageIndex(String level, int totalSessions) {
  final base = switch (level.toUpperCase()) {
    'A2' => 1,
    'B2' || 'C1' => 3,
    _ => 2,
  };
  if (totalSessions >= 6 && base < 3) return base + 1;
  return base;
}

/// 目标 → 实际存在的分类。分类数量与场景数量都由数据决定。
List<String> goalCategories(String goal, List<Scenario> scenarios) {
  final existing = scenarios.map((e) => e.category).toSet();
  final preset = kGoalCategories[goal] ?? const <String>[];
  if (preset.isEmpty) return existing.toList();
  final picked = preset.where(existing.contains).toList();
  return picked.isEmpty ? existing.toList() : picked;
}

List<Scenario> stageScenarios(int stage, String goal, PathSnapshot snap) {
  final focus = goalCategories(goal, snap.scenarios).toSet();
  var pool = snap.scenarios
      .where((s) => focus.isEmpty || focus.contains(s.category))
      .toList();
  final filtered = pool.where((s) {
    final rank = levelRank(s.level);
    return switch (stage) {
      1 => rank <= 0,
      2 => rank <= 1,
      3 => rank <= 2,
      _ => rank >= 2,
    };
  }).toList();
  if (filtered.isNotEmpty) pool = filtered;
  if (pool.isEmpty) pool = List<Scenario>.from(snap.scenarios);
  // 行为信号驱动的顺序：没练过的排前面，练过的按场景库原顺序。
  pool.sort((a, b) {
    final compared = (snap.practiceCounts[a.id] ?? 0)
        .compareTo(snap.practiceCounts[b.id] ?? 0);
    return compared != 0 ? compared : a.sortOrder.compareTo(b.sortOrder);
  });
  return pool;
}

/// 一个阶段 5–7 条：场景若干 + 1 条到期复练 +（阶段 3 起）1 条教材 / 错句。
List<PathItem> buildStageItems({
  required int stage,
  required PathSnapshot snap,
  required List<Scenario> pool,
}) {
  final items = <PathItem>[];
  final sceneCount = stage >= 3 ? 4 : 5;
  for (final scenario in pool.take(sceneCount)) {
    final practiced = snap.practiceCounts[scenario.id] ?? 0;
    final hints = snap.hintByScenario[scenario.id] ?? 0;
    final reason = hints >= 2
        ? '上次用了 $hints 次提示，趁热再走一遍。'
        : practiced > 0
            ? '再练一次，把 3 件小事都办成。'
            : '这个场景还没练过，先走一轮 10 分钟对话。';
    items.add(PathItem(
      id: 's$stage-scene-${scenario.id}',
      kind: 'scene',
      scenarioId: scenario.id,
      title: scenario.titleZh,
      reason: reason,
    ));
  }
  // 场景库极小时仍保证 5 条可用安排，不出现空计划。
  var quickIndex = 0;
  while (items.length < 4) {
    items.add(PathItem(
      id: 's$stage-quick-$quickIndex',
      kind: 'quick',
      title: '3 分钟轻量开口',
      reason: '低能量日的最小可完成动作，约 3 分钟。',
    ));
    quickIndex++;
  }
  items.add(PathItem(
    id: 's$stage-review',
    kind: 'review',
    title: '把上次改过的说法再说一遍',
    reason: '约 90 秒，把一条改法开口说对。',
  ));
  if (stage >= 3) {
    if (snap.materialCount > 0) {
      items.add(PathItem(
        id: 's$stage-material',
        kind: 'material',
        title: '听写一段真实语速素材',
        reason: '关掉字幕听一句、写一句，练真实语速。',
      ));
    } else {
      items.add(PathItem(
        id: 's$stage-wrong',
        kind: 'wrong',
        title: '只练错句本里的句子',
        reason: '把上次没听清的句子再过一遍。',
      ));
    }
  }
  // id 带阶段号，切换阶段后跳过状态自然失效。
  return items.take(7).toList();
}

String? _hintHeavyScenarioId(PathSnapshot snap) {
  for (final session in snap.sessions) {
    if (session.status != 'completed' || session.hintCount < 2) continue;
    final id = session.scenarioId;
    if (id != null && id.isNotEmpty) return id;
  }
  return null;
}

/// 到期复练 > 上次提示偏多的场景 > 未练过场景；顺序调整都带可核对理由。
List<PathItem> reorderItems(List<PathItem> items, PathSnapshot snap) {
  final ordered = <PathItem>[...items];
  final hintedId = _hintHeavyScenarioId(snap);
  if (hintedId != null) {
    final index = ordered.indexWhere(
      (e) => e.kind == 'scene' && e.scenarioId == hintedId && e.status == 'pending',
    );
    if (index > 0) {
      final item = ordered.removeAt(index);
      ordered.insert(
        0,
        item.copyWith(reason: '上次用了 ${snap.hintByScenario[hintedId] ?? 2} 次提示，先把这个场景再走一遍。'),
      );
    }
  }
  if (snap.dueCount > 0) {
    final index = ordered.indexWhere((e) => e.kind == 'review' && e.status != 'done');
    if (index > 0) {
      final item = ordered.removeAt(index);
      ordered.insert(
        0,
        item.copyWith(reason: '有 ${snap.dueCount} 条到期复练，先把最久没碰的那条说一遍。'),
      );
    }
  }
  return ordered;
}

int _goalsDone(SessionRecord session) {
  final result = ReviewResult.tryDecode(session.reviewJson);
  if (result == null) return 0;
  return result.goalResults.where((e) => e == 'done').length;
}

double? _trendValue(PathSnapshot snap, String key) {
  for (final series in snap.trends) {
    if (series.key != key) continue;
    for (final point in series.points.reversed) {
      if (point.value != null) return point.value;
    }
  }
  return null;
}

/// 完成标准只回答「可以建议往前走了吗」，不折算成分数或等级。
StageEvaluation evaluateStage(int stage, LearningPathState state, PathSnapshot snap) {
  final completed = snap.sessions
      .where((s) => s.status == 'completed' && s.modelName != quickSessionTag)
      .toList()
    ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  final recent = completed.take(3).toList();
  final evidence = <String>[];
  final pending = <String>[];
  late final bool complete;

  if (stage == 1) {
    final good = recent
        .where((s) =>
            s.turnCount >= 8 && s.hintCount <= 3 && _goalsDone(s) >= 2)
        .length;
    evidence.add('最近 ${recent.length} 次练习：$good 次达到 ≥8 回合、提示 ≤3 次、3 件小事 ≥2 件达成');
    evidence.add('复练已巩固 ${snap.consolidatedCount} 条 · 表达本已存 ${snap.phrasesCount} 条');
    final c1 = recent.length >= 3 && good >= 3;
    final c2 = snap.consolidatedCount >= 3;
    final c3 = snap.phrasesCount >= 6;
    complete = c1 && c2 && c3;
    if (!c1) pending.add('还差 ${(3 - good).clamp(0, 3)} 次达标会话');
    if (!c2) pending.add('复练巩固还差 ${(3 - snap.consolidatedCount).clamp(0, 3)} 条');
    if (!c3) pending.add('表达本还差 ${(6 - snap.phrasesCount).clamp(0, 6)} 条');
  } else if (stage == 2) {
    final good = recent
        .where((s) =>
            s.translateCount / (s.turnCount == 0 ? 1 : s.turnCount) <= 0.3 &&
            s.assistTurns <= 1 &&
            _goalsDone(s) >= 2)
        .length;
    evidence.add('最近 ${recent.length} 次练习：$good 次做到翻译 ≤30%、参考回答 ≤1 次、3 件小事 ≥2 件达成');
    evidence.add('本周已练 ${snap.weekSessions} / ${state.sessionsPerWeek} 次有效练习');
    final reuse = _trendValue(snap, 'correctionReuse');
    evidence.add(reuse == null
        ? '改法复现率：样本不足，先攒够几次练习'
        : '改法复现率：近 4 周有记录，改法能被再次用对');
    final c1 = recent.length >= 3 && good >= 3;
    final c2 = snap.weekSessions >= state.sessionsPerWeek;
    final c3 = reuse != null;
    complete = c1 && c2 && c3;
    if (!c1) pending.add('还差 ${(3 - good).clamp(0, 3)} 次少依赖的达标会话');
    if (!c2) pending.add('本周还差 ${(state.sessionsPerWeek - snap.weekSessions).clamp(0, 9)} 次');
    if (!c3) pending.add('改法复现率样本不足，再练几次就能看到');
  } else if (stage == 3) {
    final focus = goalCategories(state.goal, snap.scenarios);
    final byId = <String, Scenario>{for (final s in snap.scenarios) s.id: s};
    final covered = <String>{};
    for (final session in snap.sessions) {
      final scenario = byId[session.scenarioId];
      if (scenario != null) covered.add(scenario.category);
    }
    final coveredCount = focus.where(covered.contains).length;
    evidence.add('目标相关分类已练 $coveredCount / ${focus.length} 类');
    final good = recent.where((s) => _goalsDone(s) >= 2).length;
    evidence.add('最近 ${recent.length} 次练习：$good 次达成 ≥2 件小事');
    evidence.add('教材 ${snap.materialCount} 份 · 已练 ${snap.materialPracticedCount} 份');
    final c1 = focus.isNotEmpty && coveredCount >= focus.length;
    final c2 = recent.length >= 3 && good >= 3;
    final c3 = snap.materialPracticedCount > 0;
    complete = c1 && c2 && c3;
    if (!c1) pending.add('还有 ${(focus.length - coveredCount).clamp(0, 20)} 类没练过');
    if (!c2) pending.add('还差 ${(3 - good).clamp(0, 3)} 次达成 ≥2 件小事的会话');
    if (!c3) pending.add('教材 / 错句本还没有二次通过的练习');
  } else {
    final good = recent.where((s) => _goalsDone(s) >= 3 && s.hintCount <= 1).length;
    evidence.add('高难场景连续达标 $good / 3 次');
    evidence.add('复练已巩固 ${snap.consolidatedCount} 条（薄弱项有再练对的证据）');
    evidence.add('自评「敢开口」${state.confidence}/5');
    final c1 = recent.length >= 3 && good >= 3;
    final c2 = snap.consolidatedCount > 0;
    final c3 = state.confidence >= 4;
    complete = c1 && c2 && c3;
    if (!c1) pending.add('还差 ${(3 - good).clamp(0, 3)} 次 3 件小事全达成的会话');
    if (!c2) pending.add('还没有「已巩固」的薄弱项');
    if (!c3) pending.add('自评「敢开口」提到 4/5 后再往前走');
  }
  return StageEvaluation(complete: complete, evidence: evidence, pending: pending);
}

PathPlan computePathPlan(LearningPathState state, PathSnapshot snap) {
  if (!state.configured) return PathPlan.unconfigured(state);
  final stage = kPathStages[state.stage.clamp(1, kPathStages.length) - 1];
  final pool = stageScenarios(stage.index, state.goal, snap);
  final generated = buildStageItems(stage: stage.index, snap: snap, pool: pool);
  final today = dayKey(snap.now);
  final overrides = <String, PathItem>{for (final e in state.items) e.id: e};

  final items = generated.map((base) {
    final override = overrides[base.id];
    if (override != null && override.status == 'skipped' && override.skippedOn == today) {
      return base.copyWith(
        status: 'skipped',
        skippedOn: today,
        updatedAt: override.updatedAt,
      );
    }
    if (override != null && override.status == 'done') {
      return base.copyWith(status: 'done', updatedAt: override.updatedAt);
    }
    // 完成状态由真实数据推导，不需要在会话结束时额外写库。
    if (base.kind == 'scene') {
      final at = snap.lastCompletedAtByScenario[base.scenarioId];
      if (at != null && at >= state.updatedAt) {
        return base.copyWith(status: 'done', updatedAt: at);
      }
    } else if (base.kind == 'review') {
      if (snap.consolidatedCount > 0 && snap.dueCount == 0) {
        return base.copyWith(status: 'done');
      }
      if (snap.dueCount > 0) return base.copyWith(status: 'consolidating');
    } else if (base.kind == 'material' || base.kind == 'wrong') {
      // 没练过教材时不算完成，避免「已完成」与真实进度不符。
      if (snap.materialPracticedCount > 0) {
        return base.copyWith(status: 'done');
      }
    }
    return base;
  }).toList();

  final ordered = reorderItems(items, snap);
  final selectable = ordered
      .where((e) => e.status == 'pending' || e.status == 'consolidating')
      .toList();
  final next = selectable.isEmpty
      ? null
      : selectable[state.alternativeIndex.abs() % selectable.length];

  var reason = next?.reason ?? '本阶段安排都练过了，可以看看阶段回顾，或随便来一段。';
  if (next?.kind == 'review' && snap.dueCount > 0) {
    reason = '有 ${snap.dueCount} 条到期复练，先把最久没碰的那条说一遍，约 90 秒。';
  }
  if (snap.weekSessions < state.sessionsPerWeek) {
    reason = '$reason 本周已练 ${snap.weekSessions}/${state.sessionsPerWeek} 次。';
  }

  var lastAt = 0;
  for (final session in snap.sessions) {
    if (session.startedAt > lastAt) lastAt = session.startedAt;
  }
  final daysSinceLast = lastAt == 0
      ? 0
      : snap.now.difference(DateTime.fromMillisecondsSinceEpoch(lastAt)).inDays;

  return PathPlan(
    configured: true,
    state: state,
    stage: stage,
    items: ordered,
    scopeScenarioIds: generated
        .where((e) => e.kind == 'scene' && e.scenarioId != null)
        .map((e) => e.scenarioId!)
        .toSet(),
    evaluation: evaluateStage(stage.index, state, snap),
    next: next,
    nextReason: reason,
    daysSinceLast: daysSinceLast < 0 ? 0 : daysSinceLast,
    dueCount: snap.dueCount,
    weekSessions: snap.weekSessions,
    todayMinutes: snap.todayMinutes,
  );
}

/// 「今天先跳过」：只记覆盖项，跳过不锁后续、不补作业；次日自动恢复。
LearningPathState skipPathItem(
  LearningPathState state,
  PathItem item,
  DateTime now,
) {
  final overrides = <PathItem>[
    ...state.items.where((e) => e.id != item.id),
    item.copyWith(
      status: 'skipped',
      skippedOn: dayKey(now),
      updatedAt: now.millisecondsSinceEpoch,
    ),
  ];
  // 保留轮换位置：跳过当前这条后直接指向下一条，而不是退回第一条。
  return state.copyWith(items: overrides);
}

/// 4 个阶段都可点、可跳、可退；切换只重排，不回滚历史。
LearningPathState changePathStage(
  LearningPathState state,
  int stage,
  DateTime now,
) =>
    state.copyWith(
      stage: stage.clamp(1, kPathStages.length),
      items: const <PathItem>[],
      alternativeIndex: 0,
      updatedAt: now.millisecondsSinceEpoch,
    );

LearningPathState nextPathAlternative(LearningPathState state) =>
    state.copyWith(alternativeIndex: state.alternativeIndex + 1);
