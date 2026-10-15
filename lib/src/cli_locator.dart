import 'dart:ffi' show Abi;
import 'dart:io' show Platform;

import 'package:path/path.dart' as path;

/// Name of `wakatime-cli` when looked up on the `PATH`.
const cliCommand = 'wakatime-cli';

/// Checks whether a file exists at a path.
typedef FileExists = Future<bool> Function(String path);

/// Maps a Dart [operatingSystem] (`Platform.operatingSystem`) to the OS name
/// used by `wakatime-cli` release assets.
String wakatimeOs(String operatingSystem) => switch (operatingSystem) {
      'macos' => 'darwin',
      final other => other,
    };

/// `wakatime-cli` architecture names for [abi], preferred first.
///
/// ARM64 hosts fall back to `amd64` (Rosetta on macOS, emulation on Windows)
/// and 64-bit Windows falls back to `386`.
List<String> wakatimeArchs(Abi abi) => switch (abi) {
      Abi.macosArm64 || Abi.windowsArm64 => const ['arm64', 'amd64'],
      Abi.linuxArm64 || Abi.androidArm64 => const ['arm64'],
      Abi.windowsX64 => const ['amd64', '386'],
      Abi.macosX64 || Abi.linuxX64 || Abi.androidX64 => const ['amd64'],
      Abi.windowsIA32 || Abi.linuxIA32 || Abi.androidIA32 => const ['386'],
      Abi.linuxArm || Abi.androidArm => const ['arm'],
      _ => const ['amd64', 'arm64'],
    };

/// The user's home directory, as `wakatime-cli` and the official WakaTime
/// editor plugins see it.
String homeDirectory({
  required String operatingSystem,
  required Map<String, String> environment,
}) {
  if (operatingSystem != 'windows') return environment['HOME'] ?? '';
  if (environment['USERPROFILE'] case final profile? when profile.isNotEmpty) {
    return profile;
  }
  final homeDrive = environment['HOMEDRIVE'] ?? '';
  final homePath = environment['HOMEPATH'] ?? '';
  if (homeDrive.isNotEmpty && homePath.isNotEmpty) return '$homeDrive$homePath';
  return environment['HOME'] ?? '';
}

/// Paths where `wakatime-cli` may be installed, most preferred first.
///
/// Official WakaTime editor plugins download
/// `~/.wakatime/wakatime-cli-<os>-<arch>[.exe]` and, outside Windows, link
/// `~/.wakatime/wakatime-cli` to it.
List<String> cliCandidates({
  required String operatingSystem,
  required Abi abi,
  required Map<String, String> environment,
}) {
  final home = homeDirectory(
    operatingSystem: operatingSystem,
    environment: environment,
  );
  if (home.isEmpty) return const [];

  final isWindows = operatingSystem == 'windows';
  final context = path.Context(
    style: switch (isWindows) {
      true => path.Style.windows,
      false => path.Style.posix,
    },
  );
  final extension = switch (isWindows) {
    true => '.exe',
    false => '',
  };
  final resourcesDirectory = context.join(home, '.wakatime');
  String inResources(String name) =>
      context.join(resourcesDirectory, '$name$extension');

  final os = wakatimeOs(operatingSystem);
  final archs = wakatimeArchs(abi);
  return [
    inResources('$cliCommand-$os-${archs.first}'),
    inResources(cliCommand),
    for (final arch in archs.skip(1)) inResources('$cliCommand-$os-$arch'),
  ];
}

/// Finds the `wakatime-cli` executable to run.
///
/// Returns the first existing [cliCandidates] path, or [cliCommand] so the
/// IDE resolves it from the `PATH`.
Future<String> findCli({
  required String operatingSystem,
  required Abi abi,
  required Map<String, String> environment,
  required FileExists exists,
}) async {
  final candidates = cliCandidates(
    operatingSystem: operatingSystem,
    abi: abi,
    environment: environment,
  );
  for (final candidate in candidates) {
    if (await _existsSafely(exists, candidate)) return candidate;
  }
  return cliCommand;
}

Future<bool> _existsSafely(FileExists exists, String path) async {
  try {
    return await exists(path);
  } catch (_) {
    return false;
  }
}

/// Resolves the `wakatime-cli` path for this platform.
class CliLocator {
  CliLocator(
    this._exists, {
    String? operatingSystem,
    Abi? abi,
    Map<String, String>? environment,
  })  : _operatingSystem = operatingSystem ?? Platform.operatingSystem,
        _abi = abi ?? Abi.current(),
        _environment = environment ?? Platform.environment;

  final FileExists _exists;
  final String _operatingSystem;
  final Abi _abi;
  final Map<String, String> _environment;

  /// Path of an installed `wakatime-cli`, or [cliCommand] to use the `PATH`.
  ///
  /// Resolved on every call, so installing or updating the CLI is picked up
  /// without restarting the IDE.
  Future<String> cliPath() => findCli(
        operatingSystem: _operatingSystem,
        abi: _abi,
        environment: _environment,
        exists: _exists,
      );

  /// Whether `wakatime-cli` was found under `~/.wakatime`.
  Future<bool> isInstalled() async => await cliPath() != cliCommand;
}
