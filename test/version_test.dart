import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_server/src/version.dart';

void main() {
  test('serverVersion matches the pubspec versions', () {
    for (final path in ['pubspec.yaml', 'client/pubspec.yaml']) {
      final version = RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(File(path).readAsStringSync())!.group(1);
      expect(version, serverVersion, reason: path);
    }
  });
}
