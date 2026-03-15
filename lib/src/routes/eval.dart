import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';

import '../vm_service/eval_service.dart';

/// Handler for the /eval endpoint.
/// POST with JSON body: {"expression": "1 + 1"}
Future<Response> handleEval(Request request, EvalService evalService) async {
  if (kReleaseMode) {
    return Response(
      501,
      body: jsonEncode({
        'error': 'Eval is not available in release builds',
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  final body = await request.readAsString();
  if (body.isEmpty) {
    return Response(
      400,
      body: jsonEncode({'error': 'Request body is required'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Map<String, dynamic> parsed;
  try {
    parsed = jsonDecode(body) as Map<String, dynamic>;
  } catch (e) {
    return Response(
      400,
      body: jsonEncode({'error': 'Invalid JSON: $e'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  final expression = parsed['expression'] as String?;
  if (expression == null || expression.isEmpty) {
    return Response(
      400,
      body: jsonEncode({'error': '"expression" field is required'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  final result = await evalService.evaluate(expression);

  final statusCode = result.remove('status') as int? ?? 200;

  return Response(
    statusCode,
    body: jsonEncode(result),
    headers: {'Content-Type': 'application/json'},
  );
}
