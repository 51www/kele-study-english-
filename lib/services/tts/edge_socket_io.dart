import 'dart:io';
import 'dart:math';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const edgeOrigin = 'chrome-extension://jdiccldimpdaibmpdkjnbmckianbfold';
const edgeUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/143.0.0.0';

/// 随机 MUID（与 edge-tts 一致：32 位大写 hex，随连接生成）。
String generateEdgeMuid() {
  final rng = Random.secure();
  return List.generate(32, (_) => '0123456789ABCDEF'[rng.nextInt(16)]).join();
}

/// 微软会按 UA 指纹拒绝非浏览器客户端：dart:io 默认把
/// "Dart/x.x (dart:io)" 拼在自定义 UA 前面，导致握手 403。
/// 因此必须用 [HttpClient.userAgent] 携带干净的 Edge UA，而不是在 headers
/// 里传 User-Agent（headers 里传会被合并成 "Dart/…, Edg/…"）。
WebSocketChannel openEdgeSocket(Uri uri) {
  final client = HttpClient();
  client.userAgent = edgeUserAgent;
  client.connectionTimeout = const Duration(seconds: 4);
  return IOWebSocketChannel.connect(
    uri,
    headers: {
      'Origin': edgeOrigin,
      'Pragma': 'no-cache',
      'Accept-Language': 'en-US,en;q=0.9',
      'Cookie': 'muid=${generateEdgeMuid()};',
    },
    customClient: client,
    connectTimeout: const Duration(seconds: 4),
  );
}
