# PLAN.md - Orclawstrator Development Plan

## Phase 1: Foundation (MVP)

### 1.1 Project Setup
- [x] Create Xcode project with AppKit template
- [x] Configure Swift Package Manager dependencies
- [x] Set up project structure (MVC or MVVM)
- [x] Configure code signing and entitlements
- [x] Set up SQLite for local state

### 1.2 Core Data Models
- [x] `Project` — path, name, language, timestamps
- [x] `Agent` — id, name, persona, status (via OpenClawService.SessionInfo)
- [x] `Session` — project assignment, token usage
- [x] `BuildStatus` — vercel deployment state
- [x] `GitState` — branches, staged, untracked, stacks
- [x] `Message` — inbox items from agents (via OpenClawService.AgentMessage)

### 1.3 Shell Integration Layer
- [x] Create `ShellExecutor` for running CLI commands
- [x] Git integration (`git status`, `git log`, `git branch`)
- [x] GitHub CLI integration (`gh issue list`, `gh pr list`)
- [x] Graphite CLI integration (`gt log`, `gt stack`)
- [x] Vercel CLI integration (`vercel ls`, `vercel inspect`)

### 1.4 OpenClaw Gateway Integration
- [x] HTTP client for Gateway API
- [x] WebSocket for real-time agent output
- [x] Session management (list, spawn, send)
- [x] Token usage tracking

---

## Phase 2: Dashboard View

### 2.1 Main Window
- [x] NSWindow with custom title bar (traffic lights repositioned)
- [x] Dark theme with gradient background
- [x] Top bar with stats (projects, builds, agents, tokens)
- [x] Responsive layout

### 2.2 Project Table
- [x] NSTableView with custom cells
- [x] Columns: Name, Agent, Branches, Active Branch, Issues, Stacks, Untracked, Staged, Age, Last Main, Last Branch, PR Comments, Build Status
- [x] Language icons (Swift, TS, Rust, C, Terminal)
- [x] Color-coded status (red untracked, green staged)
- [x] Warning indicators (yellow/orange triangles)
- [x] Action buttons row (open, roadmap, readme, posthog, plan, add)

### 2.3 Left Sidebar
- [x] Chat input field (NSTextField)
- [x] "+ New Project" button
- [x] Recent Chats list (NSOutlineView)
- [ ] Collapsible sections

### 2.4 Status Bar
- [x] Connection indicator (green/red dot)
- [x] Status text (Connected | Idle | agent main)
- [x] Model/session info on right

---

## Phase 3: Project Detail View

### 3.1 Split View Layout
- [x] NSSplitView horizontal split
- [x] Left: Markdown viewer/editor tabs
- [x] Right: Agent activity stream

### 3.2 Markdown Panel (Embedded nvim via SwiftTerm)
- [x] Tab bar for project files (README, PLAN, CHANGELOG, ROADMAP)
- [x] Full terminal emulation with SwiftTerm library
- [x] nvim launches for each tab with proper VT100/xterm-256color support
- [x] Catppuccin color palette in terminal
- [x] Edit + save via nvim (native nvim behavior)

### 3.3 Agent Activity Panel
- [x] Streaming text view for agent output
- [x] ANSI color support (via SwiftTerm for nvim panel)
- [x] Auto-scroll with manual override
- [x] Copy/clear actions (post-Feb polish; see AUTOPSY)

### 3.4 Chat Integration
- [x] Chat history view
- [x] Message input field
- [x] Send to agent action
- [x] Branch switcher dropdown

### 3.5 PR Stack Viewer
- [ ] Click stack count to open viewer
- [ ] Comments thread (like GitHub/Graphite)
- [ ] Diffs below comments
- [ ] Expand/collapse sections

---

## Phase 4: Global Inbox

### 4.1 Inbox View
- [x] Stream of all agent messages (`InboxView`)
- [x] Filter by session
- [x] Mark as read / mark all read (DatabaseManager)
- [x] Sidebar inbox button + unread badge
- [ ] Richer per-project filters / reply actions (remaining)

### 4.2 Real-time Updates
- [x] WebSocket connection to Gateway (OpenClawService)
- [ ] Push notifications for important messages
- [ ] Badge count in Dock icon

---

## Phase 5: Integrations

> Note: Core CLI integrations landed in Phase 1.3 and are used by the dashboard at HEAD. Checkboxes below reflect that.

### 5.1 Git Operations
- [x] `git status --porcelain` parsing
- [x] `git log --oneline` for history
- [x] `git branch -a` for branch list
- [x] First commit date extraction
- [x] Last commit timestamps

