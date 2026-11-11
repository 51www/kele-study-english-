import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kele_speak/data/db/app_database.dart';
import 'package:kele_speak/data/db/drift_store.dart';
import 'package:kele_speak/features/dictation/ingest/material_import_service.dart';

// 用假 adapter 拦截 Dio 请求，不真正联网。
class _FakeAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path.toLowerCase();
    if (path.endsWith('.srt')) {
      const srt = '''
1
00:00:01,000 --> 00:00:03,000
I would like a cup of coffee.

2
00:00:05,000 --> 00:00:07,000
Could you give me the bill, please?
''';
      return ResponseBody.fromBytes(utf8.encode(srt), 200);
    }
    if (path.endsWith('.mp3')) {
      return ResponseBody.fromBytes(Uint8List.fromList([0, 1, 2, 3, 4, 5]), 200);
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
        final dir = await Directory.systemTemp.createTemp('kele_url_test');
        return dir.path;
      }
      return null;
    },
  );

  test('链接导入：下载音视频 + 字幕，复用切句与落库', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final store = DriftStore(db);
    final service = MaterialImportService(
      store,
      dio: Dio()..httpClientAdapter = _FakeAdapter(),
    );

    var progressCalls = 0;
    final item = await service.importFromUrl(
      mediaUrl: 'https://example.com/lesson.mp3',
      subtitleUrl: 'https://example.com/lesson.srt',
      title: '线上课',
      onProgress: (_) => progressCalls++,
    );

    expect(item.title, '线上课');
    expect(item.mediaKind, 'audio');
    expect(item.segmentCount, 2);
    expect(progressCalls, greaterThan(0));

    final segments = await store.segments(item.id);
    expect(segments.length, 2);
    expect(segments.first.textEn, 'I would like a cup of coffee.');

    await db.close();
  });

  test('链接导入：字幕为空时报明确错误', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final store = DriftStore(db);
    final service = MaterialImportService(
      store,
      dio: Dio()..httpClientAdapter = _FakeAdapter(),
    );

    expect(
      () => service.importFromUrl(
        mediaUrl: 'https://example.com/lesson.mp3',
        subtitleUrl: 'https://example.com/missing.txt',
        title: 'x',
      ),
      throwsA(isA<MaterialImportException>()),
    );

    await db.close();
  });
}
