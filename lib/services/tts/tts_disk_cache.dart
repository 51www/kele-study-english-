import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/logger.dart';
import '../../data/db/local_store.dart';
import '../../domain/models/models.dart';
import 'tts_cache.dart';

/// 朗读音频的落盘缓存（M2 / T2.3）。
///
/// - 内存 LRU 由 [TtsCache] 负责；本类把同一份字节写到应用私有目录，
///   并在 `tts_cache` 表登记索引，进程重启后仍可命中（断网重听立即可播）。
/// - 超过 80MB 时按最久未使用淘汰：同时删文件与索引。
/// - Web 无文件系统，落盘自动退化成纯内存缓存。
class TtsDiskCache {
  TtsDiskCache(this._store, {this.maxBytes = TtsCache.maxBytes});

  final LocalStore _store;
  final int maxBytes;
  final LinkedHashMap<String, TtsCacheEntry> _index = LinkedHashMap<String, TtsCacheEntry>();
  bool _loaded = false;

  bool get loaded => _loaded;

  bool has(String hash) => _index.containsKey(hash);

  Future<Directory?> _dir() async {
    if (kIsWeb) return null;
    try {
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(base.path, 'tts_cache'));
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir;
    } catch (e) {
      AppLogger.warn('tts cache dir unavailable: $e');
      return null;
    }
  }

  /// 启动时恢复索引：文件已不存在的旧记录直接清掉。
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    if (kIsWeb) return;
    try {
      final rows = await _store.ttsCache();
      for (final row in rows) {
        final file = File(row.filePath);
        if (await file.exists()) {
          _index[row.hash] = row;
          TtsCache.instance.put(row.hash, await file.readAsBytes());
        } else {
          await _store.deleteTtsCache(row.hash);
        }
      }
      await _enforce();
      AppLogger.debug('tts disk cache restored count=${_index.length}');
    } catch (e) {
      AppLogger.warn('tts disk cache load failed: $e');
    }
  }

  Future<Uint8List?> read(String hash) async {
    if (kIsWeb) return null;
    final row = _index.remove(hash);
    if (row == null) return null;
    final file = File(row.filePath);
    if (!await file.exists()) {
      await _store.deleteTtsCache(hash);
      return null;
    }
    final bytes = await file.readAsBytes();
    final now = DateTime.now().millisecondsSinceEpoch;
    final updated = TtsCacheEntry(
      hash: row.hash,
      engine: row.engine,
      voice: row.voice,
      rate: row.rate,
      filePath: row.filePath,
      bytes: row.bytes,
      createdAt: row.createdAt,
      lastUsedAt: now,
    );
    _index[hash] = updated;
    await _store.upsertTtsCache(updated);
    TtsCache.instance.put(hash, bytes);
    return bytes;
  }

  Future<void> write(
    String hash,
    Uint8List bytes, {
    required String voice,
    required double rate,
  }) async {
    TtsCache.instance.put(hash, bytes);
    if (kIsWeb) return;
    try {
      final dir = await _dir();
      if (dir == null) return;
      final file = File(p.join(dir.path, '$hash.mp3'));
      await file.writeAsBytes(bytes, flush: true);
      final now = DateTime.now().millisecondsSinceEpoch;
      final entry = TtsCacheEntry(
        hash: hash,
        engine: 'edge',
        voice: voice,
        rate: rate,
        filePath: file.path,
        bytes: bytes.length,
        createdAt: now,
        lastUsedAt: now,
      );
      _index
        ..remove(hash)
        ..[hash] = entry;
      await _store.upsertTtsCache(entry);
      await _enforce();
    } catch (e) {
      // 落盘失败不影响本次播放。
      AppLogger.warn('tts disk cache write failed: $e');
    }
  }

  int get totalBytes => _index.values.fold<int>(0, (sum, e) => sum + e.bytes);

  Future<void> remove(String hash) async {
    final row = _index.remove(hash);
    TtsCache.instance.remove(hash);
    await _store.deleteTtsCache(hash);
    if (row == null || kIsWeb) return;
    try {
      final file = File(row.filePath);
      if (await file.exists()) await file.delete();
    } catch (e) {
      AppLogger.warn('tts cache file delete failed: $e');
    }
  }

  Future<void> clear() async {
    TtsCache.instance.clear();
    final rows = await _store.ttsCache();
    for (final row in rows) {
      await _store.deleteTtsCache(row.hash);
    }
    _index.clear();
    if (kIsWeb) return;
    try {
      final dir = await _dir();
      if (dir != null && await dir.exists()) await dir.delete(recursive: true);
    } catch (e) {
      AppLogger.warn('tts cache dir clear failed: $e');
    }
  }

  Future<void> _enforce() async {
    var total = totalBytes;
    while (total > maxBytes && _index.isNotEmpty) {
      await remove(_index.keys.first);
      total = totalBytes;
    }
  }
}
