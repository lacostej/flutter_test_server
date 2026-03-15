import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

/// Connects to the Dart VM Service to evaluate expressions.
class EvalService {
  VmService? _vmService;
  String? _mainIsolateId;
  String? _rootLibraryId;

  /// Whether eval is available (debug/profile builds only).
  bool get isAvailable => !kReleaseMode;

  /// Connect to the VM Service. Must be called before [evaluate].
  Future<void> connect() async {
    if (!isAvailable) return;

    final info = await developer.Service.getInfo();
    final uri = info.serverUri;
    if (uri == null) {
      throw StateError('VM Service URI not available');
    }

    // Convert to ws:// URI
    final wsUri = uri.replace(scheme: 'ws').resolve('ws');
    _vmService = await vmServiceConnectUri(wsUri.toString());

    // Find the main isolate
    final vm = await _vmService!.getVM();
    for (final isolateRef in vm.isolates ?? <IsolateRef>[]) {
      if (isolateRef.name == 'main') {
        _mainIsolateId = isolateRef.id;
        break;
      }
    }
    // Fallback: use the first isolate
    _mainIsolateId ??= vm.isolates?.firstOrNull?.id;

    if (_mainIsolateId == null) {
      throw StateError('No isolate found in VM');
    }

    // Get the root library ID for evaluating top-level expressions
    final isolate = await _vmService!.getIsolate(_mainIsolateId!);
    _rootLibraryId = isolate.rootLib?.id;
  }

  /// Evaluate a Dart expression and return the result as a string.
  Future<Map<String, dynamic>> evaluate(String expression) async {
    if (!isAvailable) {
      return {
        'error': 'Eval is not available in release builds',
        'status': 501,
      };
    }

    if (_vmService == null) {
      await connect();
    }

    if (_rootLibraryId == null) {
      return {
        'error': 'Could not find root library for evaluation',
        'status': 500,
      };
    }

    try {
      final response = await _vmService!.evaluate(
        _mainIsolateId!,
        _rootLibraryId!,
        expression,
      );

      if (response is InstanceRef) {
        return {
          'result': response.valueAsString ?? response.classRef?.name ?? response.toString(),
          'type': response.classRef?.name,
          'kind': response.kind,
        };
      } else if (response is ErrorRef) {
        return {
          'error': response.message,
          'status': 400,
        };
      } else {
        return {
          'result': response.toString(),
        };
      }
    } catch (e) {
      return {
        'error': e.toString(),
        'status': 500,
      };
    }
  }

  /// Disconnect from the VM Service.
  Future<void> dispose() async {
    await _vmService?.dispose();
    _vmService = null;
    _mainIsolateId = null;
  }
}
