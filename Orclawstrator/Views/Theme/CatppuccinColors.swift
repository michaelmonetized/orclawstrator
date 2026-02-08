import Cocoa

// MARK: - Catppuccin Macchiato Color Palette
struct Catppuccin {
    // Base colors
    static let base = NSColor(hex: "#24273a")!
    static let mantle = NSColor(hex: "#1e2030")!
    static let crust = NSColor(hex: "#181926")!
    static let surface0 = NSColor(hex: "#363a4f")!
    static let surface1 = NSColor(hex: "#494d64")!
    static let surface2 = NSColor(hex: "#5b6078")!
    static let overlay0 = NSColor(hex: "#6e738d")!
    static let overlay1 = NSColor(hex: "#8087a2")!
    static let overlay2 = NSColor(hex: "#939ab7")!
    
    // Text colors
    static let text = NSColor(hex: "#cad3f5")!
    static let subtext0 = NSColor(hex: "#a5adcb")!
    static let subtext1 = NSColor(hex: "#b8c0e0")!
    
    // Accent colors
    static let rosewater = NSColor(hex: "#f4dbd6")!
    static let flamingo = NSColor(hex: "#f0c6c6")!
    static let pink = NSColor(hex: "#f5bde6")!
    static let mauve = NSColor(hex: "#c6a0f6")!
    static let red = NSColor(hex: "#ed8796")!
    static let maroon = NSColor(hex: "#ee99a0")!
    static let peach = NSColor(hex: "#f5a97f")!
    static let yellow = NSColor(hex: "#eed49f")!
    static let green = NSColor(hex: "#a6da95")!
    static let teal = NSColor(hex: "#8bd5ca")!
    static let sky = NSColor(hex: "#91d7e3")!
    static let sapphire = NSColor(hex: "#7dc4e4")!
    static let blue = NSColor(hex: "#8aadf4")!
    static let lavender = NSColor(hex: "#b7bdf8")!
    
    // Gradient colors for background
    static let gradientTop = NSColor(hex: "#1a1b26")!
    static let gradientMid = NSColor(hex: "#1e1e2e")!
    static let gradientPurple = NSColor(hex: "#2d2040")!
    static let gradientPink = NSColor(hex: "#3d2545")!
    static let gradientOrange = NSColor(hex: "#4a3028")!
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
}
