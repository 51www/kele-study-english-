import 'package:drift/drift.dart';

import '../../domain/models/dictation_models.dart';
import '../../domain/models/models.dart';
import 'app_database.dart'
    hide
        Scenario,
        Session,
        Message,
        Correction,
        Phrase,
        LlmProfile,
        TtsCache,
        AppMeta,
        Material,
        MaterialSegment,
        DictationAttempt;
import 'defaults.dart';
import 'local_store.dart';
import 'seeds.dart';

/// Android / 桌面实现：Drift + SQLite。
class DriftStore implements LocalStore {
  DriftStore(this._db);

  final AppDatabase _db;

  @override
  Future<void> init() async {
    for (final scenario in builtinScenarios) {
      await upsertScenario(scenario);
    }
    for (final entry in defaultSettings.entries) {
      final existing = await setting(entry.key);
      if (existing == null) await setSetting(entry.key, entry.value);
    }
  }

  Future<List<Map<String, Object?>>> _query(String sql, [List<Object?> args = const []]) async {
    final rows = await _db.customSelect(
      sql,
      variables: args.map((e) => Variable<Object>(e)).toList(),
    ).get();
    return rows.map((row) => row.data.cast<String, Object?>()).toList();
  }

  Future<void> _exec(String sql, [List<Object?> args = const []]) async {
    await _db.customStatement(sql, args);
  }

  @override
  Future<List<Scenario>> scenarios() async {
    final rows = await _query('SELECT * FROM scenario ORDER BY sort_order ASC');
    return rows.map(Scenario.fromMap).toList();
  }

  @override
  Future<void> upsertScenario(Scenario scenario) async {
    final m = scenario.toMap();
    await _exec(
      'INSERT OR REPLACE INTO scenario (id, title_zh, title_en, category, level, ai_role, '
      'user_goal, opening_line, target_phrases, expected_turns, success_criteria, branch_hint, '
      'is_builtin, sort_order) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
      [
        m['id'], m['title_zh'], m['title_en'], m['category'], m['level'], m['ai_role'],
        m['user_goal'], m['opening_line'], m['target_phrases'], m['expected_turns'],
        m['success_criteria'], m['branch_hint'], m['is_builtin'], m['sort_order'],
      ],
    );
  }

  @override
  Future<void> deleteScenario(String id) async {
    await _exec('DELETE FROM scenario WHERE id = ? AND is_builtin = 0', [id]);
  }

  @override
  Future<List<SessionRecord>> sessions() async {
    final rows = await _query('SELECT * FROM session ORDER BY started_at DESC');
    return rows.map(SessionRecord.fromMap).toList();
  }

  @override
  Future<SessionRecord?> session(String id) async {
    final rows = await _query('SELECT * FROM session WHERE id = ? LIMIT 1', [id]);
    if (rows.isEmpty) return null;
    return SessionRecord.fromMap(rows.first);
  }

  @override
  Future<void> upsertSession(SessionRecord s) async {
    final m = s.toMap();
    await _exec(
      'INSERT OR REPLACE INTO session (id, scenario_id, started_at, ended_at, duration_sec, '
      'turn_count, hint_count, assist_turns, translate_count, status, model_name, tts_engine, '
      'review_json, cost_estimate) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
      [
        m['id'], m['scenario_id'], m['started_at'], m['ended_at'], m['duration_sec'],
        m['turn_count'], m['hint_count'], m['assist_turns'], m['translate_count'], m['status'],
        m['model_name'], m['tts_engine'], m['review_json'], m['cost_estimate'],
      ],
    );
  }

  @override
  Future<void> deleteSession(String id) async {
    await _exec('DELETE FROM session WHERE id = ?', [id]);
  }

  @override
  Future<List<MessageRecord>> messages(String sessionId) async {
    final rows = await _query(
      'SELECT * FROM message WHERE session_id = ? ORDER BY seq ASC',
      [sessionId],
    );
    return rows.map(MessageRecord.fromMap).toList();
  }

  @override
  Future<void> upsertMessage(MessageRecord msg) async {
    final m = msg.toMap();
    await _exec(
      'INSERT OR REPLACE INTO message (id, session_id, seq, role, text_en, text_zh, audio_path, '
      'asr_provider, latency_ms, is_hint, hint_level, status, created_at) '
      'VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)',
      [
        m['id'], m['session_id'], m['seq'], m['role'], m['text_en'], m['text_zh'],
        m['audio_path'], m['asr_provider'], m['latency_ms'], m['is_hint'], m['hint_level'],
        m['status'], m['created_at'],
      ],
    );
  }

  @override
  Future<void> deleteMessages(String sessionId) async {
    await _exec('DELETE FROM message WHERE session_id = ?', [sessionId]);
  }

