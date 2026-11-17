import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kele_speak/services/tts/edge_gec.dart';

void main() {
  // 参考值来自 edge-tts 7.3.x drm.py（Python 侧计算，.logs/gen_dart_consts.py）。
  test('sha256 变体 + CS64 与 Python 参考一致', () {
    final data = utf8.encode(
        '134506200000000000' '6A5AA1D4EAFF4E9FB37E23D68491D6F4');
    final result = tokenHashHexForTest(data);
    expect(result[1],
        'D20C2808DDFE59E4D215A9AFBEE9A5798D15ED9BEC2A59A62197BF2C6FE782E4');
    expect(result[0], '31FCF79F135D1A67');
  });

  test('v2 token 与 Python 参考一致（固定时间戳）', () {
    final at = DateTime.fromMillisecondsSinceEpoch(
        1763300000 * 1000, isUtc: true);
    expect(generateSecMsGecV2(at: at),
        '94381C974396073B-FFCD5514A9F0FF6B9F73E7F116FC067DC611C9C425C5D92D9080F8DA70C1B11F');
  });

  test('当前时间 token 形态合法（81 字符，CS64-SHA256）', () {
    final token = generateSecMsGecV2();
    expect(token.length, 81);
    expect(token.contains('-'), isTrue);
    expect(RegExp(r'^[0-9A-F]{16}-[0-9A-F]{64}$').hasMatch(token), isTrue);
  });
}
