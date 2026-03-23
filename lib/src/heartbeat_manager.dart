import 'dart:async';
import 'package:lumide_api/lumide_api.dart';

import 'package:lumide_wakatime/src/path_utils.dart';
import 'package:lumide_wakatime/src/status_bar_manager.dart';

typedef Heartbeat = ({
  String entity,
  bool isWrite,
  int time,
  int? lineno,
  int? cursorpos,
});

class HeartbeatManager {
  HeartbeatManager(this._context, this._plugin, this._statusBarManager);

  final LumideContext _context;
  final LumidePlugin _plugin;
  final StatusBarManager _statusBarManager;

  final _queue = <Heartbeat>[];
  Timer? _debounceTimer;

  static const _debounceMs = 2000;

  void recordHeartbeat({
    required String entity,
    required bool isWrite,
    required int time,
    int? lineno,
    int? cursorpos,
  }) {
    _queue.add((
      entity: entity,
      isWrite: isWrite,
      time: time,
      lineno: lineno,
      cursorpos: cursorpos,
    ));

    if (isWrite) {
      _sendHeartbeats();
    } else {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(
        const Duration(milliseconds: _debounceMs),
        _sendHeartbeats,
      );
    }
  }

  Future<void> _sendHeartbeats() async {
    if (_queue.isEmpty) return;

    final heartbeat = _queue.removeLast();
    _queue.clear();

    final cliPath = await getCliPath();
    final args = <String>[
      '--entity',
      heartbeat.entity,
      '--time',
      heartbeat.time.toString(),
      '--plugin',
      'Lumide/1.0.0 lumide-wakatime/1.0.0',
      '--category',
      'coding',
    ];

    if (heartbeat.isWrite) args.add('--write');

    if (heartbeat.lineno case final line?) {
      args.addAll(['--lineno', line.toString()]);
    }

    if (heartbeat.cursorpos case final col?) {
      args.addAll(['--cursorpos', col.toString()]);
    }

    try {
      final result = await _context.shell.run(cliPath, args);
      if (result.exitCode == 0) {
        _statusBarManager.scheduleRefresh();
      } else {
        _plugin.log('WakaTime CLI error: ${result.stderr}');
      }
    } catch (e) {
      _plugin.log('Failed to send heartbeat: $e');
    }
  }

  Future<void> dispose() async {
    _debounceTimer?.cancel();
    await _sendHeartbeats();
  }
}
