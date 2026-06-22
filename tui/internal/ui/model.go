package ui

import (
	"fmt"

	"github.com/charmbracelet/bubbles/key"
	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/michaelcolletti/orclawstrator/internal/db"
	"github.com/michaelcolletti/orclawstrator/internal/scanner"
)

// View represents the current view state
type View int

const (
	DashboardView View = iota
	ProjectDetailView
	InboxView
)

// Focus represents which panel has focus
type Focus int

const (
	FocusSidebar Focus = iota
	FocusMain
)

// Model is the main application model
type Model struct {
	// Dimensions
	width  int
	height int

	// State
	currentView    View
	focus          Focus
	selectedRow    int
	loading        bool
	err            error

	// Data
	projects       []scanner.Project
	selectedProject *scanner.Project
	agentStats     AgentStats

	// Components
	spinner        spinner.Model
	dashboard      DashboardModel
	sidebar        SidebarModel
	projectDetail  ProjectDetailModel

	// Services
	database       *db.Database
	projectScanner *scanner.Scanner

	// Key bindings
	keys           KeyMap
}

type AgentStats struct {
	ActiveAgents int
	Subagents    int
	IdleAgents   int
	TokensUsed   int
	TokenLimit   int
}

// KeyMap defines all key bindings
type KeyMap struct {
	Up       key.Binding
	Down     key.Binding
	Left     key.Binding
	Right    key.Binding
	Enter    key.Binding
	Back     key.Binding
	Tab      key.Binding
	Refresh  key.Binding
	Search   key.Binding
	Inbox    key.Binding
	Help     key.Binding
	Quit     key.Binding
	Numbers  []key.Binding
}

func DefaultKeyMap() KeyMap {
	return KeyMap{
		Up: key.NewBinding(
			key.WithKeys("up", "k"),
			key.WithHelp("↑/k", "up"),
		),
		Down: key.NewBinding(
			key.WithKeys("down", "j"),
			key.WithHelp("↓/j", "down"),
		),
		Left: key.NewBinding(
			key.WithKeys("left", "h"),
			key.WithHelp("←/h", "left"),
		),
		Right: key.NewBinding(
			key.WithKeys("right", "l"),
			key.WithHelp("→/l", "right"),
		),
		Enter: key.NewBinding(
			key.WithKeys("enter"),
			key.WithHelp("enter", "select"),
		),
		Back: key.NewBinding(
			key.WithKeys("esc", "backspace"),
			key.WithHelp("esc", "back"),
		),
		Tab: key.NewBinding(
			key.WithKeys("tab"),
			key.WithHelp("tab", "switch focus"),
		),
		Refresh: key.NewBinding(
			key.WithKeys("r", "ctrl+r"),
			key.WithHelp("r", "refresh"),
		),
		Search: key.NewBinding(
			key.WithKeys("/", "ctrl+k"),
			key.WithHelp("/", "search"),
		),
		Inbox: key.NewBinding(
			key.WithKeys("i"),
			key.WithHelp("i", "inbox"),
		),
		Help: key.NewBinding(
			key.WithKeys("?"),
			key.WithHelp("?", "help"),
		),
		Quit: key.NewBinding(
			key.WithKeys("q", "ctrl+c"),
			key.WithHelp("q", "quit"),
		),
	}
}

// NewModel creates a new application model
func NewModel() Model {
	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = lipgloss.NewStyle().Foreground(Mauve)

	database, _ := db.New()
	projectScanner := scanner.New()

	return Model{
		spinner:        s,
		loading:        true,
		keys:           DefaultKeyMap(),
		database:       database,
		projectScanner: projectScanner,
		dashboard:      NewDashboardModel(),
		sidebar:        NewSidebarModel(),
		projectDetail:  NewProjectDetailModel(),
		focus:          FocusMain,
	}
}

// Init implements tea.Model
func (m Model) Init() tea.Cmd {
	return tea.Batch(
		m.spinner.Tick,
		m.loadProjects,
		tea.EnterAltScreen,
	)
}

// loadProjects returns a command that loads projects
func (m Model) loadProjects() tea.Msg {
	projects, err := m.projectScanner.ScanProjects("~/Projects")
	if err != nil {
		return errMsg{err}
	}
	return projectsLoadedMsg{projects}
}

// Messages
type projectsLoadedMsg struct {
	projects []scanner.Project
}

type errMsg struct {
	err error
}

