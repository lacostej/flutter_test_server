import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shelf/shelf.dart';

import '../tree/tree_node.dart';
import '../tree/tree_walker.dart';

/// Handler for the /tree endpoint.
/// Must be called on the main isolate (dispatched via server).
Future<Response> handleTree(Request request) async {
  final binding = WidgetsBinding.instance;
  final rootElement = binding.rootElement;

  if (rootElement == null) {
    return Response.ok(
      jsonEncode({'error': 'No root element — app not yet rendered'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  final typeFilter = request.url.queryParameters['type'];
  final keyFilter = request.url.queryParameters['key'];
  final semanticsFilter = request.url.queryParameters['semantics'];

  final hasFilter =
      typeFilter != null || keyFilter != null || semanticsFilter != null;

  if (hasFilter) {
    final results = TreeWalker.findAll(rootElement, (TreeNode node) {
      if (typeFilter != null && node.type != typeFilter) return false;
      if (keyFilter != null && node.key == null) return false;
      if (keyFilter != null && !node.key!.contains(keyFilter)) return false;
      if (semanticsFilter != null && node.semanticsLabel != semanticsFilter) {
        return false;
      }
      return true;
    });

    return Response.ok(
      jsonEncode({
        'count': results.length,
        'results': results.map((n) => n.toJson()).toList(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  final tree = TreeWalker.buildTree(rootElement);

  return Response.ok(
    jsonEncode(tree?.toJson()),
    headers: {'Content-Type': 'application/json'},
  );
}
