package scanner

import (
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/google/uuid"
)

// Project represents a scanned project
type Project struct {
	ID         string
	Name       string
	Path       string
	Language   string
	Agent      string
	StackCount int
	HasWarning bool
	WarningMsg string
	GitState   GitState
}

// GitState represents the git status of a project
type GitState struct {
	ActiveBranch string
	BranchCount  int
	Untracked    int
	Staged       int
	HasRemote    bool
	Branches     []string
}

// Scanner scans directories for projects
type Scanner struct{}

// New creates a new scanner
func New() *Scanner {
	return &Scanner{}
}

// ScanProjects scans a directory for git projects
func (s *Scanner) ScanProjects(dir string) ([]Project, error) {
	// Expand tilde
	if strings.HasPrefix(dir, "~/") {
		home, _ := os.UserHomeDir()
		dir = filepath.Join(home, dir[2:])
	}

	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, err
	}

	var projects []Project

	for _, entry := range entries {
		if !entry.IsDir() || strings.HasPrefix(entry.Name(), ".") {
			continue
		}

		projectPath := filepath.Join(dir, entry.Name())

		// Check if it's a git repo
		if !isGitRepo(projectPath) {
			continue
		}

		p := Project{
			ID:   uuid.New().String(),
			Name: entry.Name(),
			Path: projectPath,
		}

		// Detect language
		p.Language = detectLanguage(projectPath)

		// Get git state
		p.GitState = getGitState(projectPath)

		// Get stack count (Graphite)
		p.StackCount = getStackCount(projectPath)

		// Check warnings
		checkWarnings(&p)

		projects = append(projects, p)
	}

	return projects, nil
}

func isGitRepo(path string) bool {
	gitPath := filepath.Join(path, ".git")
	info, err := os.Stat(gitPath)
	return err == nil && info.IsDir()
}

func detectLanguage(path string) string {
	checks := []struct {
		file string
		lang string
	}{
		{"Package.swift", "swift"},
		{"Cargo.toml", "rust"},
		{"go.mod", "go"},
		{"pyproject.toml", "python"},
		{"setup.py", "python"},
		{"requirements.txt", "python"},
		{"Gemfile", "ruby"},
		{"tsconfig.json", "typescript"},
		{"package.json", "javascript"},
		{"CMakeLists.txt", "cpp"},
		{"Makefile", "c"},
	}

	for _, check := range checks {
		if _, err := os.Stat(filepath.Join(path, check.file)); err == nil {
			// Special case: package.json but no tsconfig = javascript
			if check.lang == "javascript" {
				if _, err := os.Stat(filepath.Join(path, "tsconfig.json")); err == nil {
					return "typescript"
				}
			}
			return check.lang
		}
	}

	// Check for Xcode project
	entries, _ := os.ReadDir(path)
	for _, e := range entries {
		if strings.HasSuffix(e.Name(), ".xcodeproj") || strings.HasSuffix(e.Name(), ".xcworkspace") {
			return "swift"
		}
	}

	return "terminal"
}

func getGitState(path string) GitState {
	state := GitState{}

	// Get current branch
	if out, err := runGit(path, "branch", "--show-current"); err == nil {
		state.ActiveBranch = strings.TrimSpace(out)
	}
	if state.ActiveBranch == "" {
		state.ActiveBranch = "main"
	}

	// Get branch count
	if out, err := runGit(path, "branch", "-a"); err == nil {
		lines := strings.Split(strings.TrimSpace(out), "\n")
		for _, line := range lines {
			line = strings.TrimSpace(line)
			if line != "" && !strings.Contains(line, "->") {
				// Clean up branch name
				branch := strings.TrimPrefix(line, "* ")
				branch = strings.TrimPrefix(branch, "remotes/origin/")
				if branch != "" && !contains(state.Branches, branch) {
					state.Branches = append(state.Branches, branch)
				}
			}
		}
		state.BranchCount = len(state.Branches)
	}

	// Get status
	if out, err := runGit(path, "status", "--porcelain"); err == nil {
		lines := strings.Split(out, "\n")
		for _, line := range lines {
			if len(line) < 2 {
				continue
			}
			index := line[0]
			worktree := line[1]

			if index == '?' {
				state.Untracked++
			} else if index != ' ' {
				state.Staged++
			} else if worktree != ' ' {
				state.Untracked++
			}
		}
	}

	// Check for remote
	if out, err := runGit(path, "remote"); err == nil {
		state.HasRemote = strings.TrimSpace(out) != ""
	}

	return state
}

func getStackCount(path string) int {
	// Check if graphite is available
	if _, err := exec.LookPath("gt"); err != nil {
		return 0
	}

	out, err := runCmd(path, "gt", "stack", "--list", "--quiet")
	if err != nil {
		return 0
	}

	lines := strings.Split(strings.TrimSpace(out), "\n")
	count := 0
	for _, line := range lines {
		if strings.TrimSpace(line) != "" {
			count++
		}
	}
	return count
}

func checkWarnings(p *Project) {
	// Warning if too many untracked files
	if p.GitState.Untracked > 10 {
		p.HasWarning = true
		p.WarningMsg = strconv.Itoa(p.GitState.Untracked) + " untracked files"
	}

	// Warning if no remote
	if !p.GitState.HasRemote {
		p.HasWarning = true
		p.WarningMsg = "No remote configured"
	}
}

func runGit(path string, args ...string) (string, error) {
	return runCmd(path, "git", args...)
}

func runCmd(path string, name string, args ...string) (string, error) {
	cmd := exec.Command(name, args...)
	cmd.Dir = path
	out, err := cmd.Output()
	return string(out), err
}

func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}
