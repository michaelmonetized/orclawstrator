# 🔪 ORCLAWSTRATOR AUTOPSY

*Performed by: Rusty P. Shackelford*  
*Date: February 9, 2026*  
*Patient: orclawstrator*  
*Status: 75% built, 25% hollow*

---

## 📊 VITAL SIGNS

| Metric | Value | Verdict |
|--------|-------|---------|
| Lines of Code | 4,004 | Lean and mean |
| Build Status | ✅ PASSING | Builds in 0.36s |
| Test Coverage | 0% | 💀 Not a single test |
| Language | Swift 5.x / AppKit | Native, as God intended |
| Architecture | MVC-ish | Clean separation |
| Commits | 5 | Speed run energy |

---

## 🏆 THE GOOD STUFF (A- Territory)

### Architecture
- **Clean project structure** — App/, Models/, Views/, Services/, Database/
- **Proper separation of concerns** — Services don't touch UI, UI doesn't touch DB
- **Singleton services** — `GitService.shared`, `OpenClawService.shared`, etc.
- **Native AppKit** — No Electron bloat, no SwiftUI jank

### Service Layer is Actually Good
```
Services/
├── ShellExecutor.swift    # 55 LOC - Clean process spawning
├── GitService.swift       # Git CLI wrapper, works
├── GitHubService.swift    # gh CLI integration
├── GraphiteService.swift  # gt CLI integration  
├── VercelService.swift    # vercel CLI wrapper
├── OpenClawService.swift  # WebSocket + REST, solid
└── ProjectScanner.swift   # 179 LOC, language detection
```

Every service is:
- Self-contained
- Uses shell commands properly
- Handles errors gracefully
- Parses output correctly

