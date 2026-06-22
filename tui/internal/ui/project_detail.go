package ui

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/charmbracelet/bubbles/key"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/michaelcolletti/orclawstrator/internal/scanner"
)

// ProjectDetailModel handles the project detail view
type ProjectDetailModel struct {
	width     int
	height    int
	project   *scanner.Project
	activeTab int
	content   string
	tabs      []string
	files     []string
}

func NewProjectDetailModel() ProjectDetailModel {
	return ProjectDetailModel{
		tabs:  []string{"README", "PLAN", "ROADMAP", "CHANGELOG"},
		files: []string{"README.md", "PLAN.md", "ROADMAP.md", "CHANGELOG.md"},
	}
}

func (m *ProjectDetailModel) SetSize(w, h int) {
	m.width = w
	m.height = h
}

func (m *ProjectDetailModel) SetProject(p *scanner.Project) {
	m.project = p
	m.activeTab = 0
	m.loadContent()
}

func (m *ProjectDetailModel) loadContent() {
	if m.project == nil {
		m.content = "No project selected"
		return
	}

	filePath := filepath.Join(m.project.Path, m.files[m.activeTab])
	data, err := os.ReadFile(filePath)
	if err != nil {
		m.content = fmt.Sprintf("File not found: %s\n\nPress 'e' to create it.", m.files[m.activeTab])
		return
	}
	m.content = string(data)
}

func (m ProjectDetailModel) Update(msg tea.Msg) (ProjectDetailModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch {
		case msg.String() == "1":
			m.activeTab = 0
			m.loadContent()
		case msg.String() == "2":
			m.activeTab = 1
			m.loadContent()
		case msg.String() == "3":
			m.activeTab = 2
			m.loadContent()
		case msg.String() == "4":
			m.activeTab = 3
			m.loadContent()
		case key.Matches(msg, key.NewBinding(key.WithKeys("e"))):
			// Open in $EDITOR
			return m, m.openInEditor()
		case key.Matches(msg, key.NewBinding(key.WithKeys("o"))):
			// Open folder
			return m, m.openFolder()
		case key.Matches(msg, key.NewBinding(key.WithKeys("t"))):
			// Open terminal
			return m, m.openTerminal()
		}
	case editorClosedMsg:
		m.loadContent()
	}
	return m, nil
}

type editorClosedMsg struct{}

func (m ProjectDetailModel) openInEditor() tea.Cmd {
	if m.project == nil {
		return nil
	}
	filePath := filepath.Join(m.project.Path, m.files[m.activeTab])

	// Create file if it doesn't exist
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		template := m.getTemplate()
		os.WriteFile(filePath, []byte(template), 0644)
	}

	editor := os.Getenv("EDITOR")
	if editor == "" {
		editor = "nvim"
	}

	c := exec.Command(editor, filePath)
	return tea.ExecProcess(c, func(err error) tea.Msg {
		return editorClosedMsg{}
	})
}

func (m ProjectDetailModel) openFolder() tea.Cmd {
	if m.project == nil {
		return nil
	}
	c := exec.Command("open", m.project.Path)
	return tea.ExecProcess(c, func(err error) tea.Msg { return nil })
}

func (m ProjectDetailModel) openTerminal() tea.Cmd {
	if m.project == nil {
		return nil
	}
	// Open in Terminal.app
	script := fmt.Sprintf(`tell application "Terminal" to do script "cd '%s'"`, m.project.Path)
	c := exec.Command("osascript", "-e", script)
	return tea.ExecProcess(c, func(err error) tea.Msg { return nil })
}

func (m ProjectDetailModel) getTemplate() string {
	name := "Project"
	if m.project != nil {
		name = m.project.Name
	}
	switch m.files[m.activeTab] {
	case "README.md":
		return fmt.Sprintf("# %s\n\nDescribe your project here.\n", name)
	case "PLAN.md":
		return fmt.Sprintf("# %s - Plan\n\n## Goals\n\n- [ ] Goal 1\n", name)
	case "ROADMAP.md":
		return fmt.Sprintf("# %s - Roadmap\n\n## v1.0\n\n- [ ] Feature 1\n", name)
	case "CHANGELOG.md":
		return "# Changelog\n\n## [Unreleased]\n\n### Added\n- Initial setup\n"
	}
	return ""
}

