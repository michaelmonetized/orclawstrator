package db

import (
	"database/sql"
	"os"
	"path/filepath"
	"time"

	_ "github.com/mattn/go-sqlite3"
	"github.com/michaelcolletti/orclawstrator/internal/scanner"
)

// Database handles SQLite operations
// Reuses the same database as the Swift AppKit version at ~/.orclawstrator/cache.db
type Database struct {
	db *sql.DB
}

// New creates a new database connection
func New() (*Database, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return nil, err
	}

	dbDir := filepath.Join(homeDir, ".orclawstrator")
	if err := os.MkdirAll(dbDir, 0755); err != nil {
		return nil, err
	}

	dbPath := filepath.Join(dbDir, "cache.db")
	db, err := sql.Open("sqlite3", dbPath)
	if err != nil {
		return nil, err
	}

	d := &Database{db: db}
	if err := d.createTables(); err != nil {
		return nil, err
	}

	return d, nil
}

func (d *Database) createTables() error {
	tables := []string{
		`CREATE TABLE IF NOT EXISTS projects (
			id TEXT PRIMARY KEY,
			name TEXT NOT NULL,
			path TEXT NOT NULL UNIQUE,
			language TEXT,
			last_scanned INTEGER,
			is_favorite INTEGER DEFAULT 0,
			notes TEXT
		)`,
		`CREATE TABLE IF NOT EXISTS sessions (
			id TEXT PRIMARY KEY,
			project_id TEXT,
			label TEXT,
			model TEXT,
			status TEXT,
			tokens_used INTEGER DEFAULT 0,
			created_at INTEGER,
			updated_at INTEGER,
			FOREIGN KEY (project_id) REFERENCES projects(id)
		)`,
		`CREATE TABLE IF NOT EXISTS messages (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			session_id TEXT,
			type TEXT,
			content TEXT,
			timestamp INTEGER,
			read INTEGER DEFAULT 0,
			FOREIGN KEY (session_id) REFERENCES sessions(id)
		)`,
		`CREATE TABLE IF NOT EXISTS settings (
			key TEXT PRIMARY KEY,
			value TEXT
		)`,
		`CREATE TABLE IF NOT EXISTS recent_chats (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			title TEXT NOT NULL,
			subtitle TEXT,
			project_path TEXT,
			created_at INTEGER,
			updated_at INTEGER
		)`,
	}

	for _, table := range tables {
		if _, err := d.db.Exec(table); err != nil {
			return err
		}
	}

	return nil
}

// SaveProject saves or updates a project in the database
func (d *Database) SaveProject(p scanner.Project) error {
	_, err := d.db.Exec(`
		INSERT OR REPLACE INTO projects (id, name, path, language, last_scanned)
		VALUES (?, ?, ?, ?, ?)
	`, p.ID, p.Name, p.Path, p.Language, time.Now().Unix())
	return err
}

// GetCachedProjects returns all cached projects for instant display
func (d *Database) GetCachedProjects() ([]scanner.Project, error) {
	rows, err := d.db.Query(`
		SELECT name, path, language FROM projects ORDER BY name ASC
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var projects []scanner.Project
	for rows.Next() {
		var p scanner.Project
		var lang sql.NullString
		if err := rows.Scan(&p.Name, &p.Path, &lang); err != nil {
			continue
		}
		if lang.Valid {
			p.Language = lang.String
		}
		projects = append(projects, p)
	}

	return projects, nil
}

// GetUnreadMessageCount returns the number of unread messages
func (d *Database) GetUnreadMessageCount() (int, error) {
	var count int
	err := d.db.QueryRow(`SELECT COUNT(*) FROM messages WHERE read = 0`).Scan(&count)
	return count, err
}

// GetRecentChats returns recent chat entries
func (d *Database) GetRecentChats(limit int) ([]RecentChat, error) {
	rows, err := d.db.Query(`
		SELECT title, subtitle FROM recent_chats
		ORDER BY updated_at DESC LIMIT ?
	`, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var chats []RecentChat
	for rows.Next() {
		var c RecentChat
		var subtitle sql.NullString
		if err := rows.Scan(&c.Title, &subtitle); err != nil {
			continue
		}
		if subtitle.Valid {
			c.Subtitle = subtitle.String
		}
		chats = append(chats, c)
	}

	return chats, nil
}

// RecentChat represents a recent chat entry
type RecentChat struct {
	Title    string
	Subtitle string
}

// GetSetting retrieves a setting value
func (d *Database) GetSetting(key string) (string, error) {
	var value string
	err := d.db.QueryRow(`SELECT value FROM settings WHERE key = ?`, key).Scan(&value)
	if err == sql.ErrNoRows {
		return "", nil
	}
	return value, err
}

// SetSetting saves a setting value
func (d *Database) SetSetting(key, value string) error {
	_, err := d.db.Exec(`
		INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)
	`, key, value)
	return err
}

// Close closes the database connection
func (d *Database) Close() error {
	return d.db.Close()
}
