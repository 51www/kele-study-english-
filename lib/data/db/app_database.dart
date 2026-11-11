import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// 9 张表与《开发文档》§4 字段一一对应。
/// 列名使用 snake_case，保证与 Web 兜底存储的 JSON 字段一致。
class Scenarios extends Table {
  @override
  String get tableName => 'scenario';

  TextColumn get id => text()();
  TextColumn get titleZh => text().named('title_zh')();
  TextColumn get titleEn => text().named('title_en')();
  TextColumn get category => text()();
  TextColumn get level => text()();
  TextColumn get aiRole => text().named('ai_role')();
  TextColumn get userGoal => text().named('user_goal')();
  TextColumn get openingLine => text().named('opening_line')();
  TextColumn get targetPhrases => text().named('target_phrases')();
  IntColumn get expectedTurns => integer().named('expected_turns')();
  TextColumn get successCriteria => text().named('success_criteria')();
  TextColumn get branchHint => text().named('branch_hint').nullable()();
  IntColumn get isBuiltin => integer().named('is_builtin')();
  IntColumn get sortOrder => integer().named('sort_order')();

  @override
  Set<Column> get primaryKey => {id};
}

class Sessions extends Table {
  @override
  String get tableName => 'session';

  TextColumn get id => text()();
  TextColumn get scenarioId => text().named('scenario_id').nullable()();
  IntColumn get startedAt => integer().named('started_at')();
  IntColumn get endedAt => integer().named('ended_at').nullable()();
  IntColumn get durationSec => integer().named('duration_sec')();
  IntColumn get turnCount => integer().named('turn_count')();
  IntColumn get hintCount => integer().named('hint_count')();
  IntColumn get assistTurns => integer().named('assist_turns')();
  IntColumn get translateCount => integer().named('translate_count')();
  TextColumn get status => text()();
  TextColumn get modelName => text().named('model_name').nullable()();
  TextColumn get ttsEngine => text().named('tts_engine').nullable()();
  TextColumn get reviewJson => text().named('review_json').nullable()();
  RealColumn get costEstimate => real().named('cost_estimate').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Messages extends Table {
  @override
  String get tableName => 'message';

  TextColumn get id => text()();
  TextColumn get sessionId => text().named('session_id')();
  IntColumn get seq => integer()();
  TextColumn get role => text()();
  TextColumn get textEn => text().named('text_en')();
  TextColumn get textZh => text().named('text_zh').nullable()();
  TextColumn get audioPath => text().named('audio_path').nullable()();
  TextColumn get asrProvider => text().named('asr_provider').nullable()();
  IntColumn get latencyMs => integer().named('latency_ms').nullable()();
  IntColumn get isHint => integer().named('is_hint')();
  IntColumn get hintLevel => integer().named('hint_level').nullable()();
  TextColumn get status => text()();
  IntColumn get createdAt => integer().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class Corrections extends Table {
  @override
  String get tableName => 'correction';

  TextColumn get id => text()();
  TextColumn get sessionId => text().named('session_id')();
  TextColumn get messageId => text().named('message_id')();
  TextColumn get original => text()();
  TextColumn get improved => text()();
  TextColumn get reasonZh => text().named('reason_zh')();
  TextColumn get audioPath => text().named('audio_path').nullable()();
  IntColumn get isDeleted => integer().named('is_deleted')();
  IntColumn get createdAt => integer().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class Phrases extends Table {
  @override
  String get tableName => 'phrase';

  TextColumn get id => text()();
  TextColumn get textEn => text().named('text_en')();
  TextColumn get textZh => text().named('text_zh').nullable()();
  TextColumn get sourceSessionId => text().named('source_session_id').nullable()();
  TextColumn get sourceScenarioId => text().named('source_scenario_id').nullable()();
  TextColumn get audioPath => text().named('audio_path').nullable()();
  IntColumn get mastered => integer()();
  IntColumn get createdAt => integer().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class LlmProfiles extends Table {
  @override
  String get tableName => 'llm_profile';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get baseUrl => text().named('base_url')();
  TextColumn get model => text()();
  TextColumn get keyRef => text().named('key_ref')();
  TextColumn get extraJson => text().named('extra_json').nullable()();
  TextColumn get lastCheckStatus => text().named('last_check_status').nullable()();
  TextColumn get lastCheckMessage => text().named('last_check_message').nullable()();
  IntColumn get lastCheckedAt => integer().named('last_checked_at').nullable()();
  IntColumn get isActive => integer().named('is_active')();

  @override
  Set<Column> get primaryKey => {id};
}

class SettingsTable extends Table {
  @override
  String get tableName => 'setting';

  TextColumn get key => text()();
  TextColumn get value => text()();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {key};
}

class TtsCaches extends Table {
  @override
  String get tableName => 'tts_cache';

  TextColumn get hash => text()();
  TextColumn get engine => text()();
  TextColumn get voice => text()();
  RealColumn get rate => real()();
  TextColumn get filePath => text().named('file_path')();
  IntColumn get bytes => integer()();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get lastUsedAt => integer().named('last_used_at')();

  @override
  Set<Column> get primaryKey => {hash};
}

class AppMetas extends Table {
  @override
  String get tableName => 'app_meta';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

// 二期（需求 F11–F15）：教材 / 句子 / 听写记录。老表一律不改。
class Materials extends Table {
  @override
  String get tableName => 'material';

  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get mediaPath => text().named('media_path')();
  TextColumn get mediaName => text().named('media_name')();
  TextColumn get mediaKind => text().named('media_kind')();
  TextColumn get subtitleName => text().named('subtitle_name')();
  TextColumn get sourceHash => text().named('source_hash')();
  IntColumn get durationMs => integer().named('duration_ms')();
  IntColumn get segmentCount => integer().named('segment_count')();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get lastPracticedAt => integer().named('last_practiced_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class MaterialSegments extends Table {
  @override
  String get tableName => 'material_segment';

  TextColumn get id => text()();
  TextColumn get materialId => text().named('material_id')();
  IntColumn get seq => integer()();
  TextColumn get textEn => text().named('text_en')();
  IntColumn get startMs => integer().named('start_ms')();
  IntColumn get endMs => integer().named('end_ms')();
  IntColumn get wordCount => integer().named('word_count')();
  IntColumn get isHard => integer().named('is_hard')();
  IntColumn get createdAt => integer().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class DictationAttempts extends Table {
  @override
  String get tableName => 'dictation_attempt';

  TextColumn get id => text()();
  TextColumn get materialId => text().named('material_id')();
  TextColumn get segmentId => text().named('segment_id')();
  TextColumn get userText => text().named('user_text')();
  RealColumn get accuracy => real()();
  IntColumn get passed => integer()();
  TextColumn get diffJson => text().named('diff_json')();
  IntColumn get createdAt => integer().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  Scenarios,
  Sessions,
  Messages,
  Corrections,
  Phrases,
  LlmProfiles,
  SettingsTable,
  TtsCaches,
  AppMetas,
  Materials,
  MaterialSegments,
  DictationAttempts,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  static Future<AppDatabase> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'kele_speak.sqlite'));
    return AppDatabase(NativeDatabase.createInBackground(file));
  }

  /// v1 → v2 只新增二期三张表；老表不 ALTER / 不 DROP / 不回填。
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(materials);
            await m.createTable(materialSegments);
            await m.createTable(dictationAttempts);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
