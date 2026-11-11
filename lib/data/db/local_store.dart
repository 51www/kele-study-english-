import '../../domain/models/models.dart';

/// 本地持久化门面。
///
/// - Android / 桌面：Drift + SQLite（9 张表，schemaVersion = 1）。
/// - Web：SharedPreferences（localStorage）上的 JSON 集合，字段与表结构一致，
///   仅作为本轮浏览器验证的等价实现（Android 待真机确认）。
abstract class LocalStore {
  Future<void> init();

  Future<List<Scenario>> scenarios();
  Future<void> upsertScenario(Scenario scenario);
  Future<void> deleteScenario(String id);

  Future<List<SessionRecord>> sessions();
  Future<SessionRecord?> session(String id);
  Future<void> upsertSession(SessionRecord session);
  Future<void> deleteSession(String id);

  Future<List<MessageRecord>> messages(String sessionId);
  Future<void> upsertMessage(MessageRecord message);
  Future<void> deleteMessages(String sessionId);

  Future<List<Correction>> corrections(String sessionId);
  Future<void> upsertCorrection(Correction correction);
  Future<void> deleteCorrection(String id);
  Future<void> deleteCorrections(String sessionId);

  Future<List<Phrase>> phrases();
  Future<void> upsertPhrase(Phrase phrase);
  Future<void> deletePhrase(String id);

  Future<LlmProfile?> activeProfile();
  Future<void> saveProfile(LlmProfile profile);

  Future<String?> setting(String key);
  Future<Map<String, String>> settings();
  Future<void> setSetting(String key, String value);

  Future<List<TtsCacheEntry>> ttsCache();
  Future<void> upsertTtsCache(TtsCacheEntry entry);
  Future<void> deleteTtsCache(String hash);

  Future<String?> meta(String key);
  Future<void> setMeta(String key, String value);

  Future<void> clearAll();
}
