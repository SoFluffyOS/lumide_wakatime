import 'package:lumide_api/lumide_api.dart';

import 'package:lumide_wakatime/src/heartbeat_manager.dart';
import 'package:lumide_wakatime/src/path_utils.dart';

class EventObserver {
  EventObserver(this._context, this._heartbeatManager);

  final LumideContext _context;
  final HeartbeatManager _heartbeatManager;

  void startObserving() {
    _context.editor.onDidChangeSelections((selections) {
      if (selections.isEmpty) return;

      final firstSelection = selections.first;
      final focus = firstSelection['focus'] as Map<String, dynamic>?;

      if (focus case final focusMap?) {
        final line = focusMap['line'] as int?;
        final column = focusMap['column'] as int?;

        if (line != null && column != null) {
          _recordEvent(isWrite: false, line: line, column: column);
        }
      }
    });

    _context.workspace.onDidChangeTextDocument((event) {
      _recordEvent(isWrite: false);
    });

    _context.workspace.onDidSaveTextDocument((uri) {
      _recordEvent(isWrite: true, uriOverride: uri);
    });
  }

  Future<void> _recordEvent({
    required bool isWrite,
    String? uriOverride,
    int? line,
    int? column,
  }) async {
    final activeUri =
        uriOverride ?? await _context.editor.getActiveDocumentUri();
    if (activeUri == null) return;

    final uri = Uri.tryParse(activeUri);
    if (uri == null) return;

    final filePath = toRealPath(uri);

    _heartbeatManager.recordHeartbeat(
      entity: filePath,
      isWrite: isWrite,
      lineno: line,
      cursorpos: column,
      time: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  void dispose() {}
}
