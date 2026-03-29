# Vibe Helper

A native macOS dashboard app for visualizing your [Mistral Vibe CLI](https://github.com/mistralai/mistral-vibe) usage — costs, tokens, sessions, and tool call analytics — all in a clean, minimal interface.

![macOS](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![SwiftUI](https://img.shields.io/badge/SwiftUI-Charts-green)

## Features

- **Cost Tracking** — Cumulative spend over time, average cost per session, cost by project
- **Token Analytics** — Input vs output token breakdown, tokens/sec performance trends
- **Activity Heatmap** — GitHub-style calendar heatmap showing session frequency and duration
- **Tool Usage** — Donut chart of tool call outcomes (succeeded, rejected, failed)
- **Per-Project Filtering** — Filter all stats by project/working directory
- **Time Range Controls** — Quick presets (Today, 7 Days, 30 Days, All Time) + custom date picker
- **Session Detail View** — Click any session to drill into full stats, token breakdown, tool calls, and timing
- **Live Updates** — File system watcher auto-refreshes when new sessions complete
- **Manual Refresh** — One-click refresh button

## Requirements

- macOS 14 (Sonoma) or later
- Mistral Vibe CLI with session logging enabled (default)

## Installation

### Download (recommended)

1. Go to the [Releases](../../releases) page
2. Download the latest `VibeHelper-x.x.x-macOS.dmg`
3. Open the DMG and drag **Vibe Helper** to your Applications folder
4. Launch from Applications

> **Note:** Since the app is not notarized with Apple, macOS will show a warning on first launch.
> Right-click the app → **Open** → click **Open** in the dialog. You only need to do this once.

### Build from source

Requires Xcode 15+ (or just the Command Line Tools with Swift 5.9+).

```bash
git clone https://github.com/YOUR_USERNAME/vibe-helper.git
cd vibe-helper
swift build -c release
open .build/release/VibeHelper
```

### Build the DMG yourself

```bash
bash scripts/build-dmg.sh 1.0.0
```

This creates `.build/VibeHelper-1.0.0-macOS.dmg` — a drag-to-Applications installer.

## How It Works

Vibe Helper reads session data from the Mistral Vibe CLI's default log directory:

```
~/.vibe/logs/session/
├── session_20260314_142929_13186fdf/
│   ├── meta.json          ← parsed for stats
│   └── messages.jsonl
├── session_20260315_234137_106aab31/
│   ├── meta.json
│   └── messages.jsonl
└── ...
```

Each session's `meta.json` contains stats like token counts, cost, tool call outcomes, timing, git branch, and working directory. Vibe Helper parses all of these and visualizes them.

### Enabling Session Logging

Session logging is enabled by default in Vibe CLI. If you've disabled it, add this to your `~/.vibe/config.toml`:

```toml
[session_logging]
save_dir = "~/.vibe/logs/session"  # or your preferred path
session_prefix = "session"
enabled = true
```

### Custom Session Directory

If your sessions are stored somewhere other than `~/.vibe/logs/session/`, update the path in `VibeHelper/Services/SessionLoader.swift`:

```swift
static let sessionDirectory = URL(fileURLWithPath: "/your/custom/path")
```

## Project Structure

```
VibeHelper/
├── VibeHelperApp.swift              # App entry point
├── Models/
│   ├── Session.swift                # Codable model for meta.json
│   └── TimeRange.swift              # Time range filtering enum
├── Services/
│   ├── SessionLoader.swift          # Parses all session meta.json files
│   ├── FileWatcher.swift            # FSEvents watcher for live updates
│   └── SessionStore.swift           # Central data store (ObservableObject)
├── Views/
│   ├── DashboardView.swift          # Main single-window dashboard
│   ├── Cards/
│   │   ├── CostCard.swift           # Cumulative cost area chart
│   │   ├── TokenCard.swift          # Input/output token bar chart
│   │   ├── ActivityCard.swift       # Calendar heatmap
│   │   └── ToolUsageCard.swift      # Tool call donut chart
│   ├── Controls/
│   │   ├── TimeRangePickerView.swift
│   │   └── ProjectFilterView.swift
│   ├── SessionListView.swift        # Scrollable session list
│   └── SessionDetailView.swift      # Full session detail sheet
└── Utilities/
    ├── ColorTheme.swift
    └── DateFormatting.swift
```

## License

MIT
