import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/models.dart';
import 'defaults.dart';
import 'local_store.dart';
import 'seeds.dart';

/// Web 兜底实现：SharedPreferences（localStorage）上的 JSON 集合。
/// 字段名与 SQLite 表结构完全一致，仅用于浏览器验证。
class WebStore implements LocalStore {
  WebStore(this._prefs);

  final SharedPreferences _prefs;

  static const _scenarioKey = 'store.scenario';
  static const _sessionKey = 'store.session';
  static const _messageKey = 'store.message';
  static const _correctionKey = 'store.correction';
  static const _phraseKey = 'store.phrase';
  static const _profileKey = 'store.llm_profile';
  static const _settingKey = 'store.setting';
  static const _ttsCacheKey = 'store.tts_cache';
  static const _metaKey = 'store.app_meta';

  static Future<WebStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return WebStore(prefs);
  }

  List<Map<String, Object?>> _read(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => (e as Map).cast<String, Object?>()).toList();
      }
    } catch (_) {
      return [];
    }
    return [];
  }

  Future<void> _write(String key, List<Map<String, Object?>> rows) async {
    await _prefs.setString(key, jsonEncode(rows));
  }

  Future<void> _upsert(String key, String idField, Map<String, Object?> row) async {
    final rows = _read(key);
    final index = rows.indexWhere((e) => e[idField] == row[idField]);
    if (index >= 0) {
      rows[index] = row;
    } else {
      rows.add(row);
    }
    await _write(key, rows);
  }

  Future<void> _delete(String key, bool Function(Map<String, Object?>) test) async {
    final rows = _read(key)..removeWhere(test);
    await _write(key, rows);
  }

  @override
  Future<void> init() async {
    for (final scenario in builtinScenarios) {
      final rows = _read(_scenarioKey);
      final index = rows.indexWhere((e) => e['id'] == scenario.id);
      if (index >= 0) {
        rows[index] = scenario.toMap();
      } else {
        rows.add(scenario.toMap());
      }
      await _write(_scenarioKey, rows);
    }
    final settings = _read(_settingKey);
    for (final entry in defaultSettings.entries) {
      if (!settings.any((e) => e['key'] == entry.key)) {
        settings.add({
          'key': entry.key,
          'value': entry.value,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
      }
    }
    await _write(_settingKey, settings);
  }

  @override
  Future<List<Scenario>> scenarios() async {
    final rows = _read(_scenarioKey)
      ..sort((a, b) => ((a['sort_order'] as num?) ?? 0)
          .compareTo((b['sort_order'] as num?) ?? 0));
    return rows.map(Scenario.fromMap).toList();
  }

  @override
  Future<void> upsertScenario(Scenario scenario) =>
      _upsert(_scenarioKey, 'id', scenario.toMap());

  @override
  Future<void> deleteScenario(String id) => _delete(
        _scenarioKey,
        (e) => e['id'] == id && (e['is_builtin'] ?? 1) == 0,
      );

  @override
  Future<List<SessionRecord>> sessions() async {
    final rows = _read(_sessionKey)
      ..sort((a, b) => ((b['started_at'] as num?) ?? 0)
          .compareTo((a['started_at'] as num?) ?? 0));
    return rows.map(SessionRecord.fromMap).toList();
  }

  @override
  Future<SessionRecord?> session(String id) async {
    final rows = _read(_sessionKey).where((e) => e['id'] == id);
    if (rows.isEmpty) return null;
    return SessionRecord.fromMap(rows.first);
  }

  @override
  Future<void> upsertSession(SessionRecord session) =>
      _upsert(_sessionKey, 'id', session.toMap());

  @override
  Future<void> deleteSession(String id) =>
      _delete(_sessionKey, (e) => e['id'] == id);

  @override
  Future<List<MessageRecord>> messages(String sessionId) async {
    final rows = _read(_messageKey).where((e) => e['session_id'] == sessionId).toList()
      ..sort((a, b) => ((a['seq'] as num?) ?? 0).compareTo((b['seq'] as num?) ?? 0));
    return rows.map(MessageRecord.fromMap).toList();
  }

  @override
  Future<void> upsertMessage(MessageRecord message) =>
      _upsert(_messageKey, 'id', message.toMap());

  @override
  Future<void> deleteMessages(String sessionId) =>
      _delete(_messageKey, (e) => e['session_id'] == sessionId);

  @override
  Future<List<Correction>> corrections(String sessionId) async {
    final rows = _read(_correctionKey)
        .where((e) => e['session_id'] == sessionId && (e['is_deleted'] ?? 0) == 0)
        .toList()
      ..sort((a, b) => ((a['created_at'] as num?) ?? 0)
          .compareTo((b['created_at'] as num?) ?? 0));
    return rows.map(Correction.fromMap).toList();
  }

  @override
  Future<void> upsertCorrection(Correction correction) =>
      _upsert(_correctionKey, 'id', correction.toMap());

  @override
  Future<void> deleteCorrection(String id) =>
      _delete(_correctionKey, (e) => e['id'] == id);

  @override
  Future<void> deleteCorrections(String sessionId) =>
      _delete(_correctionKey, (e) => e['session_id'] == sessionId);

  @override
  Future<List<Phrase>> phrases() async {
    final rows = _read(_phraseKey)
      ..sort((a, b) => ((b['created_at'] as num?) ?? 0)
          .compareTo((a['created_at'] as num?) ?? 0));
    return rows.map(Phrase.fromMap).toList();
  }

  @override
  Future<void> upsertPhrase(Phrase phrase) =>
      _upsert(_phraseKey, 'id', phrase.toMap());

  @override
  Future<void> deletePhrase(String id) => _delete(_phraseKey, (e) => e['id'] == id);

  @override
  Future<LlmProfile?> activeProfile() async {
    final rows = _read(_profileKey).where((e) => (e['is_active'] ?? 1) == 1);
    if (rows.isEmpty) return null;
    return LlmProfile.fromMap(rows.first);
  }

  @override
  Future<void> saveProfile(LlmProfile profile) =>
      _upsert(_profileKey, 'id', profile.toMap());

  @override
  Future<String?> setting(String key) async {
    final rows = _read(_settingKey).where((e) => e['key'] == key);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  @override
  Future<Map<String, String>> settings() async {
    final rows = _read(_settingKey);
    return {for (final row in rows) row['key'] as String: (row['value'] ?? '') as String};
  }

  @override
  Future<void> setSetting(String key, String value) async {
    final rows = _read(_settingKey);
    final index = rows.indexWhere((e) => e['key'] == key);
    final row = {
      'key': key,
      'value': value,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
    if (index >= 0) {
      rows[index] = row;
    } else {
      rows.add(row);
    }
    await _write(_settingKey, rows);
  }

  @override
  Future<List<TtsCacheEntry>> ttsCache() async {
    final rows = _read(_ttsCacheKey)
      ..sort((a, b) => ((b['last_used_at'] as num?) ?? 0)
          .compareTo((a['last_used_at'] as num?) ?? 0));
    return rows.map(TtsCacheEntry.fromMap).toList();
  }

  @override
  Future<void> upsertTtsCache(TtsCacheEntry entry) =>
      _upsert(_ttsCacheKey, 'hash', entry.toMap());

  @override
  Future<void> deleteTtsCache(String hash) =>
      _delete(_ttsCacheKey, (e) => e['hash'] == hash);

  @override
  Future<String?> meta(String key) async {
    final rows = _read(_metaKey).where((e) => e['key'] == key);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  @override
  Future<void> setMeta(String key, String value) async {
    final rows = _read(_metaKey);
    final index = rows.indexWhere((e) => e['key'] == key);
    final row = {'key': key, 'value': value};
    if (index >= 0) {
      rows[index] = row;
    } else {
      rows.add(row);
    }
    await _write(_metaKey, rows);
  }

  @override
  Future<void> clearAll() async {
    for (final key in [
      _scenarioKey,
      _sessionKey,
      _messageKey,
      _correctionKey,
      _phraseKey,
      _profileKey,
      _settingKey,
      _ttsCacheKey,
      _metaKey,
    ]) {
      await _prefs.remove(key);
    }
  }
}