### 5.2 GitHub CLI
- [x] `gh issue list --json` parsing
- [x] `gh pr list --json` parsing
- [x] Issue/PR counts per project

### 5.3 Graphite CLI
- [x] `gt log short --stack` parsing
- [x] Stack details + PR Stack Viewer (`PRStackPopover`)
- [ ] Stack comment counts via API (partial)

### 5.4 Vercel CLI
- [x] `vercel ls` / inspect integration for build status
- [x] Deployment status mapping
- [ ] Build log fetching on error

### 5.5 Language Detection
- [x] Scan for Package.swift (Swift)
- [x] Scan for package.json + tsconfig (TypeScript)
- [x] Scan for Cargo.toml (Rust)
- [x] Scan for Makefile/CMakeLists (C/C++)
- [x] Scan for pyproject.toml (Python)
- [x] Default to Terminal icon

---

## Phase 6: Polish

### 6.1 Performance
- [x] Caching with SQLite (`~/.orclawstrator/cache.db`)
- [x] ProjectScanner cache for quick switcher
- [ ] Incremental updates (file watchers)
- [ ] Lazy loading for large project lists

### 6.2 UX
- [x] Keyboard shortcuts (Cmd+1 dashboard, Cmd+I inbox, Cmd+R refresh, Cmd+1-9 jump, Esc back)
- [x] Quick switcher (Cmd+K)
- [ ] Search/filter projects (beyond quick switcher)
- [ ] Drag-drop project reordering
- [x] Catppuccin theme (custom themes beyond that still open)

### 6.3 System Integration
- [x] Menu bar icon with quick actions
- [x] Error banner UI (`ErrorBanner`)
- [ ] Notifications for build failures
- [ ] Spotlight integration
- [ ] Touch Bar support (if applicable)

---

## Architecture

```
Orclawstrator/
├── App/
│   ├── AppDelegate.swift
│   ├── MainWindow.swift
│   └── Preferences.swift
├── Models/
│   ├── Project.swift
│   ├── Agent.swift
│   ├── Session.swift
│   ├── BuildStatus.swift
│   └── GitState.swift
├── Views/
│   ├── Dashboard/
│   │   ├── DashboardViewController.swift
│   │   ├── ProjectTableView.swift
│   │   ├── ProjectRowView.swift
│   │   └── TopBarView.swift
│   ├── Sidebar/
│   │   ├── SidebarViewController.swift
│   │   ├── ChatInputView.swift
│   │   └── RecentChatsView.swift
│   ├── Detail/
│   │   ├── ProjectDetailViewController.swift
│   │   ├── MarkdownEditorView.swift
│   │   ├── AgentActivityView.swift
│   │   └── PRStackView.swift
│   └── Inbox/
│       ├── InboxViewController.swift
│       └── MessageRowView.swift
├── Services/
│   ├── ShellExecutor.swift
│   ├── GitService.swift
│   ├── GitHubService.swift
│   ├── GraphiteService.swift
│   ├── VercelService.swift
│   ├── OpenClawService.swift
│   └── ProjectScanner.swift
├── Database/
│   ├── DatabaseManager.swift
│   └── Migrations/
└── Resources/
    ├── Assets.xcassets
    └── MainMenu.xib
```

---

## Dependencies

| Package | Purpose |
|---------|---------|
| `swift-markdown` | Markdown parsing/rendering |
| `SQLite.swift` | Local database |
| `Starscream` | WebSocket client |
| `SwiftyJSON` | JSON parsing (optional) |

---

## Milestones

| Milestone | Target | Status |
|-----------|--------|--------|
| M1: Window + Table | Week 1 | ✅ |
| M2: Git Integration | Week 2 | ✅ |
| M3: OpenClaw Integration | Week 3 | ✅ |
| M4: Project Detail View | Week 4 | ✅ |
| M5: Inbox + Polish | Week 5 | ✅ (see AUTOPSY 2026-02-09) |
| M6: Beta Release | Week 6 | 🟡 remaining polish / notifications |

---

## Notes

- Start with hardcoded `~/Projects` path, make configurable later
- Use `Process` for shell commands, consider `ShellOut` package
- Cache aggressively, update on file system events
- Consider menu bar-only mode for minimal footprint

---

*Last updated: 2026-09-08 — PLAN parity vs HEAD/AUTOPSY (Phases 4–6 checkboxes synced).*
