import 'dart:async';
import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:shelf/shelf.dart';

import '../tree/tree_node.dart';
import '../tree/tree_walker.dart';

/// Handler for POST /tap
/// Body: {"key": "myKey"} or {"semantics": "Submit"} or {"x": 100, "y": 200}
Future<Response> handleTap(Request request) async {
  final body = await request.readAsString();
  final json = jsonDecode(body) as Map<String, dynamic>;

  double? x = (json['x'] as num?)?.toDouble();
  double? y = (json['y'] as num?)?.toDouble();

  // If coordinates not provided, find widget by key or semantics
  if (x == null || y == null) {
    final target = findTargetWidget(json);
    if (target == null) {
      return Response.notFound(
        jsonEncode({'error': 'Widget not found', 'query': json}),
        headers: {'Content-Type': 'application/json'},
      );
    }
    if (target.x == null || target.y == null ||
        target.width == null || target.height == null) {
      return Response.internalServerError(
        body: jsonEncode({
          'error': 'Widget found but has no position/size',
          'widget': target.toJson(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
    // Tap center of widget
    x = target.x! + target.width! / 2;
    y = target.y! + target.height! / 2;
  }

  dispatchTap(Offset(x, y));

  return Response.ok(
    jsonEncode({'status': 'ok', 'x': x, 'y': y}),
    headers: {'Content-Type': 'application/json'},
  );
}

/// Find a widget by key, semantics label, or type.
TreeNode? findTargetWidget(Map<String, dynamic> json) {
  final binding = WidgetsBinding.instance;
  final rootElement = binding.rootElement;
  if (rootElement == null) return null;

  final keyFilter = json['key'] as String?;
  final semanticsFilter = json['semantics'] as String?;
  final typeFilter = json['type'] as String?;

  if (keyFilter == null && semanticsFilter == null && typeFilter == null) {
    return null;
  }

  final results = TreeWalker.findAll(rootElement, (TreeNode node) {
    if (keyFilter != null && (node.key == null || !node.key!.contains(keyFilter))) {
      return false;
    }
    if (semanticsFilter != null && node.semanticsLabel != semanticsFilter) {
      return false;
    }
    if (typeFilter != null && node.type != typeFilter) {
      return false;
    }
    return true;
  });

  return results.isNotEmpty ? results.first : null;
}

int _nextPointer = 100;

/// Dispatch a tap (pointer down + up) at the given position.
/// Each tap uses a unique pointer ID to avoid being ignored by the gesture system.
void dispatchTap(Offset position) {
  final binding = GestureBinding.instance;
  final now = Duration(milliseconds: DateTime.now().millisecondsSinceEpoch);
  final pointer = _nextPointer++;

  binding.handlePointerEvent(PointerDownEvent(
    pointer: pointer,
    position: position,
    timeStamp: now,
  ));
  binding.handlePointerEvent(PointerUpEvent(
    pointer: pointer,
    position: position,
    timeStamp: now + const Duration(milliseconds: 50),
  ));
}
