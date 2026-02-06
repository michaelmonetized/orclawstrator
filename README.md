# Orclawstrator 🦞

**A native macOS command center for orchestrating AI coding agents across your entire project portfolio.**

![Mockup](docs/mockup.jpg)

## Overview

Orclawstrator is a Swift/AppKit desktop application that provides a unified dashboard for managing multiple OpenClaw AI agents working across dozens of projects simultaneously. It's mission control for AI-assisted development at scale.

## Why Native Swift?

- **Performance** — Native AppKit, not Electron. Handles 100+ projects without breaking a sweat.
- **System Integration** — Deep macOS integration for notifications, menubar, keyboard shortcuts.
- **Resource Efficiency** — Minimal memory footprint compared to browser-based alternatives.

## Core Features

### Dashboard View

| Column | Data Source | Description |
|--------|-------------|-------------|
| **Project Name** | Local filesystem | With language icon (Swift, TypeScript, Rust, C, Terminal) |
| **Warning Indicator** | Computed | Yellow/orange triangle if issues detected |
| **Agent** | OpenClaw API | Assigned AI persona (e.g., "Rusty P. Shackelford") |
| **Branches** | Git CLI | Main branch + sub-branch count |
| **Active Branch** | Git CLI | Current working branch name |
| **Issues** | GitHub CLI (`gh`) | Open issue count |
| **Stacked PRs** | Graphite CLI (`gt`) | PR stack depth |
| **Untracked** | Git CLI | Untracked file count (red) |
| **Staged** | Git CLI | Staged file count (green) |
| **Age** | Git CLI | Time since first commit (Xy Xm Xd) |
| **Last Main** | Git CLI | Time since last main commit/merge |
| **Last Branch** | Git CLI | Time since current branch commit |
| **PR Comments** | Graphite API | Total comments on PR stack |
| **Build Status** | Vercel CLI | Ready / Building / Queued / Error |

### Action Buttons (Right Side)

| Icon | Action |
|------|--------|
| 🔗 | Open URL / Open Folder |
| 📋 | View ROADMAP.md |
| 📖 | View README.md |
| 📊 | View on PostHog / View Profiler |
| 📝 | Plan (open/create PLAN.md) |
| ➕ | Add Tasks |

### Project Detail View (Click Project Name)

**Split Layout:**
- **Left Panel (Tabbed):** Rendered markdown files from project (README, PLAN, CHANGELOG, etc.) — editable with live preview (like nvim markdown plugins)
- **Right Panel:** Current agent activity output stream

**Additional Features:**
- Chat history with agent
- Add messages to chat
- Branch switcher dropdown
- PR stack viewer (comments thread + diffs, like Graphite web UI)

### Global Inbox

Stream of all incoming messages from all agents and bots across all projects. Unified notification center for multi-agent orchestration.

### Top Bar Stats

| Element | Source |
|---------|--------|
| `~/Projects (65)` | Filesystem scan |
| `22 Ready / 02 Building / 02 Error` | Vercel API aggregated |
| `02 Idle` | OpenClaw Gateway API |
| `04 Agents / 36 Subs` | OpenClaw sessions API |
| `125k/200k Tokens` | OpenClaw usage API |

### Left Sidebar

- **Chat input** — Talk directly to OpenClaw
- **+ New Project** — Scaffold with agent assignment
- **Recent Chats** — Quick access to conversations

### Status Bar

- Connection state (Connected/Disconnected)
- Agent status (Idle/Working)
- Current session info
- Model info (anthropic/claude-opus-4.6)

## Integrations

| Service | Integration Method |
|---------|-------------------|
| **Git** | CLI (`git`) |
| **GitHub** | CLI (`gh`) |
| **Graphite** | CLI (`gt`) + API |
| **Vercel** | CLI (`vercel`) + API |
| **OpenClaw** | Gateway API |
| **PostHog** | API (optional) |

## Language Detection

Projects are classified by primary language, shown as icons:

| Icon | Language/Type |
|------|---------------|
| 🔷 | TypeScript/JavaScript |
| 🦅 | Swift |
| 🦀 | Rust |
| ⚙️ | C/C++ |
| 🐍 | Python |
| 💎 | Ruby |
| 🐹 | Go |
| 🖥️ | CLI/TUI/Scripts |

## Tech Stack

- **Language:** Swift 5.9+
- **Framework:** AppKit (native macOS)
- **Minimum OS:** macOS 14.0 (Sonoma)
- **Architecture:** arm64 (Apple Silicon native)
- **Build:** Xcode / Swift Package Manager
- **Storage:** SQLite (local state/cache)
- **IPC:** Unix sockets / HTTP for OpenClaw Gateway

## Development

```bash
# Clone
git clone https://github.com/michaelmonetized/orclawstrator.git
cd orclawstrator

# Open in Xcode
open Orclawstrator.xcodeproj

# Or build from CLI
swift build
```

## License

MIT © 2026 HurleyUS

---

*Built with 🦞 by the OpenClaw ecosystem*
