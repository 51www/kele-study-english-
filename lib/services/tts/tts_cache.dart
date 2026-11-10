import 'dart:collection';
import 'dart:typed_data';

/// 朗读音频缓存：仅缓存 Edge TTS 返回的音频字节（系统 TTS 直接发声，无可缓存音频）。
///
/// - 键：`engine|voice|rate|sha1(text)`，见 [TtsRouter]。
/// - 策略：内存 LRU，总量上限 80MB，超出按最久未使用淘汰。
/// - 生命周期：进程内有效；清缓存入口在「设置 → 清理朗读缓存」。
class TtsCache {
  TtsCache._();

  static final TtsCache instance = TtsCache._();

  /// 上限 80MB。
  static const int maxBytes = 80 * 1024 * 1024;

  final LinkedHashMap<String, Uint8List> _entries = LinkedHashMap<String, Uint8List>();
  int _bytes = 0;
  int _hits = 0;
  int _misses = 0;

  int get sizeBytes => _bytes;
  int get count => _entries.length;
  int get hits => _hits;
  int get misses => _misses;

  bool contains(String key) => _entries.containsKey(key);

  Uint8List? get(String key) {
    final hit = _entries.remove(key);
    if (hit == null) {
      _misses++;
      return null;
    }
    // 重新插入到末尾，维持 LRU 顺序。
    _entries[key] = hit;
    _hits++;
    return hit;
  }

  void put(String key, Uint8List bytes) {
    if (bytes.isEmpty) return;
    if (bytes.length > maxBytes) return;
    final old = _entries.remove(key);
    if (old != null) _bytes -= old.length;
    _entries[key] = bytes;
    _bytes += bytes.length;
    while (_bytes > maxBytes && _entries.isNotEmpty) {
      final oldest = _entries.keys.first;
      final removed = _entries.remove(oldest);
      if (removed != null) _bytes -= removed.length;
    }
  }

  void remove(String key) {
    final removed = _entries.remove(key);
    if (removed != null) _bytes -= removed.length;
  }

  void clear() {
    _entries.clear();
    _bytes = 0;
  }
}
