import 'package:lumide_api/lumide_api.dart';

import 'package:lumide_wakatime/src/cli_locator.dart';

class DependenciesManager {
  DependenciesManager(this._cliLocator, this._plugin);

  final CliLocator _cliLocator;
  final LumidePlugin _plugin;

  Future<bool> isCliInstalled() => _cliLocator.isInstalled();

  Future<void> installCli() async {
    _plugin.log(
      'wakatime-cli was not found in ~/.wakatime; falling back to '
      '`$cliCommand` on the PATH. Install it from '
      'https://github.com/wakatime/wakatime-cli/releases if tracking fails.',
    );
  }
}
