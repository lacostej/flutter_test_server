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
  final _textController = TextEditingController();
  String _greeting = '';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Server Demo'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
              const SizedBox(height: 30),
              TextField(
                key: const Key('nameField'),
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Your name',
                  hintText: 'Enter your name',
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                key: const Key('greetButton'),
                onPressed: () {
                  setState(() {
                    _greeting = 'Hello, ${_textController.text}!';
                  });
                },
                child: const Text('Greet'),
              ),
              if (_greeting.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  _greeting,
                  key: const Key('greetingText'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ],
          ),
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
