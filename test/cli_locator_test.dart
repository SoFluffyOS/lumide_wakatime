import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:lumide_api/lumide_api.dart';
import 'package:lumide_wakatime/src/cli_locator.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

const _windowsEnv = {
  'USERPROFILE': r'C:\Users\Simon',
  'HOME': '/c/Users/Simon',
};
const _macosEnv = {'HOME': '/Users/simon'};
const _linuxEnv = {'HOME': '/home/simon'};

FileExists _existing(Set<String> files) => (path) async => files.contains(path);

void main() {
  group('cliCandidates', () {
    test('Windows x64 prefers the official windows-amd64 exe', () {
      expect(
        cliCandidates(
          operatingSystem: 'windows',
          abi: Abi.windowsX64,
          environment: _windowsEnv,
        ),
        [
          r'C:\Users\Simon\.wakatime\wakatime-cli-windows-amd64.exe',
          r'C:\Users\Simon\.wakatime\wakatime-cli.exe',
          r'C:\Users\Simon\.wakatime\wakatime-cli-windows-386.exe',
        ],
      );
    });

    test('Windows ARM64 falls back to the emulated amd64 build', () {
      expect(
        cliCandidates(
          operatingSystem: 'windows',
          abi: Abi.windowsArm64,
          environment: _windowsEnv,
        ),
        [
          r'C:\Users\Simon\.wakatime\wakatime-cli-windows-arm64.exe',
          r'C:\Users\Simon\.wakatime\wakatime-cli.exe',
          r'C:\Users\Simon\.wakatime\wakatime-cli-windows-amd64.exe',
        ],
      );
    });

    test('Windows uses HOMEDRIVE and HOMEPATH without USERPROFILE', () {
      expect(
        cliCandidates(
          operatingSystem: 'windows',
          abi: Abi.windowsX64,
          environment: {'HOMEDRIVE': 'D:', 'HOMEPATH': r'\Users\Simon'},
        ).first,
        r'D:\Users\Simon\.wakatime\wakatime-cli-windows-amd64.exe',
      );
    });

    test('macOS uses darwin and falls back to Rosetta on Apple silicon', () {
      expect(
        cliCandidates(
          operatingSystem: 'macos',
          abi: Abi.macosArm64,
          environment: _macosEnv,
        ),
        [
          '/Users/simon/.wakatime/wakatime-cli-darwin-arm64',
          '/Users/simon/.wakatime/wakatime-cli',
          '/Users/simon/.wakatime/wakatime-cli-darwin-amd64',
        ],
      );
      expect(
        cliCandidates(
          operatingSystem: 'macos',
          abi: Abi.macosX64,
          environment: _macosEnv,
        ),
        [
          '/Users/simon/.wakatime/wakatime-cli-darwin-amd64',
          '/Users/simon/.wakatime/wakatime-cli',
        ],
      );
    });

    test('Linux x64 and ARM64', () {
      expect(
        cliCandidates(
          operatingSystem: 'linux',
          abi: Abi.linuxX64,
          environment: _linuxEnv,
        ),
        [
          '/home/simon/.wakatime/wakatime-cli-linux-amd64',
          '/home/simon/.wakatime/wakatime-cli',
        ],
      );
      expect(
        cliCandidates(
          operatingSystem: 'linux',
          abi: Abi.linuxArm64,
          environment: _linuxEnv,
        ).first,
        '/home/simon/.wakatime/wakatime-cli-linux-arm64',
      );
    });

    test('no home directory yields no candidates', () {
      expect(
        cliCandidates(
          operatingSystem: 'linux',
          abi: Abi.linuxX64,
          environment: const {},
        ),
        isEmpty,
      );
    });
  });

  group('findCli', () {
    test('finds the official Windows download (issue #1)', () async {
      const installed =
          r'C:\Users\Simon\.wakatime\wakatime-cli-windows-amd64.exe';
      expect(
        await findCli(
          operatingSystem: 'windows',
          abi: Abi.windowsX64,
          environment: _windowsEnv,
          exists: _existing({installed}),
        ),
        installed,
      );
    });

    test('finds the unsuffixed symlink on macOS', () async {
      const installed = '/Users/simon/.wakatime/wakatime-cli';
      expect(
        await findCli(
          operatingSystem: 'macos',
          abi: Abi.macosArm64,
          environment: _macosEnv,
          exists: _existing({installed}),
        ),
        installed,
      );
    });

    test('falls back to the PATH when nothing is installed', () async {
      expect(
        await findCli(
          operatingSystem: 'linux',
          abi: Abi.linuxX64,
          environment: _linuxEnv,
          exists: _existing(const {}),
        ),
        cliCommand,
      );
    });

    test('treats a failing existence check as missing', () async {
      expect(
        await findCli(
          operatingSystem: 'windows',
          abi: Abi.windowsX64,
          environment: _windowsEnv,
          exists: (_) async => throw StateError('denied'),
        ),
        cliCommand,
      );
    });
  });

  test('plugin.yaml allows every command the plugin can run', () {
    final manifest = LumideManifest.fromYaml(
      File('plugin.yaml').readAsStringSync(),
    );
    final allowed = {
      for (final permission in manifest.permissions)
        if (permission case ShellPermission(:final command)) command,
    };
    const platforms = [
      ('windows', Abi.windowsX64, _windowsEnv),
      ('windows', Abi.windowsArm64, _windowsEnv),
      ('windows', Abi.windowsIA32, _windowsEnv),
      ('macos', Abi.macosArm64, _macosEnv),
      ('macos', Abi.macosX64, _macosEnv),
      ('linux', Abi.linuxX64, _linuxEnv),
      ('linux', Abi.linuxArm64, _linuxEnv),
      ('linux', Abi.linuxIA32, _linuxEnv),
      ('linux', Abi.linuxArm, _linuxEnv),
    ];
    for (final (operatingSystem, abi, environment) in platforms) {
      final context = path.Context(
        style: switch (operatingSystem) {
          'windows' => path.Style.windows,
          _ => path.Style.posix,
        },
      );
      final commands = [
        ...cliCandidates(
          operatingSystem: operatingSystem,
          abi: abi,
          environment: environment,
        ),
        cliCommand,
      ];
      for (final command in commands) {
        expect(
          allowed,
          contains(context.basenameWithoutExtension(command)),
          reason: '$command on $operatingSystem $abi',
        );
      }
    }
  });
}
