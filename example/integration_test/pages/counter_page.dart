import 'package:flutter_test_server_client/flutter_test_server_client.dart';

/// Page object for the CounterPage in the example app.
class CounterPage {
  final FlutterTestClient client;

  CounterPage(this.client);

  // -- Queries --

  Future<int> getCount() async {
    final text = await client.getTextByKey('counter');
    return int.parse(text ?? '0');
  }

  Future<String?> getGreeting() async {
    return client.getTextByKey('greetingText');
  }

  Future<bool> hasGreeting() async {
    final widget = await client.findByKey('greetingText');
    return widget != null;
  }

  // -- Actions --

  Future<void> increment() async {
    await client.tapByKey('incrementButton');
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> reset() async {
    await client.tapByKey('resetButton');
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> enterName(String name) async {
    await client.enterTextByKey('nameField', name);
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> greet() async {
    await client.tapByKey('greetButton');
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // -- Composite actions --

  Future<void> greetUser(String name) async {
    await enterName(name);
    await greet();
  }

  // -- Assertions helpers --

  Future<void> waitForGreeting(String expected) async {
    await client.waitForText('greetingText', expected);
  }
}
