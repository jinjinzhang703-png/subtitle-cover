import AppKit

struct OverlaySettings: Codable, Equatable {
    static let defaultsKey = "subtitle_cover.overlay_settings"
    static let minWidth: CGFloat = 24
    static let minHeight: CGFloat = 16
    static let maxExtent: CGFloat = 16000

    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    static let fallback = OverlaySettings(
        x: 200, y: 80, width: 720, height: 64,
        red: 0, green: 0, blue: 0, alpha: 1
    )

    var rect: NSRect {
        NSRect(x: x, y: y, width: width, height: height)
    }

    var color: NSColor {
        NSColor(
            calibratedRed: red,
            green: green,
            blue: blue,
            alpha: min(1, max(0.1, alpha))
        )
    }

    mutating func apply(rect: NSRect) {
        x = rect.origin.x
        y = rect.origin.y
        width = rect.size.width
        height = rect.size.height
    }

    mutating func apply(color: NSColor) {
        let rgb = color.usingColorSpace(.deviceRGB) ?? color
        red = rgb.redComponent
        green = rgb.greenComponent
        blue = rgb.blueComponent
        alpha = min(1, max(0.1, rgb.alphaComponent))
    }

    func sanitized() -> OverlaySettings {
        var copy = self
        if !copy.width.isFinite || copy.width <= 0 { copy.width = Self.fallback.width }
        if !copy.height.isFinite || copy.height <= 0 { copy.height = Self.fallback.height }
        copy.width = min(Self.maxExtent, max(Self.minWidth, copy.width))
        copy.height = min(Self.maxExtent, max(Self.minHeight, copy.height))
        copy.alpha = min(1, max(0.1, copy.alpha.isFinite ? copy.alpha : 1))
        if !copy.x.isFinite { copy.x = Self.fallback.x }
        if !copy.y.isFinite { copy.y = Self.fallback.y }
        return copy
    }

    /// Move a saved frame back onto a screen when it no longer intersects any display.
    func placedOnScreen() -> OverlaySettings {
        let frame = sanitized().rect
        let screens = NSScreen.screens
        if screens.contains(where: { $0.frame.intersects(frame) }) {
            return sanitized()
        }
        guard let screen = NSScreen.main ?? screens.first else { return sanitized() }
        var copy = sanitized()
        let visible = screen.visibleFrame
        copy.x = visible.midX - copy.width / 2
        copy.y = visible.minY + 80
        return copy
    }
}

enum SettingsStore {
    static func load() -> OverlaySettings {
        guard
            let data = UserDefaults.standard.data(forKey: OverlaySettings.defaultsKey),
            let decoded = try? JSONDecoder().decode(OverlaySettings.self, from: data)
        else {
            return OverlaySettings.fallback.placedOnScreen()
        }
        return decoded.placedOnScreen()
    }

    static func save(_ settings: OverlaySettings) {
        let clean = settings.sanitized()
        guard let data = try? JSONEncoder().encode(clean) else { return }
        UserDefaults.standard.set(data, forKey: OverlaySettings.defaultsKey)
    }
}
