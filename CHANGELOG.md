# Changelog

All notable changes to Vibe Helper are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [v2.0.0] - 2026-05-01

### New Features

- **Menu Bar App** — Quick access to Vibe stats from the macOS menu bar with a beautiful popover interface
  - Real-time statistics: Cost, Sessions, Tokens, and Tokens/Second
  - Time range toggle: Today, 7 Days, 30 Days
  - Active/Idle process indicator with animated status
  - Auto-refresh with configurable interval (Manual, 1 min, 2 min, 5 min, 10 min)
  - One-click access to open the full Dashboard

### Changed

- Default time range filter changed from "All Time" to "7 Days" in the main dashboard
- Sessions older than 30 days are now filtered out by default for performance
- Navigation overhaul: Dashboard → Session Detail → Replay now uses breadcrumb navigation
- Session Replay view now includes a search function to filter messages

### Performance Improvements

- Date formatters are now cached as static properties (reduces allocations)
- SessionStore uses cached filtered arrays to avoid recomputation
- MessageLoader refactored to use streaming `URL.lines` API for better memory efficiency

### Code Architecture

- Centralized state management via `StoresContainer.shared` singleton
- Proper `@MainActor` usage throughout the app for thread safety
- Callback-based navigation replaces sheet/modal patterns
- Added resource cleanup methods to all watchable stores
- Refactored to use `@EnvironmentObject` for shared state injection

### Bug Fixes

- Removed debug print statements from production code
- Silent error handling for unreadable session files
- Fixed TimeRange enum handling for custom date ranges

### Removed

- "All Time" time range option (replaced with 30-day max)
- Old stub VibeHelperMenu directory

---

## [v1.3.0] - 2026-04-03

### New Features

- Model & Provider Settings page with safe config editing
- Automatic timestamped backups before every config save
- Atomic writes with post-write validation and auto-restore on failure
- Browse and restore previous config backups from within the app

---

## [v1.2.0] - 2026-03-15

### New Features

- Session Replay: View full conversations including assistant messages and tool calls with expandable arguments
- Model Usage card showing per-model token consumption

---

## [v1.1.0] - 2026-03-12

### New Features

- Skill Management: Browse, search, create, edit, and delete skills
- Automatic backups before skill deletion
- User invocable toggle for skills

---

## [v1.0.0] - 2026-03-10

### Initial Release

- Dashboard with Cost Tracking, Token Analytics, Activity Heatmap, Tool Usage charts
- Per-Project Filtering
- Time Range Controls with custom date picker
- Session Detail View with full stats and token breakdown
- Live Updates via file system watcher
