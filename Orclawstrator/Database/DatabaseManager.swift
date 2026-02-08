import Foundation
import SQLite3

/// SQLite database manager for local state persistence
/// Stores database in ~/.orclawstrator/cache.db (survives builds)
class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private var db: OpaquePointer?
    private let dbPath: String
    
    // MARK: - Initialization
    
    private init() {
        // Store database in ~/.orclawstrator/ (not wiped on build)
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let appFolder = homeDir.appendingPathComponent(".orclawstrator")
        
        // Create folder if needed
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        
        dbPath = appFolder.appendingPathComponent("cache.db").path
        print("[DB] Using database at: \(dbPath)")
        openDatabase()
        createTables()
    }
    
    deinit {
        closeDatabase()
    }
    
    // MARK: - Database Operations
    
    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("[DB] Error opening database: \(String(cString: sqlite3_errmsg(db)))")
        } else {
            print("[DB] Database opened successfully")
        }
    }
    
    private func closeDatabase() {
        if db != nil {
            sqlite3_close(db)
            db = nil
        }
    }
    
    private func createTables() {
        let tables = [
            """
            CREATE TABLE IF NOT EXISTS projects (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                path TEXT NOT NULL UNIQUE,
                language TEXT,
                last_scanned INTEGER,
                is_favorite INTEGER DEFAULT 0,
                notes TEXT
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS sessions (
                id TEXT PRIMARY KEY,
                project_id TEXT,
                label TEXT,
                model TEXT,
                status TEXT,
                tokens_used INTEGER DEFAULT 0,
                created_at INTEGER,
                updated_at INTEGER,
                FOREIGN KEY (project_id) REFERENCES projects(id)
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id TEXT,
                type TEXT,
                content TEXT,
                timestamp INTEGER,
                read INTEGER DEFAULT 0,
                FOREIGN KEY (session_id) REFERENCES sessions(id)
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT
            )
            """,
            """
            CREATE TABLE IF NOT EXISTS recent_chats (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                subtitle TEXT,
                project_path TEXT,
                created_at INTEGER,
                updated_at INTEGER
            )
            """
        ]
        
        for sql in tables {
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
                if sqlite3_step(statement) != SQLITE_DONE {
                    print("[DB] Error creating table: \(String(cString: sqlite3_errmsg(db)))")
                }
            }
            sqlite3_finalize(statement)
        }
    }
    
    // MARK: - Projects
    
    func saveProject(_ project: Project) {
        let sql = """
            INSERT OR REPLACE INTO projects (id, name, path, language, last_scanned)
            VALUES (?, ?, ?, ?, ?)
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, project.id.uuidString, -1, nil)
            sqlite3_bind_text(statement, 2, project.name, -1, nil)
            sqlite3_bind_text(statement, 3, project.path, -1, nil)
            sqlite3_bind_text(statement, 4, project.language.rawValue, -1, nil)
            sqlite3_bind_int64(statement, 5, Int64(Date().timeIntervalSince1970))
            
            if sqlite3_step(statement) != SQLITE_DONE {
                print("[DB] Error saving project: \(String(cString: sqlite3_errmsg(db)))")
            }
        }
        sqlite3_finalize(statement)
    }
    
    func getAllProjects() -> [(id: String, name: String, path: String, language: String?)] {
        let sql = "SELECT id, name, path, language FROM projects ORDER BY last_scanned DESC"
        var results: [(String, String, String, String?)] = []
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let name = String(cString: sqlite3_column_text(statement, 1))
                let path = String(cString: sqlite3_column_text(statement, 2))
                var language: String?
                if let langPtr = sqlite3_column_text(statement, 3) {
                    language = String(cString: langPtr)
                }
                results.append((id, name, path, language))
            }
        }
        sqlite3_finalize(statement)
        return results
    }
    
    func getProject(byPath path: String) -> (id: String, isFavorite: Bool, notes: String?)? {
        let sql = "SELECT id, is_favorite, notes FROM projects WHERE path = ?"
        
        var statement: OpaquePointer?
        var result: (String, Bool, String?)?
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, path, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let isFavorite = sqlite3_column_int(statement, 1) != 0
                var notes: String?
                if let notesPtr = sqlite3_column_text(statement, 2) {
                    notes = String(cString: notesPtr)
                }
                result = (id, isFavorite, notes)
            }
        }
        sqlite3_finalize(statement)
        return result
    }
    
    func setFavorite(projectPath: String, isFavorite: Bool) {
        let sql = "UPDATE projects SET is_favorite = ? WHERE path = ?"
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, isFavorite ? 1 : 0)
            sqlite3_bind_text(statement, 2, projectPath, -1, nil)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    func getFavoriteProjects() -> [String] {
        let sql = "SELECT path FROM projects WHERE is_favorite = 1"
        var paths: [String] = []
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                if let pathPtr = sqlite3_column_text(statement, 0) {
                    paths.append(String(cString: pathPtr))
                }
            }
        }
        sqlite3_finalize(statement)
        return paths
    }
    
    // MARK: - Sessions
    
    func saveSession(_ session: OpenClawService.SessionInfo, projectId: String? = nil) {
        let sql = """
            INSERT OR REPLACE INTO sessions (id, project_id, label, model, status, tokens_used, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, session.id, -1, nil)
            if let pid = projectId {
                sqlite3_bind_text(statement, 2, pid, -1, nil)
            } else {
                sqlite3_bind_null(statement, 2)
            }
            if let label = session.label {
                sqlite3_bind_text(statement, 3, label, -1, nil)
            } else {
                sqlite3_bind_null(statement, 3)
            }
            if let model = session.model {
                sqlite3_bind_text(statement, 4, model, -1, nil)
            } else {
                sqlite3_bind_null(statement, 4)
            }
            sqlite3_bind_text(statement, 5, session.status, -1, nil)
            sqlite3_bind_int(statement, 6, Int32(session.tokensUsed ?? 0))
            sqlite3_bind_int64(statement, 7, Int64(Date().timeIntervalSince1970))
            
            if sqlite3_step(statement) != SQLITE_DONE {
                print("[DB] Error saving session: \(String(cString: sqlite3_errmsg(db)))")
            }
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: - Messages
    
    func saveMessage(sessionId: String, type: String, content: String) {
        let sql = """
            INSERT INTO messages (session_id, type, content, timestamp)
            VALUES (?, ?, ?, ?)
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, sessionId, -1, nil)
            sqlite3_bind_text(statement, 2, type, -1, nil)
            sqlite3_bind_text(statement, 3, content, -1, nil)
            sqlite3_bind_int64(statement, 4, Int64(Date().timeIntervalSince1970))
            
            if sqlite3_step(statement) != SQLITE_DONE {
                print("[DB] Error saving message: \(String(cString: sqlite3_errmsg(db)))")
            }
        }
        sqlite3_finalize(statement)
    }
    
    func getUnreadMessageCount() -> Int {
        let sql = "SELECT COUNT(*) FROM messages WHERE read = 0"
        var count = 0
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                count = Int(sqlite3_column_int(statement, 0))
            }
        }
        sqlite3_finalize(statement)
        return count
    }
    
    func markMessagesAsRead(sessionId: String) {
        let sql = "UPDATE messages SET read = 1 WHERE session_id = ?"
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, sessionId, -1, nil)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: - Recent Chats
    
    func saveRecentChat(title: String, subtitle: String?, projectPath: String?) {
        let sql = """
            INSERT INTO recent_chats (title, subtitle, project_path, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?)
        """
        
        let now = Int64(Date().timeIntervalSince1970)
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, title, -1, nil)
            if let sub = subtitle {
                sqlite3_bind_text(statement, 2, sub, -1, nil)
            } else {
                sqlite3_bind_null(statement, 2)
            }
            if let path = projectPath {
                sqlite3_bind_text(statement, 3, path, -1, nil)
            } else {
                sqlite3_bind_null(statement, 3)
            }
            sqlite3_bind_int64(statement, 4, now)
            sqlite3_bind_int64(statement, 5, now)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    func getRecentChats(limit: Int = 10) -> [(title: String, subtitle: String?)] {
        let sql = "SELECT title, subtitle FROM recent_chats ORDER BY updated_at DESC LIMIT ?"
        var results: [(String, String?)] = []
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(limit))
            while sqlite3_step(statement) == SQLITE_ROW {
                let title = String(cString: sqlite3_column_text(statement, 0))
                var subtitle: String?
                if let subPtr = sqlite3_column_text(statement, 1) {
                    subtitle = String(cString: subPtr)
                }
                results.append((title, subtitle))
            }
        }
        sqlite3_finalize(statement)
        return results
    }
    
    // MARK: - Settings
    
    func setSetting(key: String, value: String) {
        let sql = "INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)"
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, key, -1, nil)
            sqlite3_bind_text(statement, 2, value, -1, nil)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    func getSetting(key: String) -> String? {
        let sql = "SELECT value FROM settings WHERE key = ?"
        var value: String?
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, key, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_ROW {
                if let valuePtr = sqlite3_column_text(statement, 0) {
                    value = String(cString: valuePtr)
                }
            }
        }
        sqlite3_finalize(statement)
        return value
    }
    
    // MARK: - Maintenance
    
    func vacuum() {
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, "VACUUM", -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    func deleteOldMessages(olderThanDays days: Int) {
        let cutoff = Int64(Date().timeIntervalSince1970) - Int64(days * 86400)
        let sql = "DELETE FROM messages WHERE timestamp < ?"
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int64(statement, 1, cutoff)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
}
