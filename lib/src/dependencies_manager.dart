import 'package:lumide_api/lumide_api.dart';

import 'package:lumide_wakatime/src/path_utils.dart';

class DependenciesManager {
  DependenciesManager(this._context, this._plugin);

  final LumideContext _context;
  final LumidePlugin _plugin;

  Future<bool> isCliInstalled() async {
    final cliPath = await getCliPath();
    final exists = await _context.fs.exists(cliPath);
    return exists;
  }

  Future<void> installCli() async {
    _plugin.log('Installing wakatime-cli...');
    _plugin.log('wakatime-cli installation process initialized.');
  }
}
