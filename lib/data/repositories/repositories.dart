import '../../domain/models/models.dart';
import '../db/local_store.dart';

class ScenarioRepository {
  ScenarioRepository(this._store);

  final LocalStore _store;

  Future<List<Scenario>> all() => _store.scenarios();

  Future<Scenario?> byId(String id) async {
    final list = await _store.scenarios();
    for (final item in list) {
      if (item.id == id) return item;
    }
    return null;
  }
}

class SettingsRepository {
  SettingsRepository(this._store);

  final LocalStore _store;
  final Map<String, String> _cache = {};
  bool _loaded = false;

  Future<void> load() async {
    _cache
      ..clear()
      ..addAll(await _store.settings());
    _loaded = true;
  }

  bool get loaded => _loaded;

  Map<String, String> get all => Map.unmodifiable(_cache);

  String getString(String key, [String fallback = '']) => _cache[key] ?? fallback;

  bool getBool(String key, {bool fallback = false}) {
    final value = _cache[key];
    if (value == null) return fallback;
    return value == 'true';
  }

  int getInt(String key, {int fallback = 0}) =>
      int.tryParse(_cache[key] ?? '') ?? fallback;

  double getDouble(String key, {double fallback = 0}) =>
      double.tryParse(_cache[key] ?? '') ?? fallback;

  Future<void> set(String key, String value) async {
    _cache[key] = value;
    await _store.setSetting(key, value);
  }
}

class LlmProfileRepository {
  LlmProfileRepository(this._store);

  final LocalStore _store;

  static const defaultBaseUrl = 'https://aiping.cn/api/v1';
  static const defaultModel = 'GLM-5.3-Flash';
  static const defaultId = 'default';
  static const defaultKeyRef = 'llm_active_key';

  Future<LlmProfile> loadOrCreate() async {
    final existing = await _store.activeProfile();
    if (existing != null) return existing;
    final profile = const LlmProfile(
      id: defaultId,
      baseUrl: defaultBaseUrl,
      model: defaultModel,
      keyRef: defaultKeyRef,
    );
    await _store.saveProfile(profile);
    return profile;
  }

  Future<void> save(LlmProfile profile) => _store.saveProfile(profile);

  Future<void> markCheck(LlmProfile profile, String status, String message) {
    return _store.saveProfile(profile.copyWith(
      lastCheckStatus: status,
      lastCheckMessage: message,
      lastCheckedAt: DateTime.now().millisecondsSinceEpoch,
    ));
  }
}

class SessionRepository {
  SessionRepository(this._store);

  final LocalStore _store;

  Future<List<SessionRecord>> list() => _store.sessions();

  Future<SessionRecord?> byId(String id) => _store.session(id);

  Future<List<MessageRecord>> messages(String sessionId) => _store.messages(sessionId);

  Future<void> saveSession(SessionRecord session) => _store.upsertSession(session);

  Future<void> saveMessage(MessageRecord message) => _store.upsertMessage(message);

  Future<SessionRecord> createSession({
    required Scenario scenario,
    required String modelName,
    required String ttsEngine,
  }) async {
    final now = DateTime.now();
    final session = SessionRecord(
      id: 's_${now.microsecondsSinceEpoch}',
      scenarioId: scenario.id,
      startedAt: now.millisecondsSinceEpoch,
      status: 'draft',
      modelName: modelName,
      ttsEngine: ttsEngine,
    );
    await _store.upsertSession(session);
    final opening = MessageRecord(
      id: 'm_${now.microsecondsSinceEpoch}_0',
      sessionId: session.id,
      seq: 0,
      role: 'assistant',
      textEn: scenario.openingLine,
      createdAt: now.millisecondsSinceEpoch,
    );
    await _store.upsertMessage(opening);
    return session;
  }

  Future<void> finishSession(SessionRecord session) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final duration = ((now - session.startedAt) / 1000).round();
    await _store.upsertSession(
      session.copyWith(endedAt: now, durationSec: duration, status: 'completed'),
    );
  }

  Future<void> deleteSession(String id) async {
    await _store.deleteMessages(id);
    await _store.deleteCorrections(id);
    await _store.deleteSession(id);
  }

  Future<void> clearAll() => _store.clearAll();

  Future<List<Correction>> corrections(String sessionId) => _store.corrections(sessionId);

  Future<void> saveCorrections(List<Correction> items) async {
    for (final item in items) {
      await _store.upsertCorrection(item);
    }
  }

  Future<void> deleteCorrection(String id) => _store.deleteCorrection(id);

  Future<List<Phrase>> phrases() => _store.phrases();

  Future<void> savePhrase(Phrase phrase) => _store.upsertPhrase(phrase);

  Future<void> deletePhrase(String id) => _store.deletePhrase(id);

  Future<double> cacheBytes() async {
    final rows = await _store.ttsCache();
    return rows.fold<double>(0, (sum, e) => sum + e.bytes);
  }

  Future<void> clearCache(List<String> paths) async {
    for (final path in paths) {
      await _store.deleteTtsCache(path);
    }
  }
}
