import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/local_store.dart';
import '../features/chat/learner_profile.dart';
import '../features/me/metrics.dart';
import '../features/retention/review_item.dart';
import '../features/tips/tips_repository.dart';
import '../data/repositories/repositories.dart';
import '../data/secure/key_store.dart';
import '../domain/models/models.dart';
import '../services/asr/system_asr_engine.dart';
import '../services/audio/audio_player.dart';
import '../services/audio/audio_recorder.dart';
import '../services/audio/audio_session_manager.dart';
import '../services/llm/llm_client.dart';
import '../services/tts/edge_tts_engine.dart';
import '../services/tts/system_tts_engine.dart';
import '../services/tts/tts_disk_cache.dart';
import '../services/tts/tts_router.dart';

final localStoreProvider = Provider<LocalStore>((ref) {
  throw UnimplementedError('LocalStore 必须在 main() 中注入');
});

final keyStoreProvider = Provider<KeyStore>((ref) => KeyStore());

final scenarioRepositoryProvider = Provider<ScenarioRepository>(
  (ref) => ScenarioRepository(ref.watch(localStoreProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(localStoreProvider)),
);

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepository(ref.watch(localStoreProvider)),
);

final llmProfileRepositoryProvider = Provider<LlmProfileRepository>(
  (ref) => LlmProfileRepository(ref.watch(localStoreProvider)),
);

final llmClientProvider = Provider<LlmClient>((ref) => LlmClient());

final asrEngineProvider = Provider<SystemAsrEngine>((ref) => SystemAsrEngine());

final audioRecorderProvider = Provider<AudioRecorderService>((ref) => AudioRecorderService());

final audioPlayerProvider = Provider<AudioPlayerService>((ref) => AudioPlayerService());

final audioSessionProvider = Provider<AudioSessionManager>((ref) => AudioSessionManager());

final ttsDiskCacheProvider = Provider<TtsDiskCache>((ref) {
  return TtsDiskCache(ref.watch(localStoreProvider));
});

final ttsRouterProvider = Provider<TtsRouter>((ref) {
  final disk = ref.watch(ttsDiskCacheProvider);
  unawaited(disk.load());
  final router = TtsRouter(
    edge: EdgeTtsEngine(),
    system: SystemTtsEngine(),
    player: ref.watch(audioPlayerProvider),
    disk: disk,
  );
  ref.onDispose(() {
    router.stop();
    router.edge.dispose();
    router.system.dispose();
  });
  return router;
});

/// 设置项以不可变 Map 暴露，修改后立即重建依赖方。
class SettingsController extends Notifier<Map<String, String>> {
  SettingsRepository get _repository => ref.read(settingsRepositoryProvider);

  @override
  Map<String, String> build() => Map<String, String>.unmodifiable(_repository.all);

