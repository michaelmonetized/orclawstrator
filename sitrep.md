# Orclawstrator

**One-liner:** Native macOS command center for orchestrating AI coding agents across project portfolio.

## Status: **Active Development**

- **Last Updated:** 2026-02-09
- **Tech Stack:** Swift 5.9+, AppKit, SQLite
- **Completion:** ~85%

## What's Working

- Dashboard with project table (git status, branches, stacks, build status)
- Project detail view with split pane (markdown editor + agent activity)
- Git integration (branch count, staged/untracked files, commit dates)
- GitHub integration via `gh` CLI
- Graphite integration for stacked PRs
- Vercel build status integration
- OpenClaw WebSocket connection for real-time agent output
- OpenClaw REST API for session management
- SQLite persistence (~/.orclawstrator/cache.db)
- Project scanning with language detection
- Catppuccin color theming
- Chromeless semi-transparent window

## What's In Progress

- Global Inbox for cross-session messages
- PR Stack Viewer (click stack count to see details)
- Cmd+K quick switcher
- Branch switcher dropdown
- Keyboard shortcuts

## What's Planned

- Menu bar icon with quick actions
- System notifications for agent messages
- Error banner UI (replace console logging)

## Quick Start

```bash
swift build
.build/debug/Orclawstrator
```

## Configuration

Gateway settings stored in SQLite `settings` table:
- `gateway_host` (default: localhost)
- `gateway_port` (default: 3377)
