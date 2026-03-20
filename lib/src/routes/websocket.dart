import 'dart:async';
import 'dart:convert';

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'enter_text.dart';
import 'tap.dart';

/// Create a shelf handler for WebSocket connections at /ws.
Handler createWebSocketHandler(
  Future<Response> Function(Future<Response> Function()) runOnMainThread,
) {
  return webSocketHandler((WebSocketChannel channel) {
    channel.stream.listen(
      (message) async {
        try {
          final json = jsonDecode(message as String) as Map<String, dynamic>;
          final action = json['action'] as String?;
          final id = json['id']; // optional request ID for correlation

          switch (action) {
            case 'tap':
              await runOnMainThread(() async {
                final target = _resolveTarget(json);
                if (target == null) {
                  _send(channel, {'id': id, 'status': 'error', 'error': 'Widget not found'});
                  return Response.ok(''); // unused, just for type
                }
                dispatchTap(target);
                _send(channel, {'id': id, 'status': 'ok', 'action': 'tap', 'x': target.dx, 'y': target.dy});
                return Response.ok('');
              });
              // Wait for idle after the action
              await _waitForIdle();
              _send(channel, {'id': id, 'event': 'idle'});
              break;

            case 'find':
              await runOnMainThread(() async {
                final node = findTargetWidget(json);
                if (node == null) {
                  _send(channel, {'id': id, 'status': 'error', 'error': 'Widget not found'});
                } else {
                  _send(channel, {'id': id, 'status': 'ok', 'widget': node.toJson()});
                }
                return Response.ok('');
              });
              break;

            case 'enterText':
              await runOnMainThread(() async {
                final text = json['text'] as String?;
                if (text == null) {
                  _send(channel, {'id': id, 'status': 'error', 'error': 'Missing "text" field'});
                  return Response.ok('');
                }
                // If target specified, tap to focus first
                final hasTarget = json.containsKey('key') ||
                    json.containsKey('semantics') ||
                    json.containsKey('type');
                if (hasTarget) {
                  final target = _resolveTarget(json);
                  if (target != null) {
                    dispatchTap(target);
                    await Future.delayed(const Duration(milliseconds: 200));
                  }
                }
                bool result = false;
                for (int i = 0; i < 10 && !result; i++) {
                  result = enterTextInFocusedField(text, append: json['append'] as bool? ?? false);
                  if (!result) await Future.delayed(const Duration(milliseconds: 100));
                }
                if (result) {
                  _send(channel, {'id': id, 'status': 'ok', 'action': 'enterText', 'text': text});
                } else {
                  _send(channel, {'id': id, 'status': 'error', 'error': 'No focused text field found'});
                }
                return Response.ok('');
              });
              await _waitForIdle();
              _send(channel, {'id': id, 'event': 'idle'});
              break;

            case 'waitForIdle':
              await _waitForIdle();
              _send(channel, {'id': id, 'event': 'idle'});
              break;

            case 'screenshot':
              await runOnMainThread(() async {
                // Reuse the existing screenshot handler logic
                final binding = WidgetsBinding.instance;
                final rootElement = binding.rootElement;
                if (rootElement == null) {
                  _send(channel, {'id': id, 'status': 'error', 'error': 'No root element'});
                  return Response.ok('');
                }
                // For WebSocket, we send a base64-encoded PNG
                final renderObject = rootElement.renderObject;
                if (renderObject is RenderRepaintBoundary) {
                  final image = await renderObject.toImage(pixelRatio: 2.0);
                  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                  if (byteData != null) {
                    final base64Png = base64Encode(byteData.buffer.asUint8List());
                    _send(channel, {'id': id, 'status': 'ok', 'format': 'png_base64', 'data': base64Png});
                  }
                } else {
                  _send(channel, {'id': id, 'status': 'error', 'error': 'Root is not a RenderRepaintBoundary'});
                }
                return Response.ok('');
              });
              break;

            default:
              _send(channel, {'id': id, 'status': 'error', 'error': 'Unknown action: $action'});
          }
        } catch (e, st) {
          _send(channel, {'status': 'error', 'error': e.toString(), 'stackTrace': st.toString()});
        }
      },
      onDone: () {
        debugPrint('FlutterTestServer: WebSocket client disconnected');
      },
    );

    _send(channel, {'event': 'connected', 'version': '0.2.0'});
    debugPrint('FlutterTestServer: WebSocket client connected');
  });
}

Offset? _resolveTarget(Map<String, dynamic> json) {
  final x = (json['x'] as num?)?.toDouble();
  final y = (json['y'] as num?)?.toDouble();
  if (x != null && y != null) return Offset(x, y);

  final node = findTargetWidget(json);
  if (node == null) return null;
  if (node.x == null || node.y == null || node.width == null || node.height == null) {
    return null;
  }
  return Offset(node.x! + node.width! / 2, node.y! + node.height! / 2);
}

/// Wait until the Flutter framework has no more scheduled frames.
Future<void> _waitForIdle() async {
  // Give the framework a moment to schedule any post-tap work
  await Future.delayed(const Duration(milliseconds: 100));

  final completer = Completer<void>();
  void check(Duration _) {
    if (!SchedulerBinding.instance.hasScheduledFrame) {
      completer.complete();
    } else {
      SchedulerBinding.instance.addPostFrameCallback(check);
    }
  }
  SchedulerBinding.instance.addPostFrameCallback(check);
  SchedulerBinding.instance.ensureVisualUpdate();
  return completer.future.timeout(
    const Duration(seconds: 10),
    onTimeout: () {
      debugPrint('FlutterTestServer: waitForIdle timed out after 10s');
    },
  );
}

void _send(WebSocketChannel channel, Map<String, dynamic> data) {
  channel.sink.add(jsonEncode(data));
}