// Update implements tea.Model
func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmds []tea.Cmd

	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		m.dashboard.SetSize(m.mainWidth(), m.mainHeight())
		m.sidebar.SetSize(m.sidebarWidth(), m.height-2) // -2 for status bars
		m.projectDetail.SetSize(m.mainWidth(), m.mainHeight())

	case tea.KeyMsg:
		switch {
		case key.Matches(msg, m.keys.Quit):
			return m, tea.Quit

		case key.Matches(msg, m.keys.Back):
			if m.currentView != DashboardView {
				m.currentView = DashboardView
				m.selectedProject = nil
			}

		case key.Matches(msg, m.keys.Tab):
			if m.focus == FocusSidebar {
				m.focus = FocusMain
			} else {
				m.focus = FocusSidebar
			}

		case key.Matches(msg, m.keys.Up):
			if m.focus == FocusMain && m.currentView == DashboardView {
				m.dashboard.MoveUp()
			}

		case key.Matches(msg, m.keys.Down):
			if m.focus == FocusMain && m.currentView == DashboardView {
				m.dashboard.MoveDown()
			}

		case key.Matches(msg, m.keys.Enter):
			if m.focus == FocusMain && m.currentView == DashboardView {
				if p := m.dashboard.SelectedProject(); p != nil {
					m.selectedProject = p
					m.currentView = ProjectDetailView
					m.projectDetail.SetProject(p)
				}
			}

		case key.Matches(msg, m.keys.Refresh):
			m.loading = true
			cmds = append(cmds, m.loadProjects)

		case key.Matches(msg, m.keys.Inbox):
			m.currentView = InboxView

		// Number keys 1-9 for quick project access
		case msg.String() >= "1" && msg.String() <= "9":
			idx := int(msg.String()[0] - '1')
			if idx < len(m.projects) {
				m.selectedProject = &m.projects[idx]
				m.currentView = ProjectDetailView
				m.projectDetail.SetProject(m.selectedProject)
			}
		}

		// Forward to current view
		switch m.currentView {
		case ProjectDetailView:
			var cmd tea.Cmd
			m.projectDetail, cmd = m.projectDetail.Update(msg)
			cmds = append(cmds, cmd)
		}

	case projectsLoadedMsg:
		m.loading = false
		m.projects = msg.projects
		m.dashboard.SetProjects(msg.projects)
		// Save to cache
		if m.database != nil {
			for _, p := range msg.projects {
				m.database.SaveProject(p)
			}
		}

	case errMsg:
		m.loading = false
		m.err = msg.err

	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(msg)
		cmds = append(cmds, cmd)
	}

	return m, tea.Batch(cmds...)
}

// View implements tea.Model
func (m Model) View() string {
	if m.width == 0 || m.height == 0 {
		return "Initializing..."
	}

	// Top status bar
	topBar := m.renderTopBar()

	// Main content area (sidebar + main view)
	sidebar := m.sidebar.View()

	var mainContent string
	switch m.currentView {
	case DashboardView:
		mainContent = m.dashboard.View()
	case ProjectDetailView:
		mainContent = m.projectDetail.View()
	case InboxView:
		mainContent = m.renderInbox()
	}

	// Apply focus styling
	if m.focus == FocusSidebar {
		sidebar = FocusedBorderStyle.Render(sidebar)
		mainContent = BorderStyle.Render(mainContent)
	} else {
		sidebar = BorderStyle.Render(sidebar)
		mainContent = FocusedBorderStyle.Render(mainContent)
	}

	content := lipgloss.JoinHorizontal(lipgloss.Top, sidebar, mainContent)

	// Bottom status bar
	bottomBar := m.renderBottomBar()

	return lipgloss.JoinVertical(lipgloss.Left, topBar, content, bottomBar)
}

func (m Model) renderTopBar() string {
	title := Icons.Dashboard + " Orclawstrator"

	// Agent stats
	agentInfo := lipgloss.NewStyle().Foreground(Teal).Render(
		Icons.Agent + fmt.Sprintf("%d active", m.agentStats.ActiveAgents),
	)

	// Token usage
	tokenInfo := lipgloss.NewStyle().Foreground(Peach).Render(
		fmt.Sprintf("󰆧 %dk/%dk", m.agentStats.TokensUsed/1000, m.agentStats.TokenLimit/1000),
	)

	left := TopBarStyle.Render(title)
	right := TopBarStyle.Render(agentInfo + "  " + tokenInfo)

	gap := m.width - lipgloss.Width(left) - lipgloss.Width(right)
	if gap < 0 {
		gap = 0
	}

	return left + lipgloss.NewStyle().Width(gap).Render("") + right
}

func (m Model) renderBottomBar() string {
	var help string
	switch m.currentView {
	case DashboardView:
		help = HelpKeyStyle.Render("j/k") + HelpDescStyle.Render(" nav  ") +
			HelpKeyStyle.Render("enter") + HelpDescStyle.Render(" open  ") +
			HelpKeyStyle.Render("r") + HelpDescStyle.Render(" refresh  ") +
			HelpKeyStyle.Render("i") + HelpDescStyle.Render(" inbox  ") +
			HelpKeyStyle.Render("q") + HelpDescStyle.Render(" quit")
	case ProjectDetailView:
		help = HelpKeyStyle.Render("tab") + HelpDescStyle.Render(" switch  ") +
			HelpKeyStyle.Render("1-4") + HelpDescStyle.Render(" tabs  ") +
			HelpKeyStyle.Render("e") + HelpDescStyle.Render(" edit  ") +
			HelpKeyStyle.Render("esc") + HelpDescStyle.Render(" back  ") +
			HelpKeyStyle.Render("q") + HelpDescStyle.Render(" quit")
	default:
		help = HelpKeyStyle.Render("esc") + HelpDescStyle.Render(" back  ") +
			HelpKeyStyle.Render("q") + HelpDescStyle.Render(" quit")
	}

	if m.loading {
		help = m.spinner.View() + " Loading..." + "  " + help
	}

	return StatusBarStyle.Width(m.width).Render(help)
}

func (m Model) renderInbox() string {
	return lipgloss.NewStyle().
		Width(m.mainWidth()).
		Height(m.mainHeight()).
		Padding(1, 2).
		Render(Icons.Inbox + " Inbox\n\nNo new messages")
}

// Layout helpers
func (m Model) sidebarWidth() int {
	return min(30, m.width/4)
}

func (m Model) mainWidth() int {
	return m.width - m.sidebarWidth() - 4 // borders
}

func (m Model) mainHeight() int {
	return m.height - 4 // top bar + bottom bar + borders
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
