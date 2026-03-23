# Lumide WakaTime Plugin

Official WakaTime time tracking integration for the [Lumide IDE](https://lumide.dev).

WakaTime allows you to gain deep insights into your programming habits. This plugin automatically tracks your coding activity, file saves, and language usage, reporting them seamlessly to your WakaTime dashboard.

## Features

- **Automatic tracking**: Silently tracks time spent in files, language usage, and project statistics automatically without slowing down the IDE.
- **Status Bar Integration**: View your today's coding time at a glance natively in the Lumide status bar. Updates instantly upon every successful heartbeat.
- **Cross-Platform**: Fully supported on macOS, Windows, and Linux via automatic detection of system paths.
- **Secure Architecture**: Relies on the official, robust `wakatime-cli`. Offline caching and complex project heuristic analytics are handled directly by the CLI.

## Installation

1. Open Plugin Manager > Marketplace.
2. Search for `WakaTime`.
3. Click the `Install` button.
4. Enter your [api key](https://wakatime.com/settings#apikey) by opening the Command Palette (`Cmd+Shift+P` or `Ctrl+Shift+P`), typing `WakaTime: API Key`, and pressing Enter.
5. Use your IDE and your coding activity will be displayed on your [WakaTime dashboard](https://wakatime.com).

## Commands

- `WakaTime: API Key` - Prompts you to update your WakaTime API key, linking the IDE to your secure WakaTime dashboard. Open the Command Palette (`Cmd+Shift+P` or `Ctrl+Shift+P`) and type `WakaTime`.

## Settings

You can customize the plugin via Lumide settings:

- `wakatime.statusBar`: `boolean` - Toggle the visibility of the "Today's Coding Time" status bar tracking ticker. Defaults to `true`.

## Privacy & Security

WakaTime respects your privacy. This plugin leverages `~/.wakatime.cfg` to ensure your API keys and parameters are secured natively. 
