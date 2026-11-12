import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kele_speak/data/db/app_database.dart';
import 'package:kele_speak/data/db/drift_store.dart';
import 'package:kele_speak/features/retention/review_item.dart';
import 'package:sqlite3/sqlite3.dart';

/// 覆盖安装回归：v1 老库升到 v3 时只新增表（二期 3 张 + 三期 1 张），
/// 老表与老数据保持原样；v2 老库升到 v3 同理。
void main() {
  test('v1 → v3 只建二期与三期表，老表数据不丢', () async {
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
        'review_item',
      ]),
      isTrue,
    );

    final versionRows = await db.customSelect('PRAGMA user_version').get();
    expect(versionRows.first.read<int>('user_version'), 3);

    // 老表内容没被改写，新表可写。
    final phraseRows = await db.customSelect('SELECT text_en FROM phrase').get();
    expect(phraseRows.single.read<String>('text_en'), 'I would like a coffee');
    expect(await store.materials(), isEmpty);
    expect(await store.reviewItems(), isEmpty);

    await db.close();
  });

  test('v2 → v3 只建三期表，老数据不丢且新表可读写', () async {
    final raw = sqlite3.openInMemory();
    raw.execute(
      'CREATE TABLE setting ("key" TEXT NOT NULL, "value" TEXT NOT NULL, '
      'PRIMARY KEY ("key"));',
    );
    raw.execute(
      "INSERT INTO setting (\"key\", \"value\") VALUES ('asr.model', 'demo-model');",
    );
    raw.execute('PRAGMA user_version = 2;');

    final db = AppDatabase(NativeDatabase.opened(raw));
    final store = DriftStore(db);

    expect(await store.setting('asr.model'), 'demo-model');

    final tableRows =
        await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'table'").get();
    final names = tableRows.map((row) => row.read<String>('name')).toSet();
    expect(names.contains('review_item'), isTrue);

    final versionRows = await db.customSelect('PRAGMA user_version').get();
    expect(versionRows.first.read<int>('user_version'), 3);

    final now = DateTime.now().millisecondsSinceEpoch;
    await store.upsertReviewItem(
      ReviewScheduler.create(
        id: 'rv_1',
        sourceType: 'correction',
        sourceId: 's1',
        textEn: 'Could I get a flat white, please?',
        nowMs: now,
      ),
    );
    expect((await store.reviewItems()).single.textEn,
        'Could I get a flat white, please?');
    await store.deleteReviewItem('rv_1');
    expect(await store.reviewItems(), isEmpty);

    final settingRows = await db.customSelect('SELECT value FROM setting').get();
    expect(settingRows.single.read<String>('value'), 'demo-model');

    await db.close();
  });
}
