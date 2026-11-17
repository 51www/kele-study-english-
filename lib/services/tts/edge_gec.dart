import 'dart:convert';
import 'dart:typed_data';

/// Sec-MS-GEC v2 签名生成（微软 2025-11 起强制）。
///
/// 算法移植自 edge-tts 7.3.x 的 drm.py：token = `CS64 16hex - SHA256 64hex`，
/// 其中 SHA256 是带盐中态（midstate）的变体实现（轮常量表被打乱），不能换成标准库；
/// 所有运算都是 32 位截断，Dart 的 64 位 int 溢出后取低 32 位与
/// Python 大整数 & 0xFFFFFFFF 结果一致（乘加均在模 2^64 下保低 32 位）。

const int _u32Mask = 0xFFFFFFFF;

// —— SHA-256 变体的预计算中态常量（与 drm.py 一一对应）——
const List<int> _sha256Initial = [
  0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A,
  0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19,
];
const List<int> _sha256State = [
  0xFD9FBEA2, 0x91243CE7, 0xBE499094, 0xCD2E1E0A,
  0x6C006F49, 0x04BD35AB, 0xFEB0A7E4, 0x03EFFBD2,
];
const List<int> _sha256Schedule = [
  0xEB24BF9E, 0x1558691F, 0xA0C09EE2, 0x0CFA32BA,
  0xA622EE8C, 0xD1DD9491, 0xC0DD25A0, 0xF9E70AB6,
  0xF0C31573, 0x7058CE4E, 0x7188E606, 0x00E5AB33,
  0xD258B060, 0x72766564,
];
const List<int> _sha256RoundConstants = [
  0x428A2F98, 0x71374491, 0xB5C0FBCF, 0xE9B5DBA5,
  0x3956C25B, 0x59F111F1, 0x923F82A4, 0xAB1C5ED5,
  0xD807AA98, 0x12835B01, 0x243185BE, 0x550C7DC3,
  0x72BE5D74, 0x80DEB1FE, 0x9BDC06A7, 0xC19BF174,
  0xE49B69C1, 0xEFBE4786, 0x0FC19DC6, 0x240CA1CC,
  0x2DE92C6F, 0x4A7484AA, 0x5CB0A9DC, 0x76F988DA,
  0x983E5152, 0xA831C66D, 0xB00327C8, 0xBF597FC7,
  0xC6E00BF3, 0xD5A79147, 0x06CA6351, 0x14292967,
  0x27B70A85, 0x2E1B2138, 0x4D2C6DFC, 0x53380D13,
  0x650A7354, 0x766A0ABB, 0x81C2C92E, 0x92722C85,
  0xA2BFE8A1, 0xA81A664B, 0xC24B8B70, 0xC76C51A3,
  0xD192E819, 0xD6990624, 0xF40E3585, 0x106AA070,
  0x19A4C116, 0x1E376C08, 0x2748774C, 0x34B0BCB5,
  0x391C0CB3, 0x4ED8AA4A, 0x5B9CCA4F, 0x682E6FF3,
  0x748F82EE, 0x78A5636F, 0x84C87814, 0x8CC70208,
  0x90BEFFFA, 0xA4506CEB, 0xBEF9A3F7, 0xC67178F2,
];
const int _sha256Adjustment = 0xC9DC06A7;
const int _sigma0Adjustment = 0x059C0B80;
const int _sigma1Adjustment = 0x000B92C0;

// —— CS64 常量 ——
const List<List<int>> _cs64Coefficients = [
  [0xE82E91B1, 0xB32700D0],
  [0x44DE24C6, 0x88DFF51D],
  [0x3BEB65BC, 0x29514038],
  [0xC89C5933, 0xB328CBDF],
  [0x8D1EC211, 0xD405B4D5],
  [0x314EF5D5, 0x26E55F3C],
  [0xE92491B1, 0x607801C6],
  [0xF0A5B9D5, 0x82B2C1FB],
  [0x06064CF3, 0xFA51A3DA],
  [0xDA79FA60, 0x207CC464],
  [0xBED20560, 0x3C3C74F3],
  [0x89F9C9F8, 0xD2D14B61],
  [0x35FA38C6, 0xBB04A2C1],
  [0xCB49E3C6, 0xC5626167],
];
const int _cs64Factor = 0x82893933;
const int _cs64Adjustment0 = 0xF2F90B1A;
const int _cs64Adjustment1 = 0x0B1A0000;

const int _winEpoch = 11644473600;

int _rol16(int value) => ((value << 16) | (value >> 16)) & _u32Mask;

/// SHA-256 σ0/σ1（合并旋转写法，等价标准定义）。
int _sigma0(int value) =>
    ((value >> 7) ^ (value << 25) ^ (value >> 18) ^ (value << 14) ^ (value >> 3)) &
        _u32Mask;
int _sigma1(int value) =>
    ((value >> 17) ^ (value << 15) ^ (value >> 19) ^ (value << 13) ^ (value >> 10)) &
        _u32Mask;

int _rotr(int value, int n) => ((value >> n) | (value << (32 - n))) & _u32Mask;

