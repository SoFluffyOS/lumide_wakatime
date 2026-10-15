## 1.0.1

- Fixed `wakatime-cli` not being found on Windows ("Executable not found or not executable"). The plugin now runs the official `~/.wakatime/wakatime-cli-<os>-<arch>[.exe]` binary, e.g. `wakatime-cli-windows-amd64.exe`.
- Added lookup of `~/.wakatime/wakatime-cli` and `wakatime-cli` on the `PATH` as fallbacks.
- Added ARM64 support on Windows, macOS, and Linux, with a fallback to the x64 build on Windows ARM64 and Apple silicon.

## 1.0.0+1

- Initial release of the Lumide WakaTime plugin.
- Added automated time tracking support via `wakatime-cli`.
- Integrated WakaTime coding statistics (hrs/mins) directly into the Lumide Status Bar.
- Added commands to configure the strict WakaTime API key securely.
