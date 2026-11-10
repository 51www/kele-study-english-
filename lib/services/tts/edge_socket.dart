import 'package:web_socket_channel/web_socket_channel.dart';

import 'edge_socket_io.dart' if (dart.library.js_interop) 'edge_socket_web.dart';

/// 平台差异：Android 用 IOWebSocketChannel 携带自定义请求头；
/// 浏览器无法设置受限制的请求头，直接使用浏览器 WebSocket 连接。
WebSocketChannel connectEdgeSocket(Uri uri) => openEdgeSocket(uri);
