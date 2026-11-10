import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/local_store.dart';
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
    required this.targetMinutes,
    this.lastSession,
    this.lastStuck,
  });

  final List<Scenario> scenarios;
  final int todayMinutes;
  final int todayTurns;
  final int totalSessions;
  final int streakDays;
  final int weekSessions;
  final int targetMinutes;
  final SessionRecord? lastSession;

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
  // 连续天数只算「有效练习」：≥5 分钟，按自然日去重。
  final activeDays = <String>{};
  for (final session in sessions) {
    if (session.durationSec >= 300) activeDays.add(_dayKey(session.startedDate));
    if (session.startedAt >= todayStart) {
      todaySeconds += session.durationSec;
      todayTurns += session.turnCount;
    }
    if (session.startedAt >= weekStart) weekSessions++;
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
    targetMinutes: targetMinutes,
    lastSession: sessions.isEmpty ? null : sessions.first,
    lastStuck: lastStuck,
  );
});

String _dayKey(DateTime time) => '${time.year}-${time.month}-${time.day}';

final recentSessionsProvider = FutureProvider<List<SessionRecord>>((ref) {
  return ref.watch(sessionRepositoryProvider).list();
});

final phrasesProvider = FutureProvider<List<Phrase>>((ref) {
  return ref.watch(sessionRepositoryProvider).phrases();
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
