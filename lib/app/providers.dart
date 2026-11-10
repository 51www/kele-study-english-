import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/local_store.dart';
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

final ttsRouterProvider = Provider<TtsRouter>((ref) {
  final router = TtsRouter(
    edge: EdgeTtsEngine(),
    system: SystemTtsEngine(),
    player: ref.watch(audioPlayerProvider),
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
    this.lastSession,
  });

  final List<Scenario> scenarios;
  final int todayMinutes;
  final int todayTurns;
  final int totalSessions;
  final int streakDays;
  final SessionRecord? lastSession;
}

final homeDataProvider = FutureProvider<HomeData>((ref) async {
  final scenarioRepo = ref.watch(scenarioRepositoryProvider);
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final scenarios = await scenarioRepo.all();
  final sessions = await sessionRepo.list();
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
  var todaySeconds = 0;
  var todayTurns = 0;
  final dayKeys = <String>{};
  for (final session in sessions) {
    dayKeys.add(_dayKey(session.startedDate));
    if (session.startedAt >= todayStart) {
      todaySeconds += session.durationSec;
      todayTurns += session.turnCount;
    }
  }
  var streak = 0;
  var cursor = DateTime(now.year, now.month, now.day);
  while (dayKeys.contains(_dayKey(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return HomeData(
    scenarios: scenarios,
    todayMinutes: (todaySeconds / 60).round(),
    todayTurns: todayTurns,
    totalSessions: sessions.length,
    streakDays: streak,
    lastSession: sessions.isEmpty ? null : sessions.first,
  );
});

String _dayKey(DateTime time) => '${time.year}-${time.month}-${time.day}';

final recentSessionsProvider = FutureProvider<List<SessionRecord>>((ref) {
  return ref.watch(sessionRepositoryProvider).list();
});

final scenarioProvider = FutureProvider.family<Scenario?, String>((ref, id) {
  return ref.watch(scenarioRepositoryProvider).byId(id);
});