/// 标准 SHA-256 压缩轮（从 [firstRound] 恢复执行到 63），
/// 与 drm.py 的展开实现等价；第 14 轮用修正常量。
List<int> _sha256Rounds(List<int> state, List<int> words, int firstRound) {
  var a = state[0], b = state[1], c = state[2], d = state[3];
  var e = state[4], f = state[5], g = state[6], h = state[7];
  for (var i = firstRound; i < 64; i++) {
    final k = (i == 14 && firstRound == 14)
        ? _sha256Adjustment
        : _sha256RoundConstants[i];
    final t1 = (h +
            (_rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25)) +
            (g ^ (e & (f ^ g))) +
            k +
            words[i]) &
        _u32Mask;
    final t2 = ((_rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22)) +
            ((a & b) | (c & (a | b)))) &
        _u32Mask;
    h = g;
    g = f;
    f = e;
    e = (d + t1) & _u32Mask;
    d = c;
    c = b;
    b = a;
    a = (t1 + t2) & _u32Mask;
  }
  return [a, b, c, d, e, f, g, h];
}

void _expandSchedule(List<int> words, int firstWord) {
  for (var index = firstWord; index < 64; index++) {
    final x = words[index - 2], y = words[index - 15];
    final sigma1 =
        ((x >> 17) ^ (x << 15) ^ (x >> 19) ^ (x << 13) ^ (x >> 10)) & _u32Mask;
    final sigma0 =
        ((y >> 7) ^ (y << 25) ^ (y >> 18) ^ (y << 14) ^ (y >> 3)) & _u32Mask;
    words.add((sigma1 + words[index - 7] + sigma0 + words[index - 16]) & _u32Mask);
  }
}

/// 首块中态：由消息前 7 字节驱动（ticks 字符串前缀，随时间变化）。
List<int> _sha256Midstate(List<int> data) {
  final words = List<int>.filled(16, 0, growable: true);
  words[14] = (data[0] << 16) | (data[1] << 8) | data[2];
  words[15] =
      (data[3] << 24) | (data[4] << 16) | (data[5] << 8) | data[6];
  for (var index = 16; index < 30; index++) {
    var value = _sha256Schedule[index - 16];
    if (index - 2 >= 14) {
      value += index == 16
          ? (_sigma1(words[index - 2]) ^ _sigma1Adjustment)
          : _sigma1(words[index - 2]);
    }
    if (index - 7 >= 14) value += words[index - 7];
    if (index - 15 >= 14) {
      value += index == 29
          ? (_sigma0(words[index - 15]) ^ _sigma0Adjustment)
          : _sigma0(words[index - 15]);
    }
    words.add(value & _u32Mask);
  }
  words.add(
      (_sigma1(words[28]) +
          words[23] +
          _sigma0(words[15]) +
          words[14] +
          _sha256Adjustment -
          _sha256RoundConstants[14]) &
          _u32Mask);
  _expandSchedule(words, 31);
  final working = _sha256Rounds(_sha256State, words, 14);
  return List.generate(
      8, (i) => (_sha256Initial[i] + working[i]) & _u32Mask);
}

/// drm.py 的 `_sha256_digest`：带盐长度字段的 SHA-256 变体。
Uint8List _sha256Digest(List<int> data) {
  final length = 57 + data.length;
  final padded = List<int>.from(data.sublist(7));
  padded.add(0x80);
  var zeroCount = (55 - length) % 64;
  if (zeroCount < 0) zeroCount += 64;
  padded.addAll(List<int>.filled(zeroCount, 0));
  final bitLength = length * 8;
  padded.addAll([
    (bitLength >> 56) & 0xFF, (bitLength >> 48) & 0xFF,
    (bitLength >> 40) & 0xFF, (bitLength >> 32) & 0xFF,
    (bitLength >> 24) & 0xFF, (bitLength >> 16) & 0xFF,
    (bitLength >> 8) & 0xFF, bitLength & 0xFF,
  ]);
  var state = _sha256Midstate(data);
  for (var offset = 0; offset < padded.length; offset += 64) {
    final words = <int>[];
    for (var i = 0; i < 16; i++) {
      final p = offset + i * 4;
      words.add((padded[p] << 24) |
          (padded[p + 1] << 16) |
          (padded[p + 2] << 8) |
          padded[p + 3]);
    }
    _expandSchedule(words, 16);
    final working = _sha256Rounds(state, words, 0);
    state = List.generate(
        8, (i) => (state[i] + working[i]) & _u32Mask);
  }
  final out = Uint8List(32);
  for (var i = 0; i < 8; i++) {
    out[i * 4] = (state[i] >> 24) & 0xFF;
    out[i * 4 + 1] = (state[i] >> 16) & 0xFF;
    out[i * 4 + 2] = (state[i] >> 8) & 0xFF;
    out[i * 4 + 3] = state[i] & 0xFF;
  }
  return out;
}

