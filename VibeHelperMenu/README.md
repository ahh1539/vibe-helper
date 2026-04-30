# Vibe Helper Menu

An extremely lightweight macOS menu bar app for monitoring your Mistral Vibe CLI usage at a glance.

## Features

- **Today's Stats**: Cost, sessions, and token usage for today
- **This Week**: Aggregated stats for the current week
- **All Time**: Cumulative stats across all sessions
- **Active Indicator**: Shows whether Vibe CLI is currently running
- **Customizable Badge**: Choose to display session count, cost, or no badge
- **Open Dashboard**: Quick access to the full Vibe Helper dashboard app
- **Refresh**: Manual refresh to reload session data

## Requirements

- macOS 14 (Sonoma) or later
- Mistral Vibe CLI with session logging enabled (default)

## Installation

### Build from Source

```bash
cd /path/to/vibe-helper
git clone https://github.com/ahh1539/vibe-helper.git
cd vibe-helper
swift build -c release --target VibeHelperMenu
open .build/release/VibeHelperMenu
```

Or build both apps:
```bash
swift build -c release
```

This creates both `VibeHelper` and `VibeHelperMenu` in `.build/release/`.

## Usage

1. Launch VibeHelperMenu.app
2. A "V" icon appears in your menu bar
3. Click the icon to see your stats
4. Use the "Badge" menu to customize what appears next to "Vibe Helper" in the menu bar

## How It Works

Vibe Helper Menu reads session data from the Mistral Vibe CLI's default log directory:
```
~/.vibe/logs/session/
```

Each session's `meta.json` file is parsed to extract:
- Session ID
- Start time
- Total cost
- Total tokens

These are aggregated by time period (Today, This Week, All Time) and displayed in the menu.

## Project Structure

```
VibeHelperMenu/
├── VibeHelperMenuApp.swift    # App entry point with MenuBarExtra
├── MenuBarStore.swift          # Data store with aggregated stats
├── MenuBarView.swift           # Menu UI with stats display
├── Models/
│   └── MenuSession.swift       # Minimal session model
└── Services/
    ├── MenuSessionLoader.swift # Loads sessions from disk
    └── ProcessMonitor.swift    # Detects running Vibe process
```

## Design Goals

- **Extremely Lightweight**: Under 5MB binary, minimal dependencies
- **Fast Launch**: Lazy loading on first menu open
- **Low Memory**: Only tracks aggregated stats, not individual sessions
- **Simple UI**: Traditional menu with text items, no popover
- **No File Watching**: Manual refresh only to minimize resource usage

## License

MIT
