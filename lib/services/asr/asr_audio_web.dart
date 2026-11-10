import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Web 上录音插件返回 blob URL，浏览器可直接通过 XHR 读取字节。
Future<Uint8List?> readAudioBytes(String path) async {
  final dio = Dio();
  try {
    final response = await dio.get<List<int>>(
      path,
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    return data == null ? null : Uint8List.fromList(data);
  } finally {
    dio.close();
  }
}
