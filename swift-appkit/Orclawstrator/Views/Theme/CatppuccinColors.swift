import Cocoa

// MARK: - Catppuccin Mocha Color Palette (from mockup)
struct Catppuccin {
    // Base colors (Mocha)
    static let base = NSColor(hex: "#1e1e2e")!
    static let mantle = NSColor(hex: "#181825")!
    static let crust = NSColor(hex: "#11111b")!
    static let surface0 = NSColor(hex: "#313244")!
    static let surface1 = NSColor(hex: "#45475a")!
    static let surface2 = NSColor(hex: "#585b70")!
    static let overlay0 = NSColor(hex: "#6c7086")!
    static let overlay1 = NSColor(hex: "#7f849c")!
    static let overlay2 = NSColor(hex: "#9399b2")!
    
    // Text colors
    static let text = NSColor(hex: "#cdd6f4")!
    static let subtext0 = NSColor(hex: "#a6adc8")!
    static let subtext1 = NSColor(hex: "#bac2de")!
    
    // Accent colors
    static let rosewater = NSColor(hex: "#f5e0dc")!
    static let flamingo = NSColor(hex: "#f2cdcd")!
    static let pink = NSColor(hex: "#f5c2e7")!
    static let mauve = NSColor(hex: "#cba6f7")!
    static let red = NSColor(hex: "#f38ba8")!
    static let maroon = NSColor(hex: "#eba0ac")!
    static let peach = NSColor(hex: "#fab387")!
    static let yellow = NSColor(hex: "#f9e2af")!
    static let green = NSColor(hex: "#a6e3a1")!
    static let teal = NSColor(hex: "#94e2d5")!
    static let sky = NSColor(hex: "#89dceb")!
    static let sapphire = NSColor(hex: "#74c7ec")!
    static let blue = NSColor(hex: "#89b4fa")!
    static let lavender = NSColor(hex: "#b4befe")!
    
    // Semi-transparent variants for backgrounds
    static var baseTransparent: NSColor { base.withAlphaComponent(0.85) }
    static var mantleTransparent: NSColor { mantle.withAlphaComponent(0.85) }
    static var crustTransparent: NSColor { crust.withAlphaComponent(0.90) }
    static var surface0Transparent: NSColor { surface0.withAlphaComponent(0.75) }
}

// MARK: - NSColor Hex Extension
extension NSColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
    
    var cgColorSafe: CGColor {
        return self.cgColor
    }
}
