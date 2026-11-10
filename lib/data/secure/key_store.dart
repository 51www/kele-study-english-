import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/logger.dart';

/// 密钥存取封装：Android 走系统安全存储（Keystore）。
///
/// Web 上 flutter_secure_storage 使用浏览器 WebCrypto + localStorage；
/// 若浏览器环境不可用，退化为 localStorage（仅 Web 验证兜底，Android 不用）。
class KeyStore {
  KeyStore({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<String?> read(String ref) async {
    try {
      return await _storage.read(key: ref);
    } catch (e) {
      AppLogger.warn('secure storage read failed: ${e.runtimeType}');
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString('web_key_$ref');
      }
      return null;
    }
  }

  Future<void> write(String ref, String value) async {
    try {
      await _storage.write(key: ref, value: value);
    } catch (e) {
      AppLogger.warn('secure storage write failed: ${e.runtimeType}');
      if (!kIsWeb) rethrow;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('web_key_$ref', value);
    }
  }

  Future<void> delete(String ref) async {
    try {
      await _storage.delete(key: ref);
    } catch (_) {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('web_key_$ref');
      }
    }
  }

  /// 只显示尾 4 位。
  static String mask(String? key) {
    if (key == null || key.isEmpty) return '未填写';
    if (key.length <= 4) return '••••';
    return '•••• ${key.substring(key.length - 4)}';
  }
}
