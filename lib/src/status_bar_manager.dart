import 'dart:async';
import 'dart:convert';
import 'package:lumide_api/lumide_api.dart';

import 'package:lumide_wakatime/src/path_utils.dart';

class StatusBarManager {
  StatusBarManager(this._context, this._plugin);

  final LumideContext _context;
  final LumidePlugin _plugin;

  static const _statusId = 'wakatime.status';
  static const _configKey = 'wakatime.statusBar';
  static const _statusText = 'WakaTime';
  static const _statusIcon = 'clock';
  Timer? _refreshTimer;
  bool _isVisible = true;

  static const _refreshDelay = Duration(minutes: 1);

  Future<void> initialize() async {
    _isVisible =
        switch (await _context.workspace.getConfiguration(_configKey)) {
      final bool value => value,
      _ => true,
    };

    await _context.statusBar.createItem(
      id: _statusId,
      text: _statusText,
      iconName: _statusIcon,
      tooltip: 'WakaTime Initialized (Click to enter API key)',
      alignment: 'left',
      command: 'wakatime.apiKey',
    );

    if (!_isVisible) {
      await _context.statusBar.hide(_statusId);
    }

    _context.workspace.onDidChangeConfiguration((settings) {
      if (settings[_configKey] case final bool newValue) {
        _updateVisibility(newValue);
      }
    });

    unawaited(fetchTodayActivity());
  }

  void _updateVisibility(bool visible) {
    if (_isVisible == visible) return;
    _isVisible = visible;
    if (visible) {
      _context.statusBar.show(_statusId);
      unawaited(fetchTodayActivity());
    } else {
      _context.statusBar.hide(_statusId);
    }
  }

  Future<void> fetchTodayActivity() async {
    final cliPath = await getCliPath();
    const args = <String>['--today', '--output', 'json'];

    try {
      final result = await _context.shell.run(cliPath, args);
      if (result.exitCode == 0 && result.stdout.isNotEmpty) {
        if (jsonDecode(result.stdout) case {'text': final String text}) {
          await _context.statusBar.updateItem(
            _statusId,
            text: text.trim(),
            tooltip: 'WakaTime: Today’s coding time.',
            command: '',
          );
        }
      }
    } catch (e) {
      _plugin.log('Failed to fetch today activity: $e');
    }
  }

  void scheduleRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(_refreshDelay, fetchTodayActivity);
  }

  void dispose() {
    _refreshTimer?.cancel();
  }
}
