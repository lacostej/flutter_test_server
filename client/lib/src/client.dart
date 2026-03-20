import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'widget_info.dart';

/// Client for driving a Flutter app via flutter_test_server.
///
/// Provides methods for finding widgets, tapping, entering text,
/// taking screenshots, and waiting for the UI to settle.
class FlutterTestClient {
  final String baseUrl;
  final Duration defaultTimeout;

  FlutterTestClient({
    this.baseUrl = 'http://localhost:8342',
    this.defaultTimeout = const Duration(seconds: 10),
  });

  // -- Query --

  /// Get app info (platform, screen size, build mode, etc.).
  Future<Map<String, dynamic>> about() async {
    final response = await http.get(Uri.parse('$baseUrl/about'));
    _checkResponse(response, '/about');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Find a widget by key.
  Future<WidgetInfo?> findByKey(String key) async {
    final results = await _findWidgets({'key': key});
    return results.isNotEmpty ? results.first : null;
  }

  /// Find a widget by semantics label.
  Future<WidgetInfo?> findBySemantics(String label) async {
    final results = await _findWidgets({'semantics': label});
    return results.isNotEmpty ? results.first : null;
  }

  /// Find all widgets of a given type.
  Future<List<WidgetInfo>> findByType(String type) async {
    return _findWidgets({'type': type});
  }

  /// Find widgets matching the given filters.
  Future<List<WidgetInfo>> _findWidgets(Map<String, String> filters) async {
    final uri = Uri.parse('$baseUrl/tree').replace(queryParameters: filters);
    final response = await http.get(uri);
    _checkResponse(response, '/tree');
    final json = jsonDecode(response.body);
    final results = json['results'] as List;
    return results.map((r) => WidgetInfo.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Get the text content of a widget found by key.
  Future<String?> getTextByKey(String key) async {
    final widget = await findByKey(key);
    return widget?.text;
  }

  // -- Actions --

  /// Tap a widget found by key.
  Future<void> tapByKey(String key) async {
    await _tap({'key': key});
  }

  /// Tap a widget found by semantics label.
  Future<void> tapBySemantics(String label) async {
    await _tap({'semantics': label});
  }

  /// Tap at specific coordinates.
  Future<void> tapAt(double x, double y) async {
    await _tap({'x': x, 'y': y});
  }

  Future<void> _tap(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tap'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _checkResponse(response, '/tap');
  }

  /// Enter text into a widget found by key. Taps the field first to focus.
  Future<void> enterTextByKey(String key, String text, {bool append = false}) async {
    await _enterText({'key': key, 'text': text, 'append': append});
  }

  /// Enter text into the currently focused field.
  Future<void> enterText(String text, {bool append = false}) async {
    await _enterText({'text': text, 'append': append});
  }

  Future<void> _enterText(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl/enterText'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _checkResponse(response, '/enterText');
  }

  /// Take a screenshot and return the PNG bytes.
  Future<List<int>> screenshot() async {
    final response = await http.get(Uri.parse('$baseUrl/screenshot'));
    _checkResponse(response, '/screenshot');
    return response.bodyBytes;
  }

  /// Take a screenshot and save to a file.
  Future<void> screenshotToFile(String path) async {
    final bytes = await screenshot();
    await File(path).writeAsBytes(bytes);
  }

  // -- Waiting --

  /// Wait until a widget with the given key appears.
  /// Polls at [interval] until [timeout].
  Future<WidgetInfo> waitForKey(
    String key, {
    Duration? timeout,
    Duration interval = const Duration(milliseconds: 200),
  }) async {
    return _waitFor(
      () => findByKey(key),
      'widget with key "$key"',
      timeout: timeout ?? defaultTimeout,
      interval: interval,
    );
  }

  /// Wait until a widget with the given key has specific text.
  Future<WidgetInfo> waitForText(
    String key,
    String expectedText, {
    Duration? timeout,
    Duration interval = const Duration(milliseconds: 200),
  }) async {
    return _waitFor(
      () async {
        final widget = await findByKey(key);
        return widget?.text == expectedText ? widget : null;
      },
      'widget "$key" with text "$expectedText"',
      timeout: timeout ?? defaultTimeout,
      interval: interval,
    );
  }

  /// Wait until a Text widget containing [substring] appears.
  Future<WidgetInfo> waitForTextContaining(
    String substring, {
    Duration? timeout,
    Duration interval = const Duration(milliseconds: 200),
  }) async {
    return _waitFor(
      () async {
        final widgets = await findByType('Text');
        for (final w in widgets) {
          if (w.text != null && w.text!.contains(substring)) return w;
        }
        return null;
      },
      'Text containing "$substring"',
      timeout: timeout ?? defaultTimeout,
      interval: interval,
    );
  }

  Future<WidgetInfo> _waitFor(
    Future<WidgetInfo?> Function() finder,
    String description, {
    required Duration timeout,
    required Duration interval,
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final result = await finder();
      if (result != null) return result;
      await Future.delayed(interval);
    }
    throw TimeoutException('Timed out waiting for $description', timeout);
  }

  // -- Helpers --

  void _checkResponse(http.Response response, String endpoint) {
    if (response.statusCode != 200) {
      throw FlutterTestClientException(
        endpoint: endpoint,
        statusCode: response.statusCode,
        body: response.body,
      );
    }
  }
}

class FlutterTestClientException implements Exception {
  final String endpoint;
  final int statusCode;
  final String body;

  FlutterTestClientException({
    required this.endpoint,
    required this.statusCode,
    required this.body,
  });

  @override
  String toString() => 'FlutterTestClientException: $endpoint returned $statusCode: $body';
}
