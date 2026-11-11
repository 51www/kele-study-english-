import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../data/db/local_store.dart';
import '../../../domain/models/dictation_models.dart';
import '../align/segment_splitter.dart';
import 'subtitle_parser.dart';

class MaterialImportException implements Exception {
  const MaterialImportException(this.message, {this.existingId});

  final String message;
  final String? existingId;

  @override
  String toString() => message;
}

/// 素材导入：支持「本地文件」与「链接下载」两条路线，二者走同一套
/// 字幕解析 / 切句 / 落库逻辑，只是素材来源不同。
///
/// - 本地文件：纯音频复制到 App 私有目录；视频只记路径，不复制整份文件。
/// - 链接下载：把音视频与字幕下载到内存，音频/视频写入 App 私有目录（下载内容本就没有外部路径）。
/// - Web 端（浏览器验证）只在本进程内存里保留 blob / data URI，重启后提示重新导入。
///
/// 不做端内转码、不显示视频画面、不抓取平台内容。
class MaterialImportService {
  final LocalStore _store;
  final Map<String, String> _webUris = <String, String>{};
  final Dio dio;

  MaterialImportService(this._store, {Dio? dio}) : dio = dio ?? Dio();

  static const audioExtensions = <String>{
    'mp3', 'm4a', 'aac', 'wav', 'flac', 'ogg', 'opus',
  };
  static const videoExtensions = <String>{
    'mp4', 'mkv', 'mov', 'webm', 'm4v',
  };
  static const subtitleExtensions = <String>{'srt', 'vtt'};

  static const _mimeByExt = <String, String>{
    'mp3': 'audio/mpeg',
    'm4a': 'audio/mp4',
    'aac': 'audio/aac',
    'wav': 'audio/wav',
    'flac': 'audio/flac',
    'ogg': 'audio/ogg',
    'opus': 'audio/ogg',
    'mp4': 'video/mp4',
    'mkv': 'video/x-matroska',
    'mov': 'video/quicktime',
    'webm': 'video/webm',
    'm4v': 'video/mp4',
  };

  // ---- 路线 A：本地文件 ----

  Future<MaterialItem> importFiles({
    required PlatformFile media,
    required PlatformFile subtitle,
    required String title,
  }) async {
    final mediaExt = (media.extension ?? '').toLowerCase();
    final subtitleExt = (subtitle.extension ?? '').toLowerCase();
    if (!audioExtensions.contains(mediaExt) && !videoExtensions.contains(mediaExt)) {
      throw const MaterialImportException(
        '媒体格式不支持，请选 MP3 / M4A / WAV / MP4 等本地音频或视频文件。',
      );
    }
    if (!subtitleExtensions.contains(subtitleExt)) {
      throw const MaterialImportException('字幕只支持 .srt / .vtt，请重新选择字幕文件。');
    }
    final mediaBytes = await media.readAsBytes();
    final subtitleBytes = await subtitle.readAsBytes();
    return _createMaterial(
      mediaBytes: mediaBytes,
      mediaName: media.name,
      mediaExt: mediaExt,
      subtitleBytes: subtitleBytes,
      subtitleName: subtitle.name,
      title: title,
      webUri: kIsWeb ? media.uri?.toString() : null,
    );
  }

  // ---- 路线 C：链接下载 ----

  /// 从 http(s) 链接下载音视频与（可选）字幕，复用同一套解析落库逻辑。
  /// [onProgress] 在 0..1 之间回报整体进度（下载占 0.9，落库占 0.1）。
  Future<MaterialItem> importFromUrl({
    required String mediaUrl,
    String? subtitleUrl,
    required String title,
    void Function(double progress)? onProgress,
  }) async {
    final mediaBytes = await _download(
      mediaUrl,
      (c, t) => onProgress?.call((t > 0 ? c / t : 0) * 0.9),
    );
    final mediaName = _nameFromUrl(mediaUrl, isSubtitle: false);
    final mediaExt = _extOf(mediaName);

    Uint8List? subtitleBytes;
    String? subtitleName;
    final sub = subtitleUrl?.trim();
    if (sub != null && sub.isNotEmpty) {
      subtitleBytes = await _download(
        sub,
        (c, t) => onProgress?.call(0.9 + (t > 0 ? c / t : 0) * 0.1),
      );
      subtitleName = _nameFromUrl(sub, isSubtitle: true);
    }
    onProgress?.call(0.95);
    final item = await _createMaterial(
      mediaBytes: mediaBytes,
      mediaName: mediaName,
      mediaExt: mediaExt,
      subtitleBytes: subtitleBytes ?? Uint8List(0),
      subtitleName: subtitleName ?? 'subtitle.vtt',
      title: title,
      webUri: null,
    );
    onProgress?.call(1);
    return item;
  }