  @override
  Future<List<Correction>> corrections(String sessionId) async {
    final rows = await _query(
      'SELECT * FROM correction WHERE session_id = ? AND is_deleted = 0 ORDER BY created_at ASC',
      [sessionId],
    );
    return rows.map(Correction.fromMap).toList();
  }

  @override
  Future<void> upsertCorrection(Correction c) async {
    final m = c.toMap();
    await _exec(
      'INSERT OR REPLACE INTO correction (id, session_id, message_id, original, improved, '
      'reason_zh, audio_path, is_deleted, created_at) VALUES (?,?,?,?,?,?,?,?,?)',
      [
        m['id'], m['session_id'], m['message_id'], m['original'], m['improved'], m['reason_zh'],
        m['audio_path'], m['is_deleted'], m['created_at'],
      ],
    );
  }

  @override
  Future<void> deleteCorrection(String id) async {
    await _exec('DELETE FROM correction WHERE id = ?', [id]);
  }

  @override
  Future<void> deleteCorrections(String sessionId) async {
    await _exec('DELETE FROM correction WHERE session_id = ?', [sessionId]);
  }

  @override
  Future<List<Phrase>> phrases() async {
    final rows = await _query('SELECT * FROM phrase ORDER BY created_at DESC');
    return rows.map(Phrase.fromMap).toList();
  }

  @override
  Future<void> upsertPhrase(Phrase p) async {
    final m = p.toMap();
    await _exec(
      'INSERT OR REPLACE INTO phrase (id, text_en, text_zh, source_session_id, '
      'source_scenario_id, audio_path, mastered, created_at) VALUES (?,?,?,?,?,?,?,?)',
      [
        m['id'], m['text_en'], m['text_zh'], m['source_session_id'], m['source_scenario_id'],
        m['audio_path'], m['mastered'], m['created_at'],
      ],
    );
  }

  @override
  Future<void> deletePhrase(String id) async {
    await _exec('DELETE FROM phrase WHERE id = ?', [id]);
  }

  @override
  Future<LlmProfile?> activeProfile() async {
    final rows = await _query('SELECT * FROM llm_profile WHERE is_active = 1 LIMIT 1');
    if (rows.isEmpty) return null;
    return LlmProfile.fromMap(rows.first);
  }

  @override
  Future<void> saveProfile(LlmProfile p) async {
    final m = p.toMap();
    await _exec(
      'INSERT OR REPLACE INTO llm_profile (id, name, base_url, model, key_ref, extra_json, '
      'last_check_status, last_check_message, last_checked_at, is_active) '
      'VALUES (?,?,?,?,?,?,?,?,?,?)',
      [
        m['id'], m['name'], m['base_url'], m['model'], m['key_ref'], m['extra_json'],
        m['last_check_status'], m['last_check_message'], m['last_checked_at'], m['is_active'],
      ],
    );
  }