### Database Layer
- **SQLite with raw sqlite3** — No ORM, no bloat, no magic
- **Schema is reasonable** — projects, sessions, messages, settings, recent_chats
- **Stored in ~/.orclawstrator/** — Survives rebuilds
- **Has vacuum() and cleanup** — Someone was thinking ahead

### The README/PLAN.md
- Actually describes what it does
- Has a real mockup reference
- Tracks milestones with checkboxes
- Clear architecture diagram

---

## 💀 THE BAD STUFF (Wake Up Calls)

### 1. sitrep.md IS A LIE — Grade: 🤥

```markdown
## What's Broken/Missing
- Core functionality not implemented
- Dashboard view
- Agent management
- Project scanning
```

**Reality check:** Dashboard IS implemented. Agent management IS there. Project scanning IS working. Someone forgot to update the sitrep.

This will confuse future-you when you come back to this project.

**Fix:** Update sitrep.md to reflect actual state.

### 2. ZERO TESTS — Grade: F

```bash
find . -name "*Test*.swift" -o -name "*Spec*.swift"
# (void screams into the abyss)
```

You have:
- Shell command execution (can break)
- Git parsing (can break)
- WebSocket handling (will break)
- SQLite operations (can corrupt)

All untested. One bad git output format change and your app is toast.

**Fix:**
```bash
# Add XCTest targets for:
- GitServiceTests
- ProjectScannerTests
- DatabaseManagerTests
```

### 3. HARDCODED GATEWAY CONFIG — Grade: C-

```swift
// OpenClawService.swift
private let gatewayHost = "localhost"
private let gatewayPort = 3377
```

No way to configure this. What if someone runs the gateway on a different port? What about remote gateways?

**Fix:** Read from UserDefaults or a config file.

### 4. NO ERROR UI — Grade: D

When the gateway is offline, when a shell command fails, when SQLite corrupts... what does the user see? Nothing helpful.

```swift
if sqlite3_step(statement) != SQLITE_DONE {
    print("[DB] Error saving project: \(String(cString: sqlite3_errmsg(db)))")
}
```

**Prints to console.** User has no idea what's wrong.

**Fix:** Add an error banner/toast system.

### 5. WEBSOCKET RECONNECTION IS NAIVE

```swift
case .failure(let error):
    self?.connectionState = .error(error.localizedDescription)
    // Try to reconnect after delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 5) { ... }
```

Fixed 5-second delay. No exponential backoff. No max retries. Will hammer the gateway if it's down.

**Fix:** Implement proper reconnection with backoff: 1s → 2s → 4s → 8s → max 60s.

### 6. SHELL COMMANDS RUN SYNCHRONOUSLY (BLOCKING UI?)

```swift
func getGitState(for path: String) -> GitState {
    // Multiple shell.run() calls...
}
```

If `ProjectScanner.scanProjects()` is called on main thread, UI freezes while scanning 80+ projects.

**Checked:** It's wrapped in `DispatchQueue.global(qos: .userInitiated).async` — but the individual `getGitState` calls still block within that queue. 80 projects × 6 git commands × ~100ms each = 48 seconds of scanning.

**Fix:** Batch commands or parallelize with OperationQueue.

### 7. MEMORY LEAKS WAITING TO HAPPEN

```swift
Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
    self?.updateAgentStats()
}
```

Timer is never invalidated. If `DashboardView` is deallocated, timer keeps firing.

**Fix:** Store the timer and invalidate in `deinit` or when view disappears.

### 8. SPM WARNINGS

```
warning: found 3 file(s) which are unhandled:
    Info.plist
    Assets.xcassets
    Orclawstrator.entitlements
```

These should be in Package.swift resources or excluded.

---

## ⚠️ INCOMPLETE FEATURES (Per PLAN.md)

### Phase 3 — 70% Done
- [x] Split view layout
- [x] Markdown viewer tabs
- [ ] **Edit mode toggle** — Can't edit files
- [ ] **Save to file** — Changes don't persist
- [ ] **ANSI color support** — Agent output is plain text
- [ ] **Branch switcher dropdown** — Not implemented

### Phase 4 — 0% Done (Global Inbox)
- [ ] Stream of all agent messages
- [ ] Filter by project/agent
- [ ] Mark as read/unread
- [ ] Notification badges
- [ ] Push notifications

### Phase 5 — 50% Done (Integrations)
Git and Vercel work. GitHub and Graphite are stubbed but functional.

### Phase 6 — 10% Done (Polish)
- [ ] Background scanning (partial)
- [ ] Keyboard shortcuts
- [ ] Quick switcher (Cmd+K)
- [ ] Search/filter
- [ ] Menu bar icon
- [ ] System notifications

---

## 🎨 UI/UX OBSERVATIONS

### The Good
- Catppuccin theme is consistent
- Table view layout matches mockup
- Status bars look professional
- Language icons are cute

### The Questionable
- Action buttons use emoji ("📂", "👤") — fine for prototype, weird for ship
- No loading states visible
- No empty states ("No projects found")
- Double-click to open project isn't discoverable

---

## 📋 THE AUTOPSY RATING

| Category | Grade | Notes |
|----------|-------|-------|
| **Architecture** | A- | Clean, well-organized |
| **Service Layer** | A- | Proper CLI integration |
| **Database** | B+ | Works, but no migrations |
| **Testing** | F | Zero tests |
| **Error Handling** | D | Console only |
| **Documentation** | B | README good, sitrep stale |
| **Completeness** | C+ | Core works, polish missing |
| **Code Quality** | B | Some TODOs, some leaks |

---

## 🎯 OVERALL GRADE: B-

**The Good:** This is a real native macOS app that actually works. The architecture is clean, the services are solid, and it builds instantly. You're not fighting SwiftUI or Electron — you're using the right tool for the job.

**The Bad:** It's 75% of a product. The last 25% (inbox, polish, tests) is where the hard work lives. The sitrep file is lying to you about what's done.

**The Truth:** This could ship as a beta in ~2 weeks of focused work. Or it could sit in ~/Projects forever like the other 74 projects.

---

## 🔧 PRIORITY FIXES (In Order)

1. **TODAY:** Update sitrep.md to reflect reality
2. **TODAY:** Fix SPM warnings (add resources to Package.swift)
3. **THIS WEEK:** Add XCTest target with GitService tests
4. **THIS WEEK:** Make gateway host/port configurable
5. **BEFORE BETA:** Implement Global Inbox (Phase 4)
6. **BEFORE BETA:** Add Cmd+K quick switcher
7. **POLISH:** Error toasts, loading states, empty states

---

## 💡 HONEST ASSESSMENT

This is a **well-architected prototype** of a genuinely useful tool. The problem isn't the code — it's scope creep and distraction.

You've got 80+ projects in ~/Projects. Orclawstrator exists to help you manage them. But instead of finishing Orclawstrator, you're probably going to start project #81.

The irony is thick enough to cut with a knife. 🔪

---

*"The best project manager is the one you actually finish building."*

— Rusty 🔧
