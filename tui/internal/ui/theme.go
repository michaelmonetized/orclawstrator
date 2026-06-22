package ui

import "github.com/charmbracelet/lipgloss"

// Catppuccin Macchiato palette
var (
	Rosewater = lipgloss.Color("#f4dbd6")
	Flamingo  = lipgloss.Color("#f0c6c6")
	Pink      = lipgloss.Color("#f5bde6")
	Mauve     = lipgloss.Color("#c6a0f6")
	Red       = lipgloss.Color("#ed8796")
	Maroon    = lipgloss.Color("#ee99a0")
	Peach     = lipgloss.Color("#f5a97f")
	Yellow    = lipgloss.Color("#eed49f")
	Green     = lipgloss.Color("#a6da95")
	Teal      = lipgloss.Color("#8bd5ca")
	Sky       = lipgloss.Color("#91d7e3")
	Sapphire  = lipgloss.Color("#7dc4e4")
	Blue      = lipgloss.Color("#8aadf4")
	Lavender  = lipgloss.Color("#b7bdf8")
	Text      = lipgloss.Color("#cad3f5")
	Subtext1  = lipgloss.Color("#b8c0e0")
	Subtext0  = lipgloss.Color("#a5adcb")
	Overlay2  = lipgloss.Color("#939ab7")
	Overlay1  = lipgloss.Color("#8087a2")
	Overlay0  = lipgloss.Color("#6e738d")
	Surface2  = lipgloss.Color("#5b6078")
	Surface1  = lipgloss.Color("#494d64")
	Surface0  = lipgloss.Color("#363a4f")
	Base      = lipgloss.Color("#24273a")
	Mantle    = lipgloss.Color("#1e2030")
	Crust     = lipgloss.Color("#181926")
)

// Nerdfont icons for languages
var LanguageIcons = map[string]string{
	"swift":      " ",
	"rust":       " ",
	"go":         " ",
	"python":     " ",
	"javascript": " ",
	"typescript": " ",
	"ruby":       " ",
	"c":          " ",
	"cpp":        " ",
	"java":       " ",
	"lua":        " ",
	"shell":      " ",
	"terminal":   " ",
	"unknown":    " ",
}

// UI icons
var Icons = struct {
	Branch     string
	Stack      string
	Untracked  string
	Staged     string
	Warning    string
	Check      string
	Error      string
	Folder     string
	Terminal   string
	Agent      string
	Inbox      string
	Dashboard  string
	Settings   string
	Refresh    string
	Search     string
	ArrowRight string
	ArrowLeft  string
	ArrowUp    string
	ArrowDown  string
	Spinner    []string
}{
	Branch:     " ",
	Stack:      "󰜮 ",
	Untracked:  " ",
	Staged:     " ",
	Warning:    " ",
	Check:      " ",
	Error:      " ",
	Folder:     " ",
	Terminal:   " ",
	Agent:      "󰚩 ",
	Inbox:      "󰇮 ",
	Dashboard:  "󰕮 ",
	Settings:   " ",
	Refresh:    "󰑓 ",
	Search:     " ",
	ArrowRight: "",
	ArrowLeft:  "",
	ArrowUp:    "",
	ArrowDown:  "",
	Spinner:    []string{"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"},
}

// Common styles
var (
	// Base styles
	BaseStyle = lipgloss.NewStyle().
			Background(Base).
			Foreground(Text)

	// Status bar
	StatusBarStyle = lipgloss.NewStyle().
			Background(Surface0).
			Foreground(Subtext1).
			Padding(0, 1)

	TopBarStyle = lipgloss.NewStyle().
			Background(Mantle).
			Foreground(Text).
			Padding(0, 1).
			Bold(true)

	// Sidebar
	SidebarStyle = lipgloss.NewStyle().
			Background(Crust).
			Foreground(Text).
			Padding(1, 2)

	SidebarHeaderStyle = lipgloss.NewStyle().
				Foreground(Mauve).
				Bold(true).
				MarginBottom(1)

	// Dashboard
	TableHeaderStyle = lipgloss.NewStyle().
				Foreground(Subtext0).
				Bold(true)

	TableRowStyle = lipgloss.NewStyle().
			Background(Surface0).
			Foreground(Text).
			Padding(0, 1)

	TableRowSelectedStyle = lipgloss.NewStyle().
				Background(Surface1).
				Foreground(Text).
				Bold(true).
				Padding(0, 1)

	// Project info
	ProjectNameStyle = lipgloss.NewStyle().
				Foreground(Text).
				Bold(true)

	BranchStyle = lipgloss.NewStyle().
			Foreground(Green)

	StackStyle = lipgloss.NewStyle().
			Foreground(Blue)

	UntrackedStyle = lipgloss.NewStyle().
			Foreground(Red)

	StagedStyle = lipgloss.NewStyle().
			Foreground(Green)

	WarningStyle = lipgloss.NewStyle().
			Foreground(Yellow)

	// Tabs
	ActiveTabStyle = lipgloss.NewStyle().
			Background(Surface1).
			Foreground(Mauve).
			Bold(true).
			Padding(0, 2)

	InactiveTabStyle = lipgloss.NewStyle().
				Background(Surface0).
				Foreground(Subtext0).
				Padding(0, 2)

	// Agent styles
	AgentNameStyle = lipgloss.NewStyle().
			Foreground(Teal)

	AgentActiveStyle = lipgloss.NewStyle().
				Foreground(Green).
				Bold(true)

	AgentIdleStyle = lipgloss.NewStyle().
			Foreground(Overlay0)

	// Help
	HelpKeyStyle = lipgloss.NewStyle().
			Foreground(Mauve).
			Bold(true)

	HelpDescStyle = lipgloss.NewStyle().
			Foreground(Subtext0)

	// Borders
	BorderStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(Surface1)

	FocusedBorderStyle = lipgloss.NewStyle().
				Border(lipgloss.RoundedBorder()).
				BorderForeground(Mauve)
)