  Future<void> set(String key, String value) async {
    await _repository.set(key, value);
    state = Map<String, String>.unmodifiable(_repository.all);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, Map<String, String>>(SettingsController.new);

class ProfileInfo {
  const ProfileInfo({required this.profile, required this.maskedKey, required this.hasKey});

  final LlmProfile profile;
  final String maskedKey;
  final bool hasKey;
}

final profileInfoProvider = FutureProvider<ProfileInfo>((ref) async {
  final repo = ref.watch(llmProfileRepositoryProvider);
  final keyStore = ref.watch(keyStoreProvider);
  final profile = await repo.loadOrCreate();
  final key = await keyStore.read(profile.keyRef);
  return ProfileInfo(
    profile: profile,
    maskedKey: KeyStore.mask(key),
    hasKey: key != null && key.isNotEmpty,
  );
});

class HomeData {
  const HomeData({
    required this.scenarios,
    required this.todayMinutes,
    required this.todayTurns,
    required this.totalSessions,
    required this.streakDays,
    required this.weekSessions,
    required this.quickWeekSessions,
    required this.targetMinutes,
    this.lastSession,
    this.resumableSession,
    this.lastStuck,
  });

  final List<Scenario> scenarios;
  final int todayMinutes;
  final int todayTurns;
  final int totalSessions;
  final int streakDays;
  final int weekSessions;
  final int quickWeekSessions;
  final int targetMinutes;
  final SessionRecord? lastSession;

  /// 最近一次半路退出、仍可接着聊的会话（首页「继续上次」主入口）。
  final SessionRecord? resumableSession;

  /// 上次复盘里第一条未被删除的纠错，用于首页「上次卡在哪」。
  final Correction? lastStuck;
}

final homeDataProvider = FutureProvider<HomeData>((ref) async {
  final scenarioRepo = ref.watch(scenarioRepositoryProvider);
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final scenarios = await scenarioRepo.all();
  final sessions = await sessionRepo.list();
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  final targetMinutes = settingsRepo.getInt(SettingsKeys.targetMinutes, fallback: 10);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final todayStart = today.millisecondsSinceEpoch;
  final weekStart = DateTime(now.year, now.month, now.day - (now.weekday - 1))
      .millisecondsSinceEpoch;
  var todaySeconds = 0;
  var todayTurns = 0;
  var weekSessions = 0;
  var quickWeekSessions = 0;
  // 连续天数只算「有效练习」：≥5 分钟，按自然日去重。
  final activeDays = <String>{};
  for (final session in sessions) {
    if (session.durationSec >= 300) activeDays.add(_dayKey(session.startedDate));
    if (session.startedAt >= todayStart) {
      todaySeconds += session.durationSec;
      todayTurns += session.turnCount;
    }
    if (session.startedAt >= weekStart) {
      // 3 分钟轻量练习计入今日分钟，但不计入每周有效次数（需求 §3.2 口径）。
      if (session.modelName == quickSessionTag) {
        quickWeekSessions++;
      } else {
        weekSessions++;
      }
    }
  }
  // 今天还没练时从昨天起算，避免上午打开 App 就把连续天数清零。
  var cursor = today;
  if (!activeDays.contains(_dayKey(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
  }
  var streak = 0;
  while (activeDays.contains(_dayKey(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  Correction? lastStuck;
  for (final session in sessions.where((e) => e.status == 'completed').take(3)) {
    final rows = await sessionRepo.corrections(session.id);
    final first = rows.where((e) => !e.isDeleted && e.improved.isNotEmpty).firstOrNull;
    if (first != null) {
      lastStuck = first;
      break;
    }
  }
  return HomeData(
    scenarios: scenarios,
    todayMinutes: (todaySeconds / 60).round(),
    todayTurns: todayTurns,
    totalSessions: sessions.length,
    streakDays: streak,
    weekSessions: weekSessions,
    quickWeekSessions: quickWeekSessions,
    targetMinutes: targetMinutes,
    lastSession: sessions.isEmpty ? null : sessions.first,
    resumableSession: sessions.where(isResumableSession).firstOrNull,
    lastStuck: lastStuck,
  );
});

String _dayKey(DateTime time) => '${time.year}-${time.month}-${time.day}';

// ── 三期：待复练队列与「今天练这个」 ──────────────────────────────────────

final reviewItemsProvider = FutureProvider<List<ReviewItem>>((ref) async {
  final store = ref.watch(localStoreProvider);
  final items = await store.reviewItems();
  // 删除表达 / 删除教材后，对应复习项不再出现（等价于级联清理）。
  final phraseIds = (await store.phrases()).map((e) => e.id).toSet();
  final segmentIds = <String>{};
  for (final material in await store.materials()) {
    for (final segment in await store.segments(material.id)) {
      segmentIds.add(segment.id);
    }
  }
  return items.where((item) {
    switch (item.sourceType) {
      case 'phrase':
        return phraseIds.contains(item.sourceId);
      case 'segment':
        return segmentIds.contains(item.sourceId);
      default:
        return true;
    }
  }).toList();
});

/// 从表达本与错句本补充待复练项；同一来源只入队一次。纯本地、不调模型。
Future<int> syncRetentionSources(LocalStore store) async {
  final items = await store.reviewItems();
  final now = DateTime.now().millisecondsSinceEpoch;
  var added = 0;
  for (final phrase in await store.phrases()) {
    if (phrase.textEn.trim().isEmpty) continue;
    if (ReviewScheduler.hasSource(items, 'phrase', phrase.id)) continue;
    await store.upsertReviewItem(
      ReviewScheduler.create(
        id: 'rv_phrase_${phrase.id}',
        sourceType: 'phrase',
        sourceId: phrase.id,
        textEn: phrase.textEn.trim(),
        textZh: phrase.textZh,
        nowMs: now,
      ),
    );
    added++;
  }
  final failed = (await store.allAttempts())
      .where((attempt) => !attempt.passed)
      .map((attempt) => attempt.segmentId)
      .toSet();
  if (failed.isNotEmpty) {
    for (final material in await store.materials()) {
      for (final segment in await store.segments(material.id)) {
        if (!failed.contains(segment.id)) continue;
        if (ReviewScheduler.hasSource(items, 'segment', segment.id)) continue;
        await store.upsertReviewItem(
          ReviewScheduler.create(
            id: 'rv_segment_${segment.id}',
            sourceType: 'segment',
            sourceId: segment.id,
            textEn: segment.textEn,
            nowMs: now,
          ),
        );
        added++;
      }
    }
  }
  return added;
}

final dueReviewItemsProvider = FutureProvider<List<ReviewItem>>((ref) async {
  final items = await ref.watch(reviewItemsProvider.future);
  final raw = await ref.watch(localStoreProvider).setting(SettingsKeys.reviewDailyLimit);
  final limit = int.tryParse(raw ?? '5') ?? 5;
  return ReviewScheduler.due(
    items,
    DateTime.now().millisecondsSinceEpoch,
    limit: limit.clamp(1, 20),
  );
});

class TodayPlan {
  const TodayPlan({
    required this.title,
    required this.reason,
    required this.route,
  });

  final String title;
  final String reason;
  final String route;
}

/// 纯规则、不调模型：待复练 > 上次提示偏多的场景再练 > 未练过场景。
final todayPlanProvider = FutureProvider<TodayPlan>((ref) async {
  final due = await ref.watch(dueReviewItemsProvider.future);
  if (due.isNotEmpty) {
    return TodayPlan(
      title: '把上次改过的说法再说一遍',
      reason: '有 ${due.length} 条到期的复练，先练最久没碰的那条，约 90 秒。',
      route: '/retention',
    );
  }
  final sessions = await ref.watch(sessionRepositoryProvider).list();
  final scenarios = await ref.watch(scenarioRepositoryProvider).all();
  if (scenarios.isEmpty) {
    return const TodayPlan(
      title: '先挑个场景开口',
      reason: '场景库还没加载好，稍后刷新一下。',
      route: '/scenarios',
    );
  }
  final hinted = sessions
      .where((s) => s.status == 'completed' && s.hintCount >= 2)
      .firstOrNull;
  if (hinted?.scenarioId != null) {
    for (final scenario in scenarios) {
      if (scenario.id == hinted!.scenarioId) {
        return TodayPlan(
          title: '再练一次「${scenario.titleZh}」',
          reason: '上次用了 ${hinted.hintCount} 次提示，趁热再走一遍。',
          route: '/scenario/${scenario.id}',
        );
      }
    }
  }
  final practiced = sessions.map((s) => s.scenarioId).toSet();
  final next = scenarios.where((s) => !practiced.contains(s.id)).firstOrNull ?? scenarios.first;
  return TodayPlan(
    title: '试试「${next.titleZh}」',
    reason: practiced.isEmpty
        ? '从第一个场景开始，一轮 10 分钟就能走完。'
        : '这个场景还没练过，换个话题试试。',
    route: '/scenario/${next.id}',
  );
});

/// 半路退出留下的、还能接着聊的会话（有实际开口、未显式结束并复盘）。
bool isResumableSession(SessionRecord session) =>
    session.status != 'completed' && session.turnCount > 0;

// ── 三期 M11：轻量模式标记与可解释趋势 ───────────────────────────────────

/// 3 分钟轻量会话标记：复用 `session.model_name`，零改表。
/// 这类会话计入今日分钟，但不计入每周有效次数。
const String quickSessionTag = 'quick-3min';

/// 近 4 周趋势：全部来自本地已有表，不联网、不调模型。
final trendsProvider = FutureProvider<List<TrendSeries>>((ref) async {
  final repo = ref.watch(sessionRepositoryProvider);
  final all = await repo.list();
  // 3 分钟轻量会话不计入主指标，避免把「没用提示」的轻量轮次算成提示使用率下降。
  final sessions = all.where((s) => s.modelName != quickSessionTag).toList();
  final correctionsBySession = <String, List<Correction>>{};
  final messagesBySession = <String, List<MessageRecord>>{};
  for (final session in sessions) {
    correctionsBySession[session.id] = await repo.corrections(session.id);
    messagesBySession[session.id] = await repo.messages(session.id);
  }
  return computeTrends(TrendInput(
    sessions: sessions,
    correctionsBySession: correctionsBySession,
    messagesBySession: messagesBySession,
    now: DateTime.now(),
  ));
});

// ── 三期 M12：主对话只读学习者档案 ─────────────────────────────────────

/// 只聚合本地既有表的文本字段，不读复盘 JSON 全文、不读表达本音频、不调模型；
/// 关闭设置开关时返回 null，`chatSystem` 随即回到 M8 原文。
final learnerProfileProvider =
    FutureProvider.family<LearnerProfile?, String>((ref, sessionId) async {
  // 用响应式设置状态：在设置页关掉开关后，已缓存的档案会立即失效。
  final settings = ref.watch(settingsControllerProvider);
  final enabled = settings[SettingsKeys.learnerProfileEnabled] != 'false';
  if (!enabled) return null;
  final sessionsRepo = ref.watch(sessionRepositoryProvider);
  final store = ref.watch(localStoreProvider);
  final sessions = await sessionsRepo.list();
  final tail = <SessionRecord>[...sessions]
    ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  final correctionsBySession = <String, List<Correction>>{};
  for (final session in tail.take(learnerProfileMaxSessions + 1)) {
    correctionsBySession[session.id] = await sessionsRepo.corrections(session.id);
  }
  return buildLearnerProfile(LearnerProfileInput(
    enabled: enabled,
    sessions: sessions,
    correctionsBySession: correctionsBySession,
    reviewItems: await store.reviewItems(),
    phrases: await store.phrases(),
    scenarios: await ref.watch(scenarioRepositoryProvider).all(),
    currentSessionId: sessionId,
  ));
});

final recentSessionsProvider = FutureProvider<List<SessionRecord>>((ref) {
  return ref.watch(sessionRepositoryProvider).list();
});

/// 某个场景下最近的未完成会话，供场景详情页提供「继续上次」入口。
final resumableSessionForScenarioProvider =
    FutureProvider.family<SessionRecord?, String>((ref, scenarioId) async {
  final sessions = await ref.watch(recentSessionsProvider.future);
  return sessions
      .where((e) => e.scenarioId == scenarioId && isResumableSession(e))
      .firstOrNull;
});

final phrasesProvider = FutureProvider<List<Phrase>>((ref) async {
  final repo = ref.watch(sessionRepositoryProvider);
  await repo.ensureStarterPhrases();
  return repo.phrases();
});

/// 朗读缓存占用（读 tts_cache 表求和，单位字节）。
final cacheBytesProvider = FutureProvider<double>((ref) async {
  final rows = await ref.watch(localStoreProvider).ttsCache();
  return rows.fold<double>(0, (sum, e) => sum + e.bytes);
});

final correctionsForSessionProvider =
    FutureProvider.family<List<Correction>, String>((ref, sessionId) {
  return ref.watch(sessionRepositoryProvider).corrections(sessionId);
});

final scenarioProvider = FutureProvider.family<Scenario?, String>((ref, id) {
  return ref.watch(scenarioRepositoryProvider).byId(id);
});

class ScenarioLibraryData {
  const ScenarioLibraryData({required this.scenarios, required this.practiceCounts});

  final List<Scenario> scenarios;

  /// 按 session.scenario_id 聚合的「练过次数」，只统计真正开口过的会话。
  final Map<String, int> practiceCounts;
}

/// 场景库：全部内置场景 + 练过次数。会话结束或清空数据后需要 invalidate。
final scenarioLibraryProvider = FutureProvider<ScenarioLibraryData>((ref) async {
  final scenarios = await ref.watch(scenarioRepositoryProvider).all();
  final sessions = await ref.watch(sessionRepositoryProvider).list();
  final counts = <String, int>{};
  for (final session in sessions) {
    final id = session.scenarioId;
    if (id == null || id.isEmpty || session.turnCount <= 0) continue;
    counts[id] = (counts[id] ?? 0) + 1;
  }
  return ScenarioLibraryData(scenarios: scenarios, practiceCounts: counts);
});

/// 站内「方法 / 技巧」文章（本地 assets，无网络请求）。
final tipsProvider = FutureProvider<List<TipArticle>>((ref) {
  return TipsRepository().all();
});

/// 本月累计成本（从 session.cost_estimate 聚合，不另存冗余计数）。
final monthlyCostProvider = FutureProvider<double>((ref) async {
  final sessions = await ref.watch(sessionRepositoryProvider).list();
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
  return sessions
      .where((e) => e.startedAt >= monthStart)
      .fold<double>(0, (sum, e) => sum + (e.costEstimate ?? 0));
});

/// 上一回合分阶段延迟：asr / firstToken / firstAudio / total（毫秒）。
final lastLatencyProvider = FutureProvider<Map<String, int>?>((ref) async {
  final raw = await ref.watch(localStoreProvider).meta('latency.lastTurn');
  if (raw == null || raw.isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return decoded.map(
        (key, value) => MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
      );
    }
  } catch (_) {
    return null;
  }
  return null;
});
