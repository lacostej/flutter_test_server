import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:shelf/shelf.dart';

/// Handler for the /screenshot endpoint.
/// Must be called on the main isolate.
Future<Response> handleScreenshot(Request request) async {
  final binding = WidgetsBinding.instance;
  final renderObject = binding.rootElement?.renderObject;

  if (renderObject == null) {
    return Response.internalServerError(
      body: 'No render object — app not yet rendered',
    );
  }

  // Find the nearest RenderRepaintBoundary
  RenderRepaintBoundary? boundary;
  void findBoundary(RenderObject obj) {
    if (obj is RenderRepaintBoundary) {
      boundary = obj;
      return;
    }
    obj.visitChildren(findBoundary);
  }
  findBoundary(renderObject);

  if (boundary == null) {
    return Response.internalServerError(
      body: 'No RenderRepaintBoundary found',
    );
  }

  final pixelRatioParam = request.url.queryParameters['pixelRatio'];
  final pixelRatio = pixelRatioParam != null
      ? double.tryParse(pixelRatioParam) ?? 1.0
      : 1.0;

  try {
    final image = await boundary!.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    if (byteData == null) {
      return Response.internalServerError(body: 'Failed to encode PNG');
    }

    return Response.ok(
      byteData.buffer.asUint8List(),
      headers: {'Content-Type': 'image/png'},
    );
  } catch (e) {
    return Response.internalServerError(body: 'Screenshot failed: $e');
  }
}
