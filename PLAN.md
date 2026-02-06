# PLAN.md - Orclawstrator Development Plan

## Phase 1: Foundation (MVP)

### 1.1 Project Setup
- [x] Create Xcode project with AppKit template
- [ ] Configure Swift Package Manager dependencies
- [x] Set up project structure (MVC or MVVM)
- [x] Configure code signing and entitlements
- [ ] Set up SQLite for local state

### 1.2 Core Data Models
- [x] `Project` — path, name, language, timestamps
- [ ] `Agent` — id, name, persona, status
- [ ] `Session` — project assignment, token usage
- [x] `BuildStatus` — vercel deployment state
- [x] `GitState` — branches, staged, untracked, stacks
- [ ] `Message` — inbox items from agents

### 1.3 Shell Integration Layer
- [x] Create `ShellExecutor` for running CLI commands
- [x] Git integration (`git status`, `git log`, `git branch`)
- [ ] GitHub CLI integration (`gh issue list`, `gh pr list`)
- [ ] Graphite CLI integration (`gt log`, `gt stack`)
- [ ] Vercel CLI integration (`vercel ls`, `vercel inspect`)

### 1.4 OpenClaw Gateway Integration
- [ ] HTTP client for Gateway API
- [ ] WebSocket for real-time agent output
- [ ] Session management (list, spawn, send)
- [ ] Token usage tracking

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
- [ ] NSSplitView horizontal split
- [ ] Left: Markdown viewer/editor tabs
- [ ] Right: Agent activity stream

### 3.2 Markdown Panel
- [ ] Tab bar for project files (README, PLAN, CHANGELOG, ROADMAP)
- [ ] Live markdown rendering (like nvim markdown plugins)
- [ ] Edit mode toggle
- [ ] Save to file on edit

### 3.3 Agent Activity Panel
- [ ] Streaming text view for agent output
- [ ] ANSI color support
- [ ] Auto-scroll with manual override
- [ ] Copy/clear actions

### 3.4 Chat Integration
- [ ] Chat history view
- [ ] Message input field
- [ ] Send to agent action
- [ ] Branch switcher dropdown

### 3.5 PR Stack Viewer
- [ ] Click stack count to open viewer
- [ ] Comments thread (like GitHub/Graphite)
- [ ] Diffs below comments
- [ ] Expand/collapse sections

---

## Phase 4: Global Inbox

### 4.1 Inbox View
- [ ] Stream of all agent messages
- [ ] Filter by project/agent
- [ ] Mark as read/unread
- [ ] Quick actions (reply, open project)
- [ ] Notification badges

### 4.2 Real-time Updates
- [ ] WebSocket connection to Gateway
- [ ] Push notifications for important messages
- [ ] Badge count in Dock icon

---

## Phase 5: Integrations

### 5.1 Git Operations
- [ ] `git status --porcelain` parsing
- [ ] `git log --oneline` for history
- [ ] `git branch -a` for branch list
- [ ] First commit date extraction
- [ ] Last commit timestamps

### 5.2 GitHub CLI
- [ ] `gh issue list --json` parsing
- [ ] `gh pr list --json` parsing
- [ ] Issue/PR counts per project

### 5.3 Graphite CLI
- [ ] `gt log short --stack` parsing
- [ ] `gt stack` for PR details
- [ ] Stack comment counts via API

### 5.4 Vercel CLI
- [ ] `vercel ls --json` parsing
- [ ] Deployment status mapping
- [ ] Build log fetching on error

### 5.5 Language Detection
- [ ] Scan for Package.swift (Swift)
- [ ] Scan for package.json + tsconfig (TypeScript)
- [ ] Scan for Cargo.toml (Rust)
- [ ] Scan for Makefile/CMakeLists (C/C++)
- [ ] Scan for pyproject.toml (Python)
- [ ] Default to Terminal icon

---

## Phase 6: Polish

### 6.1 Performance
- [ ] Background scanning (not blocking UI)
- [ ] Incremental updates (file watchers)
- [ ] Caching with SQLite
- [ ] Lazy loading for large project lists

### 6.2 UX
- [ ] Keyboard shortcuts (Cmd+1-9 for projects)
- [ ] Quick switcher (Cmd+K)
- [ ] Search/filter projects
- [ ] Drag-drop project reordering
- [ ] Custom themes

### 6.3 System Integration
- [ ] Menu bar icon with quick actions
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
| M2: Git Integration | Week 2 | 🟡 In Progress |
| M3: OpenClaw Integration | Week 3 | ⬜ |
| M4: Project Detail View | Week 4 | ⬜ |
| M5: Inbox + Polish | Week 5 | ⬜ |
| M6: Beta Release | Week 6 | ⬜ |

---

## Notes

- Start with hardcoded `~/Projects` path, make configurable later
- Use `Process` for shell commands, consider `ShellOut` package
- Cache aggressively, update on file system events
- Consider menu bar-only mode for minimal footprint

---

*Last updated: 2026-02-06*
