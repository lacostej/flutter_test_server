import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shelf/shelf.dart';

/// Handler for the /about endpoint.
Response handleAbout(Request request) {
  final window = WidgetsBinding.instance.platformDispatcher.views.first;
  final size = window.physicalSize / window.devicePixelRatio;

  final info = {
    'server': 'flutter_test_server',
    'serverVersion': '0.1.0',
    'platform': Platform.operatingSystem,
    'platformVersion': Platform.operatingSystemVersion,
    'dartVersion': Platform.version,
    'screenWidth': size.width,
    'screenHeight': size.height,
    'devicePixelRatio': window.devicePixelRatio,
    'buildMode': kReleaseMode
        ? 'release'
        : kProfileMode
            ? 'profile'
            : 'debug',
  };

  return Response.ok(
    jsonEncode(info),
    headers: {'Content-Type': 'application/json'},
  );
}