func (m ProjectDetailModel) View() string {
	if m.width == 0 || m.height == 0 || m.project == nil {
		return ""
	}

	var b strings.Builder

	// Header with project info
	header := m.renderHeader()
	b.WriteString(header + "\n")

	// Tabs
	tabs := m.renderTabs()
	b.WriteString(tabs + "\n")

	// Separator
	sep := lipgloss.NewStyle().Foreground(Surface1).Render(strings.Repeat("─", m.width-4))
	b.WriteString(sep + "\n")

	// Content
	contentHeight := m.height - 10 // header, tabs, sep, padding
	content := m.renderContent(contentHeight)
	b.WriteString(content)

	return lipgloss.NewStyle().
		Width(m.width).
		Height(m.height).
		Padding(1, 2).
		Render(b.String())
}

func (m ProjectDetailModel) renderHeader() string {
	if m.project == nil {
		return ""
	}

	langIcon := LanguageIcons[m.project.Language]
	if langIcon == "" {
		langIcon = LanguageIcons["unknown"]
	}

	// Project name
	name := lipgloss.NewStyle().
		Foreground(Text).
		Bold(true).
		Render(langIcon + m.project.Name)

	// Path
	path := lipgloss.NewStyle().
		Foreground(Subtext0).
		Render(m.project.Path)

	// Branch info
	branch := BranchStyle.Render(
		Icons.Branch + m.project.GitState.ActiveBranch,
	)

	// Status pills
	var pills []string
	if m.project.GitState.Untracked > 0 {
		pills = append(pills, UntrackedStyle.Render(
			fmt.Sprintf("%d untracked", m.project.GitState.Untracked),
		))
	}
	if m.project.GitState.Staged > 0 {
		pills = append(pills, StagedStyle.Render(
			fmt.Sprintf("%d staged", m.project.GitState.Staged),
		))
	}

	pillsStr := strings.Join(pills, "  ")

	return name + "\n" + path + "  " + branch + "  " + pillsStr
}

func (m ProjectDetailModel) renderTabs() string {
	var tabs []string
	for i, tab := range m.tabs {
		style := InactiveTabStyle
		if i == m.activeTab {
			style = ActiveTabStyle
		}
		// Add number hint
		hint := lipgloss.NewStyle().Foreground(Overlay0).Render(fmt.Sprintf("%d:", i+1))
		tabs = append(tabs, hint+style.Render(tab))
	}
	return lipgloss.JoinHorizontal(lipgloss.Top, tabs...)
}

func (m ProjectDetailModel) renderContent(maxHeight int) string {
	// Simple markdown rendering with syntax highlighting
	lines := strings.Split(m.content, "\n")
	var rendered []string

	for i, line := range lines {
		if i >= maxHeight-1 {
			rendered = append(rendered, lipgloss.NewStyle().Foreground(Overlay0).Render("..."))
			break
		}
		rendered = append(rendered, m.renderMarkdownLine(line))
	}

	return strings.Join(rendered, "\n")
}

func (m ProjectDetailModel) renderMarkdownLine(line string) string {
	// Headers
	if strings.HasPrefix(line, "### ") {
		return lipgloss.NewStyle().Foreground(Mauve).Bold(true).Render(line)
	}
	if strings.HasPrefix(line, "## ") {
		return lipgloss.NewStyle().Foreground(Blue).Bold(true).Render(line)
	}
	if strings.HasPrefix(line, "# ") {
		return lipgloss.NewStyle().Foreground(Lavender).Bold(true).Render(line)
	}

	// List items
	if strings.HasPrefix(line, "- [x]") {
		return lipgloss.NewStyle().Foreground(Green).Render(
			strings.Replace(line, "- [x]", Icons.Check, 1),
		)
	}
	if strings.HasPrefix(line, "- [ ]") {
		return lipgloss.NewStyle().Foreground(Yellow).Render(
			strings.Replace(line, "- [ ]", "○", 1),
		)
	}
	if strings.HasPrefix(line, "- ") || strings.HasPrefix(line, "* ") {
		return lipgloss.NewStyle().Foreground(Teal).Render(line)
	}

	// Code blocks
	if strings.HasPrefix(line, "```") {
		return lipgloss.NewStyle().Foreground(Overlay2).Render(line)
	}

	// Default
	return lipgloss.NewStyle().Foreground(Text).Render(line)
}
