import AppKit

/// "#RRGGBB" / "#RRGGBBAA" 与 NSColor 的互转。
enum ColorHex {
    static func parse(_ hex: String) -> NSColor {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var value: UInt64 = 0
        guard Scanner(string: s).scanHexInt64(&value) else { return fallback() }
        let r, g, b: CGFloat
        switch s.count {
        case 6:
            r = CGFloat((value >> 16) & 0xFF) / 255
            g = CGFloat((value >> 8) & 0xFF) / 255
            b = CGFloat(value & 0xFF) / 255
        default:
            return fallback()
        }
        return NSColor(calibratedRed: r, green: g, blue: b, alpha: 1)
    }

    static func string(from color: NSColor) -> String {
        guard let rgb = color.usingColorSpace(.sRGB) else { return "#4C8DFF" }
        let r = Int((rgb.redComponent * 255).rounded())
        let g = Int((rgb.greenComponent * 255).rounded())
        let b = Int((rgb.blueComponent * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    private static func fallback() -> NSColor {
        NSColor(calibratedRed: 0x4C / 255.0, green: 0x8D / 255.0, blue: 0xFF / 255.0, alpha: 1)
    }
}
