# flutter_test_server

A lightweight, embeddable HTTP server for Flutter apps that exposes a REST API for on-device test automation — inspired by [Unium](https://github.com/gwaredd/unium) for Unity.

**Any language with HTTP support can drive tests. `curl` is your test client.**

## Quick Start

1. Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_test_server:
    path: ../flutter_test_server  # or publish to pub.dev
```

2. Wrap your app:

```dart
import 'package:flutter_test_server/flutter_test_server.dart';

void main() {
  runApp(
    FlutterTestServer(
      child: MyApp(),
    ),
  );
}
```

3. Run your app and hit the API:

```bash
# For Android emulator, forward the port first:
adb forward tcp:8342 tcp:8342

# App info
curl http://localhost:8342/about

# Full widget tree
curl http://localhost:8342/tree

# Find all Text widgets
curl http://localhost:8342/tree?type=Text

# Find widget by key
curl http://localhost:8342/tree?key=counter

# Find widget by semantics label
curl http://localhost:8342/tree?semantics=Submit

# Screenshot
curl http://localhost:8342/screenshot > screenshot.png
open screenshot.png

# Evaluate Dart expression (debug/profile only)
curl -X POST http://localhost:8342/eval \
  -H 'Content-Type: application/json' \
  -d '{"expression": "1 + 1"}'
```

## API Reference

| Endpoint | Method | Description |
|---|---|---|
| `/about` | GET | App info: platform, screen size, build mode, server version |
| `/tree` | GET | Full widget tree as JSON |
| `/tree?type=Text` | GET | Filter tree by widget type |
| `/tree?key=myKey` | GET | Find widget by Key |
| `/tree?semantics=Submit` | GET | Find widget by semantics label |
| `/screenshot` | GET | Capture screen as PNG |
| `/screenshot?pixelRatio=2` | GET | Screenshot at specific pixel ratio |
| `/eval` | POST | Evaluate a Dart expression (debug/profile only) |

## Configuration

```dart
FlutterTestServer(
  port: 8342,           // default: 8342
  address: '0.0.0.0',   // default: binds all interfaces
  child: MyApp(),
)
```

## How It Works

- **Server**: Uses `shelf` + `shelf_router` for HTTP handling
- **Widget tree**: Walks `WidgetsBinding.instance.rootElement` via `visitChildren()`
- **Screenshots**: Uses `RenderRepaintBoundary.toImage()` to capture PNG
- **Eval**: Connects to Dart VM Service via `dart:developer` (debug/profile only)
- **Thread safety**: Route handlers dispatch to the main isolate via `addPostFrameCallback`
