import 'dart:async';
import 'package:lumide_api/lumide_api.dart';

import 'package:lumide_wakatime/src/cli_locator.dart';
import 'package:lumide_wakatime/src/dependencies_manager.dart';
import 'package:lumide_wakatime/src/event_observer.dart';
import 'package:lumide_wakatime/src/heartbeat_manager.dart';
import 'package:lumide_wakatime/src/status_bar_manager.dart';

class WakaTimePlugin extends LumidePlugin {
  CliLocator? _cliLocator;
  DependenciesManager? _dependenciesManager;
  HeartbeatManager? _heartbeatManager;
  EventObserver? _eventObserver;
  StatusBarManager? _statusBarManager;

  @override
  Future<void> onActivate(LumideContext context) async {
    log('WakaTimePlugin activating...');

    final cliLocator = CliLocator(context.fs.exists);
    _cliLocator = cliLocator;
    _dependenciesManager = DependenciesManager(cliLocator, this);
    if (!await _dependenciesManager!.isCliInstalled()) {
      await _dependenciesManager!.installCli();
    }

    _statusBarManager = StatusBarManager(context, this, cliLocator);
    await _statusBarManager!.initialize();

    _heartbeatManager = HeartbeatManager(
      context,
      this,
      _statusBarManager!,
      cliLocator,
    );
    _eventObserver = EventObserver(context, _heartbeatManager!);

    await _registerCommands(context);

    _eventObserver!.startObserving();
    log('WakaTimePlugin activated successfully.');
  }

  Future<void> _registerCommands(LumideContext context) async {
    await context.commands.registerCommand(
      id: 'wakatime.apiKey',
      title: 'WakaTime: API Key',
      callback: ([args]) async {
        final key = await context.window.showInputBox(
          prompt: 'WakaTime API Key',
          password: true,
        );

        if (key case final validKey? when validKey.isNotEmpty) {
          final isValid = RegExp(
            r'^(waka_)?[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$',
            caseSensitive: false,
          ).hasMatch(validKey);

          if (!isValid) {
            await context.window.showMessage(
              'Invalid API key. Check https://wakatime.com/api-key for your key.',
              type: MessageType.error,
            );
            return;
          }

          log('Saving API Key...');
          final cliPath = await _cliLocator?.cliPath() ?? cliCommand;
          final result = await context.shell.run(cliPath, [
            '--config-write',
            'api_key=$validKey',
          ]);

          if (result.exitCode == 0) {
            await context.window
                .showMessage('WakaTime API Key saved successfully.');
            unawaited(_statusBarManager?.fetchTodayActivity());
          } else {
            await context.window.showMessage(
              'Failed to save WakaTime API Key: ${result.stderr}',
              type: MessageType.error,
            );
          }
        }
      },
    );
  }

  @override
  Future<void> onDeactivate() async {
    _eventObserver?.dispose();
    await _heartbeatManager?.dispose();
    _statusBarManager?.dispose();
    log('WakaTimePlugin deactivated.');
  }
}