  @override
  Future<String?> setting(String key) async {
    final rows = await _query('SELECT value FROM setting WHERE key = ? LIMIT 1', [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  @override
  Future<Map<String, String>> settings() async {
    final rows = await _query('SELECT * FROM setting');
    return {
      for (final row in rows) row['key'] as String: (row['value'] ?? '') as String,
    };
  }

  @override
  Future<void> setSetting(String key, String value) async {
    await _exec(
      'INSERT OR REPLACE INTO setting (key, value, updated_at) VALUES (?,?,?)',
      [key, value, DateTime.now().millisecondsSinceEpoch],
    );
  }

  @override
  Future<List<TtsCacheEntry>> ttsCache() async {
    final rows = await _query('SELECT * FROM tts_cache ORDER BY last_used_at DESC');
    return rows.map(TtsCacheEntry.fromMap).toList();
  }

  @override
  Future<void> upsertTtsCache(TtsCacheEntry entry) async {
    final m = entry.toMap();
    await _exec(
      'INSERT OR REPLACE INTO tts_cache (hash, engine, voice, rate, file_path, bytes, '
      'created_at, last_used_at) VALUES (?,?,?,?,?,?,?,?)',
      [
        m['hash'], m['engine'], m['voice'], m['rate'], m['file_path'], m['bytes'],
        m['created_at'], m['last_used_at'],
      ],
    );
  }

  @override
  Future<void> deleteTtsCache(String hash) async {
    await _exec('DELETE FROM tts_cache WHERE hash = ?', [hash]);
  }

  @override
  Future<String?> meta(String key) async {
    final rows = await _query('SELECT value FROM app_meta WHERE key = ? LIMIT 1', [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  @override
  Future<void> setMeta(String key, String value) async {
    await _exec(
      'INSERT OR REPLACE INTO app_meta (key, value) VALUES (?,?)',
      [key, value],
    );
  }

  // ── 二期：教材 / 句子 / 听写记录 ────────────────────────────────────────

  @override
  Future<List<MaterialItem>> materials() async {
    final rows = await _query('SELECT * FROM material ORDER BY created_at DESC');
    return rows.map(MaterialItem.fromMap).toList();
  }

  @override
  Future<MaterialItem?> material(String id) async {
    final rows = await _query('SELECT * FROM material WHERE id = ? LIMIT 1', [id]);
    if (rows.isEmpty) return null;
    return MaterialItem.fromMap(rows.first);
  }

  @override
  Future<MaterialItem?> materialByHash(String hash) async {
    final rows = await _query('SELECT * FROM material WHERE source_hash = ? LIMIT 1', [hash]);
    if (rows.isEmpty) return null;
    return MaterialItem.fromMap(rows.first);
  }

  @override
  Future<void> upsertMaterial(MaterialItem item) async {
    final m = item.toMap();
    await _exec(
      'INSERT OR REPLACE INTO material (id, title, media_path, media_name, media_kind, '
      'subtitle_name, source_hash, duration_ms, segment_count, created_at, '
      'last_practiced_at) VALUES (?,?,?,?,?,?,?,?,?,?,?)',
      [
        m['id'], m['title'], m['media_path'], m['media_name'], m['media_kind'],
        m['subtitle_name'], m['source_hash'], m['duration_ms'], m['segment_count'],
        m['created_at'], m['last_practiced_at'],
      ],
    );
  }

  @override
  Future<void> deleteMaterial(String id) async {
    await _db.transaction(() async {
      await _exec('DELETE FROM dictation_attempt WHERE material_id = ?', [id]);
      await _exec('DELETE FROM material_segment WHERE material_id = ?', [id]);
      await _exec('DELETE FROM material WHERE id = ?', [id]);
    });
  }

  @override
  Future<List<MaterialSegment>> segments(String materialId) async {
    final rows = await _query(
      'SELECT * FROM material_segment WHERE material_id = ? ORDER BY seq ASC',
      [materialId],
    );
    return rows.map(MaterialSegment.fromMap).toList();
  }

  @override
  Future<void> replaceSegments(String materialId, List<MaterialSegment> list) async {
    await _db.transaction(() async {
      await _exec('DELETE FROM material_segment WHERE material_id = ?', [materialId]);
      for (final segment in list) {
        final m = segment.toMap();
        await _exec(
          'INSERT OR REPLACE INTO material_segment (id, material_id, seq, text_en, '
          'start_ms, end_ms, word_count, is_hard, created_at) VALUES (?,?,?,?,?,?,?,?,?)',
          [
            m['id'], m['material_id'], m['seq'], m['text_en'], m['start_ms'],
            m['end_ms'], m['word_count'], m['is_hard'], m['created_at'],
          ],
        );
      }
    });
  }

  @override
  Future<void> deleteSegment(String id) async {
    await _db.transaction(() async {
      await _exec('DELETE FROM dictation_attempt WHERE segment_id = ?', [id]);
      await _exec('DELETE FROM material_segment WHERE id = ?', [id]);
    });
  }

  @override
  Future<List<DictationAttempt>> attempts(String materialId) async {
    final rows = await _query(
      'SELECT * FROM dictation_attempt WHERE material_id = ? ORDER BY created_at ASC',
      [materialId],
    );
    return rows.map(DictationAttempt.fromMap).toList();
  }

  @override
  Future<List<DictationAttempt>> allAttempts() async {
    final rows = await _query('SELECT * FROM dictation_attempt ORDER BY created_at ASC');
    return rows.map(DictationAttempt.fromMap).toList();
  }

  @override
  Future<void> upsertAttempt(DictationAttempt attempt) async {
    final m = attempt.toMap();
    await _exec(
      'INSERT OR REPLACE INTO dictation_attempt (id, material_id, segment_id, user_text, '
      'accuracy, passed, diff_json, created_at) VALUES (?,?,?,?,?,?,?,?)',
      [
        m['id'], m['material_id'], m['segment_id'], m['user_text'], m['accuracy'],
        m['passed'], m['diff_json'], m['created_at'],
      ],
    );
  }

  @override
  Future<void> clearAll() async {
    for (final table in [
      'dictation_attempt',
      'material_segment',
      'material',
      'message',
      'correction',
      'session',
      'phrase',
      'llm_profile',
      'setting',
      'tts_cache',
      'app_meta',
      'scenario',
    ]) {
      await _exec('DELETE FROM $table');
    }
  }
}
