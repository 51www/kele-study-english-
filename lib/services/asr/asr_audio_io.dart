import 'dart:io';
import 'dart:typed_data';

Future<Uint8List?> readAudioBytes(String path) async {
  final file = File(path);
  if (!await file.exists()) return null;
  return file.readAsBytes();
}
