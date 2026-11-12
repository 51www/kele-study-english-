import '../../domain/models/dictation_models.dart';
import '../../domain/models/models.dart';
import '../../features/retention/review_item.dart';

/// 本地持久化门面。
///
/// - Android / 桌面：Drift + SQLite（13 张表，schemaVersion = 3；v1 → v2 建二期 3 张表，v2 → v3 建三期 1 张表）。
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

  // 二期：教材 / 句子 / 听写记录。删除教材时由实现层级联删除子表。
  Future<List<MaterialItem>> materials();
  Future<MaterialItem?> material(String id);
  Future<MaterialItem?> materialByHash(String hash);
  Future<void> upsertMaterial(MaterialItem item);
  Future<void> deleteMaterial(String id);

  Future<List<MaterialSegment>> segments(String materialId);
  Future<void> replaceSegments(String materialId, List<MaterialSegment> list);
  Future<void> deleteSegment(String id);

  Future<List<DictationAttempt>> attempts(String materialId);
  Future<List<DictationAttempt>> allAttempts();
  Future<void> upsertAttempt(DictationAttempt attempt);

  // 三期：待复练队列（复盘改法 / 表达 / 错句共用）。
  Future<List<ReviewItem>> reviewItems();
  Future<void> upsertReviewItem(ReviewItem item);
  Future<void> deleteReviewItem(String id);
  Future<void> deleteReviewItemsForSource(String sourceType, String sourceId);

  Future<void> clearAll();
}
