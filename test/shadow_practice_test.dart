import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kele_speak/data/db/app_database.dart';
import 'package:kele_speak/data/db/drift_store.dart';
import 'package:kele_speak/data/repositories/repositories.dart';

void main() {
  late AppDatabase db;
  late DriftStore store;
  late ShadowPracticeRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = DriftStore(db);
    repo = ShadowPracticeRepository(store);
  });

  tearDown(() => db.close());

  test('按天累计材料练习耗时，读写一致且互不串日', () async {
    final day1 = DateTime(2026, 11, 17, 10);
    final day2 = DateTime(2026, 11, 18, 10);

    expect(await repo.secondsOn(day1), 0);

    await repo.addSeconds(day1, 40);
    await repo.addSeconds(day1, 35);
    await repo.addSeconds(day2, 20);

    expect(await repo.secondsOn(day1), 75);
    expect(await repo.secondsOn(day2), 20);
    expect(await repo.activeDays(), {'2026-11-17', '2026-11-18'});
  });

  test('非正数秒数不写入，坏数据按空处理', () async {
    await repo.addSeconds(DateTime(2026, 11, 17), -5);
    await repo.addSeconds(DateTime(2026, 11, 17), 0);
    expect(await repo.all(), isEmpty);

    await store.setMeta('shadow.sec.by_day', 'not-json');
    expect(await repo.all(), isEmpty);
    expect(await repo.activeDays(), isEmpty);
  });
}
