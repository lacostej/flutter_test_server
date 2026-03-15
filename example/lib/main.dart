import 'package:flutter/material.dart';
import 'package:flutter_test_server/flutter_test_server.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const FlutterTestServer(
      child: ExampleApp(),
    ),
  );
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Server Demo',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const CounterPage(),
    );
  }
}

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Server Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'You have pushed the button this many times:',
              key: Key('instructions'),
            ),
            Text(
              '$_counter',
              key: const Key('counter'),
              style: Theme.of(context).textTheme.headlineMedium,
              semanticsLabel: 'Counter value: $_counter',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              key: const Key('incrementButton'),
              onPressed: () => setState(() => _counter++),
              child: const Text('Increment'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              key: const Key('resetButton'),
              onPressed: () => setState(() => _counter = 0),
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _counter++),
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
