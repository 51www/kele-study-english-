import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kele_speak/data/db/app_database.dart';
import 'package:kele_speak/data/db/drift_store.dart';
import 'package:sqlite3/sqlite3.dart';

/// 覆盖安装回归：v1 老库升到 v2 时只新增三张表，老表与老数据保持原样。
void main() {
  test('v1 → v2 只建二期表，老表数据不丢', () async {
    final raw = sqlite3.openInMemory();
    raw.execute(
      'CREATE TABLE setting ("key" TEXT NOT NULL, "value" TEXT NOT NULL, '
      'PRIMARY KEY ("key"));',
    );
    raw.execute(
      "INSERT INTO setting (\"key\", \"value\") VALUES ('asr.model', 'demo-model');",
    );
    raw.execute(
      'CREATE TABLE phrase (id TEXT NOT NULL PRIMARY KEY, text_en TEXT NOT NULL, '
      'created_at INTEGER NOT NULL);',
    );
    raw.execute(
      "INSERT INTO phrase (id, text_en, created_at) VALUES "
      "('p1', 'I would like a coffee', 1000);",
    );
    raw.execute('PRAGMA user_version = 1;');

    final db = AppDatabase(NativeDatabase.opened(raw));
    final store = DriftStore(db);

    // 任意一次查询都会触发 drift 的迁移。
    expect(await store.setting('asr.model'), 'demo-model');

    final tableRows =
        await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'table'").get();
    final names = tableRows.map((row) => row.read<String>('name')).toSet();
    expect(
      names.containsAll(<String>[
        'setting',
        'phrase',
        'material',
        'material_segment',
        'dictation_attempt',
      ]),
      isTrue,
    );

    final versionRows = await db.customSelect('PRAGMA user_version').get();
    expect(versionRows.first.read<int>('user_version'), 2);

    // 老表内容没被改写，新表可写。
    final phraseRows = await db.customSelect('SELECT text_en FROM phrase').get();
    expect(phraseRows.single.read<String>('text_en'), 'I would like a coffee');
    expect(await store.materials(), isEmpty);

    await db.close();
  });
}
