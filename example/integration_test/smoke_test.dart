/// Integration test for flutter_test_server.
///
/// Prerequisites:
///   1. Run the example app: flutter run (on emulator or device)
///   2. Forward port: adb forward tcp:8342 tcp:8342 (Android only)
///   3. Run this test: dart test integration_test/smoke_test.dart

import 'dart:convert';

import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

const baseUrl = 'http://localhost:8342';
const wsUrl = 'ws://localhost:8342/ws';

void main() {
  group('REST API', () {
    test('/about returns app info', () async {
      final response = await http.get(Uri.parse('$baseUrl/about'));
      expect(response.statusCode, 200);
      final json = jsonDecode(response.body);
      expect(json['serverVersion'], isNotNull);
    });

    test('/tree returns widget tree', () async {
      final response = await http.get(Uri.parse('$baseUrl/tree'));
      expect(response.statusCode, 200);
      final json = jsonDecode(response.body);
      expect(json['type'], isNotNull);
    });

    test('/tree?type=Text finds Text widgets', () async {
      final response = await http.get(Uri.parse('$baseUrl/tree?type=Text'));
      expect(response.statusCode, 200);
      final json = jsonDecode(response.body);
      expect(json['count'], greaterThan(0));
      // Should find the instructions text
      final texts = (json['results'] as List)
          .map((r) => r['properties']?['text'] as String?)
          .where((t) => t != null)
          .toList();
      expect(texts, contains(contains('pushed the button')));
    });

    test('/tree?key=counter finds counter widget', () async {
      final response = await http.get(Uri.parse('$baseUrl/tree?key=counter'));
      expect(response.statusCode, 200);
      final json = jsonDecode(response.body);
      expect(json['count'], greaterThan(0));
    });

    test('/screenshot returns PNG', () async {
      final response = await http.get(Uri.parse('$baseUrl/screenshot'));
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], 'image/png');
      expect(response.bodyBytes.length, greaterThan(100));
    });

    test('POST /tap increments counter', () async {
      // Get initial counter value
      var treeResponse = await http.get(Uri.parse('$baseUrl/tree?key=counter'));
      var counterNode = jsonDecode(treeResponse.body)['results'][0];
      final initialText = counterNode['properties']['text'];

      // Tap increment button
      final tapResponse = await http.post(
        Uri.parse('$baseUrl/tap'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'key': 'incrementButton'}),
      );
      expect(tapResponse.statusCode, 200);

      // Wait for UI to settle
      await Future.delayed(const Duration(milliseconds: 500));

      // Verify counter incremented
      treeResponse = await http.get(Uri.parse('$baseUrl/tree?key=counter'));
      counterNode = jsonDecode(treeResponse.body)['results'][0];
      final newText = counterNode['properties']['text'];
      expect(int.parse(newText), equals(int.parse(initialText) + 1));
    });

    test('POST /enterText + tap greet button shows greeting', () async {
      // Enter text in name field
      final enterResponse = await http.post(
        Uri.parse('$baseUrl/enterText'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'key': 'nameField', 'text': 'Flutter'}),
      );
      expect(enterResponse.statusCode, 200);

      await Future.delayed(const Duration(milliseconds: 300));

      // Tap greet button
      final tapResponse = await http.post(
        Uri.parse('$baseUrl/tap'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'key': 'greetButton'}),
      );
      expect(tapResponse.statusCode, 200);

      await Future.delayed(const Duration(milliseconds: 500));

      // Verify greeting appeared
      final treeResponse = await http.get(Uri.parse('$baseUrl/tree?key=greetingText'));
      final json = jsonDecode(treeResponse.body);
      expect(json['count'], greaterThan(0));
      final greetingText = json['results'][0]['properties']['text'];
      expect(greetingText, 'Hello, Flutter!');
    });
  });

  group('WebSocket', () {
    late WebSocketChannel channel;
    late Stream<dynamic> broadcastStream;

    setUp(() {
      channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      broadcastStream = channel.stream.asBroadcastStream();
    });

    tearDown(() {
      channel.sink.close();
    });

    Future<Map<String, dynamic>> sendAndWait(
      Map<String, dynamic> message, {
      bool waitForIdle = false,
    }) async {
      channel.sink.add(jsonEncode(message));
      Map<String, dynamic>? result;
      await for (final msg in broadcastStream) {
        final json = jsonDecode(msg as String) as Map<String, dynamic>;
        // Skip the initial connected event
        if (json['event'] == 'connected') continue;
        // If waiting for idle, collect the action response and then wait for idle
        if (waitForIdle) {
          if (json['event'] == 'idle' && json['id'] == message['id']) {
            return result ?? json;
          }
          if (json['id'] == message['id'] && json['status'] != null) {
            result = json;
            continue;
          }
        } else {
          if (json['id'] == message['id']) return json;
        }
      }
      throw StateError('Stream closed without response');
    }

    test('connects and receives version', () async {
      final msg = await broadcastStream.first;
      final json = jsonDecode(msg as String);
      expect(json['event'], 'connected');
      expect(json['version'], isNotNull);
    });

    test('tap via WebSocket increments counter', () async {
      // Skip connected event
      await broadcastStream.first;

      // Reset counter first
      await sendAndWait(
        {'action': 'tap', 'key': 'resetButton', 'id': 'reset1'},
        waitForIdle: true,
      );

      // Tap increment
      final result = await sendAndWait(
        {'action': 'tap', 'key': 'incrementButton', 'id': 'tap1'},
        waitForIdle: true,
      );
      expect(result['status'], 'ok');

      // Find counter value
      final findResult = await sendAndWait(
        {'action': 'find', 'key': 'counter', 'id': 'find1'},
      );
      expect(findResult['status'], 'ok');
      expect(findResult['widget']['properties']['text'], '1');
    });

    test('enterText via WebSocket', () async {
      // Skip connected event
      await broadcastStream.first;

      // Enter text
      final result = await sendAndWait(
        {'action': 'enterText', 'key': 'nameField', 'text': 'WebSocket', 'id': 'enter1'},
        waitForIdle: true,
      );
      expect(result['status'], 'ok');

      // Tap greet
      await sendAndWait(
        {'action': 'tap', 'key': 'greetButton', 'id': 'greet1'},
        waitForIdle: true,
      );

      // Find greeting
      final findResult = await sendAndWait(
        {'action': 'find', 'key': 'greetingText', 'id': 'find2'},
      );
      expect(findResult['status'], 'ok');
      expect(findResult['widget']['properties']['text'], 'Hello, WebSocket!');
    });
  });
}
