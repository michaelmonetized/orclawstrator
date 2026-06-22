# Orclawstrator 🦞

**Command center for orchestrating AI coding agents across your entire project portfolio.**

```
┌─────────────────────────────────────────────────────────────────────┐
│  Orclawstrator                          󰚩 3 active   󰆧 125k/500k  │
├────────────┬────────────────────────────────────────────────────────┤
│            │   Dashboard                                           │
│ 󰭻  Chat    │                                                        │
│            │  PROJECT           AGENT       BRANCH   STACKS CHANGES │
│ 󰇮  Inbox   │  ──────────────────────────────────────────────────────│
│            │    orclawstrator  󰚩 Claude    05 main   02   clean   │
│ Recent     │    getat.me       󰚩 Claude    12 feat   05    03 stg  │
│ ───────    │    bestwnc.com    —           03 main   00    12 unt  │
│  chat 1    │    ...                                                 │
│  chat 2    │                                                        │
└────────────┴────────────────────────────────────────────────────────┘
 j/k nav  enter open  r refresh  i inbox  q quit
```

## Monorepo Structure

```
orclawstrator/
├── tui/              # Go TUI using Bubble Tea (recommended)
│   ├── cmd/
│   ├── internal/
│   └── Makefile
├── swift-appkit/     # Native macOS AppKit version (archived)
│   ├── Package.swift
│   └── Orclawstrator/
└── README.md
```

Both versions share the same SQLite database at `~/.orclawstrator/cache.db`.

---

## TUI (Recommended)

Fast, responsive terminal interface with Nerdfont icons.

```bash
cd tui
make run
```

Or install globally:

```bash
cd tui
make install
orclawstrator
```

### Features

-  **Dashboard** — Project list with git status, branches, stacks
-  **Project Detail** — View/edit README, PLAN, ROADMAP, CHANGELOG
-  **Vim-style navigation** — j/k, h/l, numbers for quick access
-  **Nerdfont icons** — Beautiful icons for languages and status
-  **Responsive** — Adapts to terminal size
-  **Shared DB** — Reuses cache across both versions

### Keybindings

| Key | Action |
|-----|--------|
| `j/k` | Navigate up/down |
| `h/l` | Navigate left/right |
| `Enter` | Select/open |
| `Esc` | Back |
| `Tab` | Switch focus |
| `1-9` | Quick project access |
| `r` | Refresh |
| `i` | Inbox |
| `e` | Edit in $EDITOR |
| `o` | Open folder |
| `t` | Open terminal |
| `q` | Quit |

### Requirements

- Go 1.21+
- A [Nerd Font](https://www.nerdfonts.com/) for icons
- Optional: `gt` (Graphite CLI) for stack counts
- Optional: `gh` (GitHub CLI) for PR info

---

## Swift AppKit (Archived)

Native macOS app. Has some embedding issues with terminal views.

```bash
cd swift-appkit
swift build
.build/debug/Orclawstrator
```

---

## Database Schema

```sql
-- Projects cache
CREATE TABLE projects (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    path TEXT NOT NULL UNIQUE,
    language TEXT,
    last_scanned INTEGER,
    is_favorite INTEGER DEFAULT 0,
    notes TEXT
);

-- Agent sessions
CREATE TABLE sessions (
    id TEXT PRIMARY KEY,
    project_id TEXT,
    label TEXT,
    model TEXT,
    status TEXT,
    tokens_used INTEGER DEFAULT 0
);

-- Messages inbox
CREATE TABLE messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT,
    type TEXT,
    content TEXT,
    timestamp INTEGER,
    read INTEGER DEFAULT 0
);
```

---

## Language Icons

| Icon | Language |
|------|----------|
|   | Swift |
|   | Rust |
|   | Go |
|   | Python |
|   | JavaScript |
|   | TypeScript |
|   | Ruby |
|   | C |
|   | C++ |
|   | Terminal/Scripts |

## Integrations

| Service | Method |
|---------|--------|
| **Git** | CLI |
| **GitHub** | `gh` CLI |
| **Graphite** | `gt` CLI |
| **Vercel** | CLI + API |
| **OpenClaw** | Gateway API |

---

## License

MIT © 2026 HurleyUS

*Built with 🦞 by the OpenClaw ecosystem*
