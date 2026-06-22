package ui

import (
	"strings"

	"github.com/charmbracelet/lipgloss"
)

// SidebarModel handles the left sidebar with input and recent chats
type SidebarModel struct {
	width       int
	height      int
	recentChats []RecentChat
	input       string
	unreadCount int
}

type RecentChat struct {
	Title    string
	Subtitle string
}

func NewSidebarModel() SidebarModel {
	return SidebarModel{
		recentChats: []RecentChat{},
	}
}

func (m *SidebarModel) SetSize(w, h int) {
	m.width = w
	m.height = h
}

func (m *SidebarModel) SetRecentChats(chats []RecentChat) {
	m.recentChats = chats
}

func (m *SidebarModel) SetUnreadCount(count int) {
	m.unreadCount = count
}

func (m SidebarModel) View() string {
	if m.width == 0 || m.height == 0 {
		return ""
	}

	var b strings.Builder

	// Input area
	inputBox := lipgloss.NewStyle().
		Width(m.width - 4).
		Padding(0, 1).
		Background(Surface0).
		Foreground(Subtext0).
		Render("󰭻  Chat with openclaw...")

	b.WriteString(inputBox + "\n\n")

	// Inbox button
	inboxLabel := Icons.Inbox + " Inbox"
	if m.unreadCount > 0 {
		badge := lipgloss.NewStyle().
			Background(Red).
			Foreground(Crust).
			Padding(0, 1).
			Render(string(rune('0'+m.unreadCount%10))) // Simple badge
		inboxLabel += " " + badge
	}
	inboxBtn := lipgloss.NewStyle().
		Width(m.width - 4).
		Padding(0, 1).
		Background(Surface0).
		Foreground(Blue).
		Render(inboxLabel)

	b.WriteString(inboxBtn + "\n\n")

	// Recent chats header
	header := SidebarHeaderStyle.Render("Recent Chats")
	b.WriteString(header + "\n")

	// Recent chats list
	if len(m.recentChats) == 0 {
		empty := lipgloss.NewStyle().
			Foreground(Overlay0).
			Italic(true).
			Render("No recent chats")
		b.WriteString(empty + "\n")
	} else {
		for _, chat := range m.recentChats {
			title := lipgloss.NewStyle().
				Foreground(Text).
				Width(m.width - 6).
				Render(truncate(chat.Title, m.width-8))

			subtitle := lipgloss.NewStyle().
				Foreground(Subtext0).
				Width(m.width - 6).
				Render(truncate(chat.Subtitle, m.width-8))

			chatBox := lipgloss.NewStyle().
				Width(m.width - 4).
				Padding(0, 1).
				MarginBottom(1).
				Background(Surface0).
				Render(title + "\n" + subtitle)

			b.WriteString(chatBox + "\n")
		}
	}

	return lipgloss.NewStyle().
		Width(m.width).
		Height(m.height).
		Background(Crust).
		Padding(1, 1).
		Render(b.String())
}