/// drm.py 的 `_cs64_digest`：微软自研校验算法。
List<int> _cs64Digest(List<int> data, Uint8List digest) {
  var keyA = (digest[0] | (digest[1] << 8) | (digest[2] << 16) | (digest[3] << 24)) &
      _u32Mask;
  var keyB = (digest[4] | (digest[5] << 8) | (digest[6] << 16) | (digest[7] << 24)) &
      _u32Mask;
  keyA |= 1;
  keyB |= 1;
  final factorA = (keyA * _cs64Factor) & _u32Mask;
  final factorB = (keyB * _cs64Factor) & _u32Mask;

  final terms = <int>[
    for (var i = 0; i < _cs64Coefficients.length; i++)
      (_cs64Coefficients[i][0] * (i % 2 == 0 ? factorA : factorB)) & _u32Mask,
  ];
  final offsets = <int>[
    for (final c in _cs64Coefficients) c[1],
  ];

  // _words_le4_even(b'\x00' + data)：前置 0 字节后按小端 32 位切词，
  // 补齐到偶数个词（Python 版在奇数时会补一个 0 词，必须保留，影响状态链）。
  final buf = <int>[0, ...data];
  final wordCount = (buf.length + 3) ~/ 4;
  final totalWords = wordCount + (wordCount % 2);
  for (var index = 0; index < totalWords; index++) {
    final p = index * 4;
    var word = 0;
    for (var i = 3; i >= 0; i--) {
      word = (word << 8) | (p + i < buf.length ? buf[p + i] : 0);
    }
    word &= _u32Mask;
    var term = word * (index % 2 == 0 ? keyA : keyB);
    var off = _rol16(word) * (index % 2 == 0 ? 0xEF0569FB : 0xC31713DB);
    if (index == 0) {
      term += _cs64Adjustment0 * factorA;
      off += _cs64Adjustment1;
    }
    terms.add(term & _u32Mask);
    offsets.add(off & _u32Mask);
  }

  var swapAcc = 0, swapLast = 0, state = 0, acc = 0;
  for (var index = 0; index < terms.length; index += 2) {
    final x = terms[index], y = terms[index + 1];
    var t = _rol16((offsets[index] + x) & _u32Mask);
    var q = (t * 0x76F50F34) & _u32Mask;
    swapAcc = (swapAcc + (_rol16(q) * 0xC3EFEA97 + q)) & _u32Mask;
    t = _rol16((offsets[index + 1] + y) & _u32Mask);
    q = (t * 0x1881CE3C) & _u32Mask;
    swapLast = (_rol16(q) * 0x35BD1EC9 + q) & _u32Mask;
    swapAcc = (swapAcc + swapLast) & _u32Mask;

    state = (state * keyA + x) & _u32Mask;
    state = (_rol16(state) * 0xCF98B111) & _u32Mask;
    state = (_rol16(state) * 0x87085B9F) & _u32Mask;
    state = (_rol16(state) * 0x12CEB96D) & _u32Mask;
    state = (_rol16(state) * 0x257E1D83) & _u32Mask;
    acc = (acc + state) & _u32Mask;
    var tmp = (state * keyB + y) & _u32Mask;
    tmp = (_rol16(tmp) * 0xA27416F5) & _u32Mask;
    tmp = (_rol16(tmp) * 0xD38396FF) & _u32Mask;
    state = (_rol16((_rol16(tmp) * 0x7C932B89) & _u32Mask) * 0xBFA49F69) & _u32Mask;
    acc = (acc + state) & _u32Mask;
  }
  return [swapLast ^ state, swapAcc ^ acc];
}

/// CS64 词按小端字节序输出 hex（Python `struct.pack('<II')` 后再 hex）。
String _hex32LE(int v) {
  final bytes = [
    v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF,
  ];
  return bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join()
      .toUpperCase();
}
String _hex64Digest(Uint8List digest) =>
    digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();

/// token 格式：`CS64 16hex - SHA256 64hex`（81 字符）。
String generateSecMsGecV2({DateTime? at}) {
  var seconds = (at ?? DateTime.now()).toUtc().millisecondsSinceEpoch / 1000.0;
  seconds += _winEpoch;
  seconds -= seconds % 300;
  final ticks = seconds * 1e7; // 秒 → 100ns FILETIME tick
  final strToHash = utf8.encode('${ticks.toStringAsFixed(0)}$_trustedToken');
  final digest = _sha256Digest(strToHash);
  final cs64 = _cs64Digest(strToHash, digest);
  return '${_hex32LE(cs64[0])}${_hex32LE(cs64[1])}-${_hex64Digest(digest)}';
}

// 当前 TrustedClientToken（与drm.py constants.py 一致）。
const String _trustedToken = '6A5AA1D4EAFF4E9FB37E23D68491D6F4';

/// 仅供测试对拍：对固定输入串（ticks+token）输出 [cs64hex, sha256hex]。
List<String> tokenHashHexForTest(List<int> data) {
  final digest = _sha256Digest(data);
  final cs64 = _cs64Digest(data, digest);
  return ['${_hex32LE(cs64[0])}${_hex32LE(cs64[1])}', _hex64Digest(digest)];
}
