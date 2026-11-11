import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kele_speak/data/db/app_database.dart';
import 'package:kele_speak/data/db/drift_store.dart';
import 'package:kele_speak/features/dictation/ingest/material_import_service.dart';

/// B 站导入走配套服务：用假 adapter 模拟配套服务的 4 个接口，不真正联网。
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({this.jobState = 'done', this.jobError = '', this.unreachable = false});

  final String jobState;
  final String jobError;
  final bool unreachable;

  static const _srt = '''
1
00:00:01,000 --> 00:00:03,000
I would like a cup of coffee.

2
00:00:05,000 --> 00:00:07,000
Could you give me the bill, please?
''';

  ResponseBody _json(Object data, [int code = 200]) => ResponseBody.fromString(
        jsonEncode(data),
        code,
        headers: {
          'content-type': <String>['application/json'],
        },
      );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path.toLowerCase();
    if (unreachable) return ResponseBody.fromBytes(Uint8List(0), 404);
    if (options.method.toUpperCase() == 'POST' && path.endsWith('/api/bili/import')) {
      return _json({'jobId': 'j1'});
    }
    if (path.endsWith('/api/bili/job/j1')) {
      return _json(<String, dynamic>{
        'jobId': 'j1',
        'state': jobState,
        'progress': jobState == 'done' ? 1 : 0.1,
        'stage': jobState == 'done' ? '完成' : '解析视频信息',
        'title': 'English Listening Practice Ep.1',
        'durationSec': 12,
        'subLang': 'ai-zh',
        'audioExt': 'm4a',
        'error': jobError,
      });
    }
    if (path.endsWith('/api/bili/job/j1/audio')) {
      return ResponseBody.fromBytes(Uint8List.fromList([0, 1, 2, 3, 4, 5]), 200);
    }
    if (path.endsWith('/api/bili/job/j1/subtitle')) {
      return ResponseBody.fromBytes(utf8.encode(_srt), 200);
    }
    return ResponseBody.fromBytes(Uint8List(0), 404);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // 单元测试没有原生 path_provider 实现，桩一个临时目录。
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        final dir = await Directory.systemTemp.createTemp('kele_companion_test');
        return dir.path;
      }
      return null;
    },
  );

  test('B 站导入：提交任务 → 轮询 → 取回音频与字幕 → 复用切句落库', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final store = DriftStore(db);
    final service = MaterialImportService(
      store,
      dio: Dio()..httpClientAdapter = _FakeAdapter(),
    );

    final stages = <String>[];
    final item = await service.importBiliFromCompanion(
      videoUrl: 'https://www.bilibili.com/video/BV1xx?p=2',
      serviceBase: 'http://192.168.1.5:8787/',
      cookie: 'SESSDATA=abc',
      title: '',
      onStatus: (_, stage) => stages.add(stage),
    );

    // 用户没填标题时使用配套服务返回的视频标题。
    expect(item.title, 'English Listening Practice Ep.1');
    expect(item.mediaKind, 'audio');
    expect(item.mediaName, 'audio.m4a');
    expect(item.segmentCount, 2);
    expect(stages, isNotEmpty);

    final segments = await store.segments(item.id);
    expect(segments.length, 2);
    expect(segments.first.textEn, 'I would like a cup of coffee.');

    await db.close();
  });

  test('B 站导入：配套服务报错时把原因透传给导入页', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final store = DriftStore(db);
    final service = MaterialImportService(
      store,
      dio: Dio()
        ..httpClientAdapter = _FakeAdapter(
          jobState: 'error',
          jobError: '没有拿到可用字幕',
        ),
    );

    await expectLater(
      () => service.importBiliFromCompanion(
        videoUrl: 'https://b23.tv/abc',
        serviceBase: 'http://192.168.1.5:8787',
      ),
      throwsA(
        isA<MaterialImportException>().having(
          (e) => e.message,
          'message',
          contains('没有拿到可用字幕'),
        ),
      ),
    );

    await db.close();
  });

  test('B 站导入：配套服务不可达时报可理解的原因', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final store = DriftStore(db);
    final service = MaterialImportService(
      store,
      dio: Dio()..httpClientAdapter = _FakeAdapter(unreachable: true),
    );

    await expectLater(
      () => service.importBiliFromCompanion(
        videoUrl: 'https://www.bilibili.com/video/BV1xx',
        serviceBase: 'http://192.168.1.5:8787',
      ),
      throwsA(
        isA<MaterialImportException>().having(
          (e) => e.message,
          'message',
          contains('配套服务'),
        ),
      ),
    );

    await db.close();
  });

  test('B 站导入：服务地址不合法直接报错，不发起请求', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final store = DriftStore(db);
    final service = MaterialImportService(
      store,
      dio: Dio()..httpClientAdapter = _FakeAdapter(),
    );

    await expectLater(
      () => service.importBiliFromCompanion(
        videoUrl: 'https://www.bilibili.com/video/BV1xx',
        serviceBase: 'not-a-url',
      ),
      throwsA(
        isA<MaterialImportException>().having(
          (e) => e.message,
          'message',
          contains('配套服务地址不正确'),
        ),
      ),
    );

    await db.close();
  });
}
