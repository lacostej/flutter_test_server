/// Integration test for flutter_test_server.
///
/// Prerequisites:
///   1. Run the example app: flutter run (on emulator or device)
///   2. Forward port: adb forward tcp:8342 tcp:8342 (Android only)
///   3. Run this test: dart test integration_test/smoke_test.dart

import 'package:flutter_test_server_client/flutter_test_server_client.dart';
import 'package:test/test.dart';

import 'pages/counter_page.dart';

void main() {
  late FlutterTestClient client;
  late CounterPage counterPage;

  setUpAll(() {
    client = FlutterTestClient();
  });

  setUp(() {
    counterPage = CounterPage(client);
  });

  group('server', () {
    test('is reachable', () async {
      final info = await client.about();
      expect(info['serverVersion'], isNotNull);
      expect(info['buildMode'], 'debug');
    });

    test('can take screenshot', () async {
      final bytes = await client.screenshot();
      expect(bytes.length, greaterThan(100));
    });

    test('can find widgets by type', () async {
      final texts = await client.findByType('Text');
      expect(texts.length, greaterThan(0));
      final hasInstructions = texts.any((w) =>
          w.text != null && w.text!.contains('pushed the button'));
      expect(hasInstructions, isTrue);
    });
  });

  group('counter', () {
    setUp(() async {
      await counterPage.reset();
    });

    test('starts at zero', () async {
      expect(await counterPage.getCount(), 0);
    });

    test('increments on tap', () async {
      await counterPage.increment();
      expect(await counterPage.getCount(), 1);
    });

    test('increments multiple times', () async {
      await counterPage.increment();
      await counterPage.increment();
      await counterPage.increment();
      expect(await counterPage.getCount(), 3);
    });

    test('resets to zero', () async {
      await counterPage.increment();
      await counterPage.increment();
      await counterPage.reset();
      expect(await counterPage.getCount(), 0);
    });
  });

  group('greeting', () {
    test('greets the user by name', () async {
      await counterPage.greetUser('Flutter');
      expect(await counterPage.getGreeting(), 'Hello, Flutter!');
    });

    test('updates greeting when name changes', () async {
      await counterPage.greetUser('Alice');
      expect(await counterPage.getGreeting(), 'Hello, Alice!');

      await counterPage.greetUser('Bob');
      expect(await counterPage.getGreeting(), 'Hello, Bob!');
    });
  });

  group('screenshots', () {
    test('captures state after interaction', () async {
      await counterPage.increment();
      await counterPage.increment();
      await counterPage.greetUser('Screenshot');

      await client.screenshotToFile('/tmp/flutter_test_server_screenshot.png');
      // Visual verification — file should show counter=2 and "Hello, Screenshot!"
    });
  });
}
