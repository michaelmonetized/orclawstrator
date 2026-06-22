package ui

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/lipgloss"
	"github.com/michaelcolletti/orclawstrator/internal/scanner"
)

// DashboardModel handles the main project list view
type DashboardModel struct {
	width       int
	height      int
	projects    []scanner.Project
	selectedIdx int
	scrollOff   int
}

func NewDashboardModel() DashboardModel {
	return DashboardModel{}
}

func (m *DashboardModel) SetSize(w, h int) {
	m.width = w
	m.height = h
}

func (m *DashboardModel) SetProjects(projects []scanner.Project) {
	m.projects = projects
	m.selectedIdx = 0
	m.scrollOff = 0
}

func (m *DashboardModel) MoveUp() {
	if m.selectedIdx > 0 {
		m.selectedIdx--
		if m.selectedIdx < m.scrollOff {
			m.scrollOff = m.selectedIdx
		}
	}
}

func (m *DashboardModel) MoveDown() {
	if m.selectedIdx < len(m.projects)-1 {
		m.selectedIdx++
		visibleRows := m.height - 4 // header + padding
		if m.selectedIdx >= m.scrollOff+visibleRows {
			m.scrollOff = m.selectedIdx - visibleRows + 1
		}
	}
}

func (m *DashboardModel) SelectedProject() *scanner.Project {
	if m.selectedIdx < len(m.projects) {
		return &m.projects[m.selectedIdx]
	}
	return nil
}

func (m DashboardModel) View() string {
	if m.width == 0 || m.height == 0 {
		return ""
	}

	var b strings.Builder

	// Title
	title := lipgloss.NewStyle().
		Foreground(Text).
		Bold(true).
		Render(Icons.Dashboard + " Dashboard")
	b.WriteString(title + "\n\n")

	// Column headers
	headers := m.renderHeaders()
	b.WriteString(headers + "\n")

	// Separator
	sep := lipgloss.NewStyle().Foreground(Surface1).Render(strings.Repeat("─", m.width-4))
	b.WriteString(sep + "\n")

	// Projects
	visibleRows := m.height - 6 // header, title, separator, padding
	if visibleRows < 1 {
		visibleRows = 1
	}

	for i := m.scrollOff; i < len(m.projects) && i < m.scrollOff+visibleRows; i++ {
		row := m.renderProjectRow(i, m.projects[i])
		b.WriteString(row + "\n")
	}

	// Fill remaining space
	rendered := b.String()
	lines := strings.Count(rendered, "\n")
	for i := lines; i < m.height-2; i++ {
		b.WriteString("\n")
	}

	return lipgloss.NewStyle().
		Width(m.width).
		Height(m.height).
		Padding(1, 2).
		Render(b.String())
}

func (m DashboardModel) renderHeaders() string {
	// Calculate column widths based on available space
	w := m.width - 8 // padding

	warnW := 3
	nameW := max(20, w/4)
	agentW := max(15, w/5)
	branchW := max(15, w/5)
	stackW := 10
	changesW := w - warnW - nameW - agentW - branchW - stackW

	warn := lipgloss.NewStyle().Width(warnW).Render("")
	name := TableHeaderStyle.Width(nameW).Render("PROJECT")
	agent := TableHeaderStyle.Width(agentW).Render("AGENT")
	branch := TableHeaderStyle.Width(branchW).Render("BRANCH")
	stack := TableHeaderStyle.Width(stackW).Render("STACKS")
	changes := TableHeaderStyle.Width(changesW).Render("CHANGES")

	return warn + name + agent + branch + stack + changes
}

func (m DashboardModel) renderProjectRow(idx int, p scanner.Project) string {
	w := m.width - 8

	warnW := 3
	nameW := max(20, w/4)
	agentW := max(15, w/5)
	branchW := max(15, w/5)
	stackW := 10
	changesW := w - warnW - nameW - agentW - branchW - stackW

	// Base style
	style := TableRowStyle
	if idx == m.selectedIdx {
		style = TableRowSelectedStyle
	}

	// Warning indicator
	var warn string
	if p.HasWarning {
		warn = WarningStyle.Width(warnW).Render(Icons.Warning)
	} else {
		warn = lipgloss.NewStyle().Width(warnW).Render(" ")
	}

	// Language icon + name
	langIcon := LanguageIcons[p.Language]
	if langIcon == "" {
		langIcon = LanguageIcons["unknown"]
	}
	name := style.Width(nameW).Render(langIcon + truncate(p.Name, nameW-4))

	// Agent
	var agent string
	if p.Agent != "" {
		agent = AgentNameStyle.Width(agentW).Render(Icons.Agent + truncate(p.Agent, agentW-4))
	} else {
		agent = AgentIdleStyle.Width(agentW).Render("—")
	}

	// Branch
	branchStr := BranchStyle.Render(Icons.Branch) +
		lipgloss.NewStyle().Foreground(Green).Bold(true).Render(fmt.Sprintf("%02d", p.GitState.BranchCount)) +
		" " + Subtext1Style().Render(truncate(p.GitState.ActiveBranch, branchW-8))
	branch := lipgloss.NewStyle().Width(branchW).Render(branchStr)

	// Stacks
	stackStr := StackStyle.Render(Icons.Stack) +
		lipgloss.NewStyle().Foreground(Blue).Bold(true).Render(fmt.Sprintf("%02d", p.StackCount))
	stack := lipgloss.NewStyle().Width(stackW).Render(stackStr)

	// Changes
	var changesStr string
	if p.GitState.Untracked > 0 {
		changesStr += UntrackedStyle.Render(fmt.Sprintf("%s%02d ", Icons.Untracked, p.GitState.Untracked))
	}
	if p.GitState.Staged > 0 {
		changesStr += StagedStyle.Render(fmt.Sprintf("%s%02d", Icons.Staged, p.GitState.Staged))
	}
	if changesStr == "" {
		changesStr = lipgloss.NewStyle().Foreground(Overlay0).Render("clean")
	}
	changes := lipgloss.NewStyle().Width(changesW).Render(changesStr)

	row := warn + name + agent + branch + stack + changes

	// Apply row background for selected
	if idx == m.selectedIdx {
		row = lipgloss.NewStyle().
			Background(Surface1).
			Width(m.width - 4).
			Render(row)
	}

	return row
}

func Subtext1Style() lipgloss.Style {
	return lipgloss.NewStyle().Foreground(Subtext1)
}

func truncate(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	if maxLen <= 3 {
		return s[:maxLen]
	}
	return s[:maxLen-1] + "…"
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}
