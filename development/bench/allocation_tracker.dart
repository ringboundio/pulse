import 'dart:async';
import 'dart:developer' as developer;
import 'dart:isolate';

import 'package:vm_service/vm_service.dart' as vm;
import 'package:vm_service/vm_service_io.dart' as vm_io;

class AllocationSnapshot {
  const AllocationSnapshot({
    required this.totalBytes,
    required this.totalInstances,
  });

  final int totalBytes;
  final int totalInstances;
}

class AllocationTracker {
  AllocationTracker._(this._service, this._isolateId);

  final vm.VmService _service;
  final String _isolateId;

  static Future<AllocationTracker?> create() async {
    try {
      final developer.ServiceProtocolInfo info =
          await developer.Service.getInfo();
      final Uri? serverUri = info.serverUri;
      if (serverUri == null) {
        return null;
      }
      final String? isolateId = developer.Service.getIsolateId(Isolate.current);
      if (isolateId == null) {
        return null;
      }
      final Uri wsUri = _toWebSocketUri(serverUri);
      final vm.VmService service = await vm_io.vmServiceConnectUri(
        wsUri.toString(),
      );
      return AllocationTracker._(service, isolateId);
    } catch (_) {
      return null;
    }
  }

  Future<void> reset() async {
    try {
      await _service.getAllocationProfile(_isolateId, reset: true);
    } catch (_) {
      // Best effort; ignore when service is unavailable.
    }
  }

  Future<AllocationSnapshot?> collect() async {
    try {
      final vm.AllocationProfile profile = await _service.getAllocationProfile(
        _isolateId,
        reset: false,
      );
      final List<vm.ClassHeapStats>? members = profile.members;
      if (members == null) {
        return const AllocationSnapshot(totalBytes: 0, totalInstances: 0);
      }
      int bytes = 0;
      int instances = 0;
      for (final vm.ClassHeapStats stats in members) {
        bytes += _readStat(
          stats,
          'accumulatedSize',
          fallback: 'bytesAllocated',
        );
        instances += _readStat(
          stats,
          'accumulatedInstances',
          fallback: 'instances',
        );
      }
      return AllocationSnapshot(totalBytes: bytes, totalInstances: instances);
    } catch (_) {
      return null;
    }
  }

  static Uri _toWebSocketUri(Uri uri) {
    if (uri.scheme == 'ws' || uri.scheme == 'wss') {
      return uri;
    }
    final String scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    String path = uri.path;
    if (!path.endsWith('/')) {
      path = '$path/';
    }
    path = '${path}ws';
    return uri.replace(scheme: scheme, path: path);
  }

  static int _readStat(
    vm.ClassHeapStats stats,
    String primary, {
    String? fallback,
  }) {
    final Map<String, Object?> json = stats.json ?? const <String, Object?>{};
    final Object? value =
        json[primary] ?? (fallback != null ? json[fallback] : null);
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }
}
