import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kele_speak/data/db/app_database.dart'
    hide Material, MaterialSegment, DictationAttempt;
import 'package:kele_speak/data/db/drift_store.dart';
import 'package:kele_speak/domain/models/dictation_models.dart';

void main() {
  late AppDatabase db;
  late DriftStore store;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = DriftStore(db);
  });

  tearDown(() => db.close());

  test('v2 建出二期三张表，教材 / 句子 / 记录可读写', () async {
    const item = MaterialItem(
      id: 'm1',
      title: 'Lesson 1',
      mediaPath: '/tmp/a.mp3',
      mediaName: 'a.mp3',
      mediaKind: 'audio',
      subtitleName: 'a.srt',
      sourceHash: 'hash-1',
      durationMs: 60000,
      segmentCount: 2,
      createdAt: 1000,
    );
    await store.upsertMaterial(item);
    expect((await store.materials()).single.title, 'Lesson 1');
    expect((await store.materialByHash('hash-1'))?.id, 'm1');

    final List<MaterialSegment> segments = [
      MaterialSegment(
        id: 's1',
        materialId: 'm1',
        seq: 0,
        textEn: 'Hello there my friend.',
        startMs: 0,
        endMs: 4000,
        wordCount: 4,
        createdAt: 1000,
      ),
      MaterialSegment(
        id: 's2',
        materialId: 'm1',
        seq: 1,
        textEn: 'See you tomorrow morning.',
        startMs: 4000,
        endMs: 9000,
        wordCount: 4,
        isHard: true,
        createdAt: 1000,
      ),
    ];
    await store.replaceSegments('m1', segments);
    expect((await store.segments('m1')).length, 2);
    expect((await store.segments('m1')).last.isHard, isTrue);

    final attempt = DictationAttempt(
      id: 'a1',
      materialId: 'm1',
      segmentId: 's1',
      userText: 'Hello there my friend',
      accuracy: 1,
      passed: true,
      diffJson: '[]',
      createdAt: 2000,
    );
    await store.upsertAttempt(attempt);
    expect((await store.attempts('m1')).single.passed, isTrue);
    expect((await store.allAttempts()).length, 1);

    // 重复导入判定
    expect((await store.materialByHash('hash-1'))?.id, 'm1');
  });

  test('删除教材级联删除句子与记录；清空所有数据清掉二期表', () async {
    await store.upsertMaterial(const MaterialItem(
      id: 'm1',
      title: 'Lesson 1',
      mediaPath: '/tmp/a.mp3',
      mediaName: 'a.mp3',
      mediaKind: 'audio',
      subtitleName: 'a.srt',
      sourceHash: 'hash-1',
      durationMs: 60000,
      segmentCount: 1,
      createdAt: 1000,
    ));
    await store.replaceSegments('m1', [
      MaterialSegment(
        id: 's1',
        materialId: 'm1',
        seq: 0,
        textEn: 'Hello there my friend.',
        startMs: 0,
        endMs: 4000,
        wordCount: 4,
        createdAt: 1000,
      ),
    ]);
    await store.upsertAttempt(const DictationAttempt(
      id: 'a1',
      materialId: 'm1',
      segmentId: 's1',
      userText: 'Hello there my friend',
      accuracy: 1,
      passed: true,
      diffJson: '[]',
      createdAt: 2000,
    ));

    await store.deleteMaterial('m1');
    expect(await store.material('m1'), isNull);
    expect(await store.segments('m1'), isEmpty);
    expect(await store.attempts('m1'), isEmpty);

    await store.clearAll();
    expect(await store.materials(), isEmpty);
    expect(await store.allAttempts(), isEmpty);
  });
}
