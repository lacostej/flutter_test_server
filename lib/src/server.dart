import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;

import 'routes/about.dart';
import 'routes/eval.dart';
import 'routes/screenshot.dart';
import 'routes/tree.dart';
import 'vm_service/eval_service.dart';

/// Embeddable HTTP server that exposes a REST API for test automation.
///
/// Wrap your app with [FlutterTestServer] to start the server:
///
/// ```dart
/// void main() {
///   runApp(
///     FlutterTestServer(
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
class FlutterTestServer extends StatefulWidget {
  /// The app widget to wrap.
  final Widget child;

  /// The port to listen on. Defaults to 8342 (homage to Unium).
  final int port;

  /// The address to bind to. Defaults to any IPv4 address.
  final String address;

  const FlutterTestServer({
    super.key,
    required this.child,
    this.port = 8342,
    this.address = '0.0.0.0',
  });

  @override
  State<FlutterTestServer> createState() => _FlutterTestServerState();
}

class _FlutterTestServerState extends State<FlutterTestServer> {
  HttpServer? _server;
  final EvalService _evalService = EvalService();

  @override
  void initState() {
    super.initState();
    // Start the server after the first frame so the widget tree is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startServer();
    });
  }

  Future<void> _startServer() async {
    final router = shelf_router.Router();

    // /about — synchronous, safe to call from any isolate
    router.get('/about', (shelf.Request request) {
      return _runOnMainThread(() => handleAbout(request));
    });

    // /tree — needs access to the widget tree, must run on main thread
    router.get('/tree', (shelf.Request request) {
      return _runOnMainThread(() => handleTree(request));
    });

    // /screenshot — needs access to render objects, must run on main thread
    router.get('/screenshot', (shelf.Request request) {
      return _runOnMainThread(() => handleScreenshot(request));
    });

    // /eval — VM service calls
    router.post('/eval', (shelf.Request request) async {
      try {
        return await handleEval(request, _evalService);
      } catch (e, st) {
        debugPrint('FlutterTestServer /eval error: $e\n$st');
        return shelf.Response.internalServerError(
          body: '{"error": "${e.toString().replaceAll('"', '\\"')}"}',
          headers: {'Content-Type': 'application/json'},
        );
      }
    });

    // CORS middleware for browser-based tools
    final handler = const shelf.Pipeline()
        .addMiddleware(_corsMiddleware())
        .addMiddleware(shelf.logRequests())
        .addHandler(router.call);

    try {
      _server = await shelf_io.serve(
        handler,
        widget.address,
        widget.port,
      );
      debugPrint(
        'FlutterTestServer listening on '
        'http://${widget.address}:${widget.port}',
      );
    } catch (e) {
      debugPrint('FlutterTestServer failed to start: $e');
    }
  }

  /// Dispatches a callback to the main (UI) thread and returns the result.
  /// shelf's server runs on a separate isolate/thread, but widget tree access
  /// must happen on the main isolate.
  Future<shelf.Response> _runOnMainThread(
    FutureOr<shelf.Response> Function() callback,
  ) {
    final completer = Completer<shelf.Response>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final response = await callback();
        completer.complete(response);
      } catch (e, st) {
        debugPrint('FlutterTestServer handler error: $e\n$st');
        completer.complete(shelf.Response.internalServerError(
          body: 'Internal error: $e',
        ));
      }
    });
    // Trigger a frame so the callback runs even if the UI is idle.
    WidgetsBinding.instance.ensureVisualUpdate();
    return completer.future;
  }

  shelf.Middleware _corsMiddleware() {
    return (shelf.Handler innerHandler) {
      return (shelf.Request request) async {
        if (request.method == 'OPTIONS') {
          return shelf.Response.ok('', headers: _corsHeaders);
        }
        final response = await innerHandler(request);
        return response.change(headers: _corsHeaders);
      };
    };
  }

  static const _corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  };

  @override
  void dispose() {
    _server?.close(force: true);
    _evalService.dispose();
    debugPrint('FlutterTestServer stopped');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
