import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const edgeOrigin = 'chrome-extension://jdiccldimpdaibmpdkjnbmckianbfold';
const edgeUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36 Edg/130.0.0.0';

WebSocketChannel openEdgeSocket(Uri uri) {
  return IOWebSocketChannel.connect(
    uri,
    headers: {
      'Origin': edgeOrigin,
      'User-Agent': edgeUserAgent,
      'Pragma': 'no-cache',
      'Cache-Control': 'no-cache',
    },
    connectTimeout: const Duration(seconds: 4),
  );
}