  Future<Uint8List> _download(
    String url,
    void Function(int received, int total)? onProgress,
  ) async {
    final trimmed = url.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const MaterialImportException('链接格式不对，请填写 http(s) 开头的音频或字幕链接。');
    }
    try {
      final resp = await dio.get<Uint8List>(
        trimmed,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 2),
        ),
        onReceiveProgress: onProgress,
      );
      final data = resp.data;
      if (data == null || data.isEmpty) {
        throw const MaterialImportException('下载到的是空文件，请检查链接是否失效。');
      }
      return data;
    } on DioException catch (e) {
      throw MaterialImportException('下载失败：${e.message ?? e.type.name}');
    }
  }

  String _nameFromUrl(String url, {required bool isSubtitle}) {
    final uri = Uri.tryParse(url.trim());
    final base = uri?.pathSegments.where((s) => s.isNotEmpty).lastOrNull;
    if (base == null || !base.contains('.')) {
      return isSubtitle ? 'subtitle.vtt' : 'audio.mp3';
    }
    return base.split('?').first;
  }

  String _extOf(String name) => name.contains('.') ? name.split('.').last.toLowerCase() : '';

  // ---- 共用落库 ----

  Future<MaterialItem> _createMaterial({
    required Uint8List mediaBytes,
    required String mediaName,
    required String mediaExt,
    required Uint8List subtitleBytes,
    required String subtitleName,
    required String title,
    required String? webUri,
  }) async {
    if (!audioExtensions.contains(mediaExt) && !videoExtensions.contains(mediaExt)) {
      throw const MaterialImportException(
        '媒体格式不支持，链接应指向 MP3 / M4A / WAV / MP4 等可播放的音频或视频。',
      );
    }
    if (subtitleBytes.isEmpty) {
      throw const MaterialImportException('没有可解析的字幕内容，请填写字幕链接或改用本地文件导入。');
    }

    final parsed = SubtitleParser.parse(subtitleBytes, fileName: subtitleName);
    final drafts = splitSegments(parsed.cues);
    if (drafts.isEmpty) {
      throw const MaterialImportException(
        '字幕里没有可练的英文句子（可能全是音乐或音效标注），请换一份字幕。',
      );
    }

    final hash = _hashBytes(mediaName, mediaBytes, subtitleName, subtitleBytes);
    final existing = await _store.materialByHash(hash);
    if (existing != null) {
      throw MaterialImportException(
        '这份教材已经导入过了：${existing.title}。可以直接打开它继续练。',
        existingId: existing.id,
      );
    }

    final id = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    late final String mediaPath;
    late final String mediaKind;

    if (kIsWeb) {
      mediaKind = 'web';
      mediaPath = webUri ?? _dataUri(mediaBytes, mediaExt);
    } else {
      final dir = await _materialsDir();
      final dest = File(p.join(dir.path, '$id.$mediaExt'));
      await dest.writeAsBytes(mediaBytes);
      mediaPath = dest.path;
      // 下载得到的视频没有外部源文件，必须落盘才能反复播放。
      mediaKind = audioExtensions.contains(mediaExt) ? 'audio' : 'video';
    }

    final item = MaterialItem(
      id: id,
      title: title.trim().isEmpty ? _defaultTitle(mediaName) : title.trim(),
      mediaPath: mediaPath,
      mediaName: mediaName,
      mediaKind: mediaKind,
      subtitleName: subtitleName,
      sourceHash: hash,
      durationMs: parsed.durationMs,
      segmentCount: drafts.length,
      createdAt: now,
    );
    final segments = <MaterialSegment>[
      for (var i = 0; i < drafts.length; i++)
        MaterialSegment(
          id: const Uuid().v4(),
          materialId: id,
          seq: i,
          textEn: drafts[i].text,
          startMs: drafts[i].startMs,
          endMs: drafts[i].endMs,
          wordCount: drafts[i].wordCount,
          createdAt: now,
        ),
    ];
    await _store.upsertMaterial(item);
    await _store.replaceSegments(id, segments);
    return item;
  }

  String _dataUri(Uint8List bytes, String ext) =>
      Uri.dataFromBytes(bytes, mimeType: _mimeByExt[ext] ?? 'application/octet-stream').toString();

  /// 片段播放器用的媒体地址；源文件失效时给明确提示，不静默失败。
  Uri playableUri(MaterialItem item) {
    if (item.mediaKind == 'web') {
      final raw = _webUris[item.id];
      if (raw == null) {
        throw const MaterialImportException(
          '浏览器重启后不会保留媒体文件，请重新导入这份教材。',
        );
      }
      return Uri.parse(raw);
    }
    if (item.mediaPath.isEmpty) {
      throw const MaterialImportException('找不到这份教材的源文件，请重新导入。');
    }
    if (!kIsWeb && !File(item.mediaPath).existsSync()) {
      throw const MaterialImportException(
        '源文件已被移动或删除，请重新导入这份教材（句子与练习记录会保留）。',
      );
    }
    return kIsWeb ? Uri.parse(item.mediaPath) : Uri.file(item.mediaPath);
  }

  Future<void> deleteAsset(MaterialItem item) async {
    _webUris.remove(item.id);
    if (kIsWeb || item.mediaKind != 'audio' || item.mediaPath.isEmpty) return;
    final file = File(item.mediaPath);
    if (await file.exists()) await file.delete();
  }

  /// 清理 App 私有目录里所有音频副本，返回删除文件数。
  Future<int> clearAssets() async {
    if (kIsWeb) return 0;
    final dir = await _materialsDir();
    if (!await dir.exists()) return 0;
    var count = 0;
    await for (final entity in dir.list()) {
      if (entity is File) {
        await entity.delete();
        count++;
      }
    }
    _webUris.clear();
    return count;
  }

  Future<Directory> _materialsDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'materials'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  String _hashBytes(
    String mediaName,
    Uint8List mediaBytes,
    String subtitleName,
    Uint8List subtitleBytes,
  ) {
    final builder = BytesBuilder()
      ..add(utf8.encode('$mediaName|${mediaBytes.length}|$subtitleName|'))
      ..add(mediaBytes)
      ..add(subtitleBytes);
    return sha256.convert(builder.takeBytes()).toString();
  }

  String _defaultTitle(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot > 0 ? fileName.substring(0, dot) : fileName;
  }
}
