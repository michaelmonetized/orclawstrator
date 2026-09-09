# Orclawstrator

**One-liner:** Native macOS command center for orchestrating AI coding agents across a project portfolio.

## Status: **RESUSCITATED / ship-worthy** (see AUTOPSY.md)

- **Last Updated:** 2026-09-08 (docs parity)
- **Tech Stack:** Swift 5.9+, AppKit, SQLite, SwiftTerm
- **Completion:** ~85%+

## What's Working
- Dashboard with project table (git status, branches, stacks, build status)
- Project detail view with split pane (markdown/nvim via SwiftTerm + agent activity)
- Git / GitHub (`gh`) / Graphite / Vercel CLI integrations
- OpenClaw WebSocket + REST session management
- SQLite persistence (`~/.orclawstrator/cache.db`)
- Project scanning + language detection
- Global Inbox (`InboxView`) with read/unread
- PR Stack Viewer (`PRStackPopover`)
- Branch switcher dropdown
- Cmd+K quick switcher + keyboard shortcuts
- Menu bar status item + error banner
- Catppuccin theming

## Remaining
- Push notifications / Dock badge
- File-watcher incremental updates
- Deeper stack-comment API counts / build-log-on-error
- Broader project search/filter + drag-reorder

## Quick Start
```bash
swift build
.build/debug/Orclawstrator
```
