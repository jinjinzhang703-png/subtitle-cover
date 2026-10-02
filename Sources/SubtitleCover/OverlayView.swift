import AppKit

struct ResizeEdges: OptionSet {
    let rawValue: Int
    static let left = ResizeEdges(rawValue: 1 << 0)
    static let right = ResizeEdges(rawValue: 1 << 1)
    static let bottom = ResizeEdges(rawValue: 1 << 2)
    static let top = ResizeEdges(rawValue: 1 << 3)

    var isCorner: Bool {
        let horizontal = contains(.left) || contains(.right)
        let vertical = contains(.bottom) || contains(.top)
        return horizontal && vertical
    }
}

/// Opposite-edge-anchored resize. Each grabbed edge moves with the pointer
/// and stops at the minimum size instead of flipping past the opposite edge.
func resizedFrame(start: NSRect, delta: CGPoint, edges: ResizeEdges) -> NSRect {
    let minW = OverlaySettings.minWidth
    let minH = OverlaySettings.minHeight
    let maxE = OverlaySettings.maxExtent
    var frame = start

    if edges.contains(.left) {
        let width = min(maxE, max(minW, start.width - delta.x))
        frame.origin.x = start.maxX - width
        frame.size.width = width
    } else if edges.contains(.right) {
        frame.size.width = min(maxE, max(minW, start.width + delta.x))
    }

    if edges.contains(.bottom) {
        let height = min(maxE, max(minH, start.height - delta.y))
        frame.origin.y = start.maxY - height
        frame.size.height = height
    } else if edges.contains(.top) {
        frame.size.height = min(maxE, max(minH, start.height + delta.y))
    }

    return frame
}

protocol OverlayViewDelegate: AnyObject {
    func overlayDidChangeFrame(_ view: OverlayView)
    func overlayDidRequestMenu(_ view: OverlayView, event: NSEvent)
    func overlayDidRequestSettings(_ view: OverlayView)
}

final class OverlayView: NSView {
    weak var delegate: OverlayViewDelegate?
    var fillColor: NSColor = .black

    private enum DragMode {
        case none
        case move
        case resize
        case select
    }

    private var mode: DragMode = .none
    private var resizeEdges: ResizeEdges = []
    private var dragStartScreen = CGPoint.zero
    private var dragStartFrame = NSRect.zero
    private var didDrag = false

    override var isFlipped: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        fillColor.setFill()
        bounds.fill()

        let grip = gripColor
        grip.setStroke()
        let border = NSBezierPath(rect: bounds.insetBy(dx: 0.5, dy: 0.5))
        border.lineWidth = 1
        border.stroke()

        guard bounds.width >= 36, bounds.height >= 28 else { return }
        let length = min(14, min(bounds.width, bounds.height) / 3)
        let inset: CGFloat = 3
        let corners: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (inset, inset, 1, 1),
            (bounds.maxX - inset, inset, -1, 1),
            (inset, bounds.maxY - inset, 1, -1),
            (bounds.maxX - inset, bounds.maxY - inset, -1, -1),
        ]
        for (x, y, sx, sy) in corners {
            let path = NSBezierPath()
            path.move(to: NSPoint(x: x + sx * length, y: y))
            path.line(to: NSPoint(x: x, y: y))
            path.line(to: NSPoint(x: x, y: y + sy * length))
            path.lineWidth = 2
            path.stroke()
        }
    }

    private var gripColor: NSColor {
        let rgb = fillColor.usingColorSpace(.deviceRGB) ?? fillColor
        let luminance = 0.299 * rgb.redComponent + 0.587 * rgb.greenComponent + 0.114 * rgb.blueComponent
        return luminance > 0.55 ? NSColor.black.withAlphaComponent(0.85) : NSColor.white.withAlphaComponent(0.9)
    }

    /// Edge bands shrink on a short subtitle bar so the middle stays draggable.
    private var hitThickness: CGFloat {
        let band = min(bounds.width, bounds.height) / 3
        return min(14, max(6, band))
    }

    func edges(at point: NSPoint) -> ResizeEdges {
        guard bounds.contains(point) else { return [] }
        let t = hitThickness
        var edges: ResizeEdges = []
        if point.x <= bounds.minX + t { edges.insert(.left) }
        else if point.x >= bounds.maxX - t { edges.insert(.right) }
        if point.y <= bounds.minY + t { edges.insert(.bottom) }
        else if point.y >= bounds.maxY - t { edges.insert(.top) }
        return edges
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        let t = hitThickness
        let horizontal = NSCursor.resizeLeftRight
        let vertical = NSCursor.resizeUpDown
        let corner = NSCursor.crosshair

        addCursorRect(NSRect(x: t, y: 0, width: max(0, bounds.width - 2 * t), height: t), cursor: vertical)
        addCursorRect(NSRect(x: t, y: bounds.maxY - t, width: max(0, bounds.width - 2 * t), height: t), cursor: vertical)
        addCursorRect(NSRect(x: 0, y: t, width: t, height: max(0, bounds.height - 2 * t)), cursor: horizontal)
        addCursorRect(NSRect(x: bounds.maxX - t, y: t, width: t, height: max(0, bounds.height - 2 * t)), cursor: horizontal)

        addCursorRect(NSRect(x: 0, y: 0, width: t, height: t), cursor: corner)
        addCursorRect(NSRect(x: bounds.maxX - t, y: 0, width: t, height: t), cursor: corner)
        addCursorRect(NSRect(x: 0, y: bounds.maxY - t, width: t, height: t), cursor: corner)
        addCursorRect(NSRect(x: bounds.maxX - t, y: bounds.maxY - t, width: t, height: t), cursor: corner)

        let interior = bounds.insetBy(dx: t, dy: t)
        if interior.width > 0, interior.height > 0 {
            addCursorRect(interior, cursor: .openHand)
        }
    }

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        if event.clickCount >= 2 {
            delegate?.overlayDidRequestSettings(self)
            return
        }
        dragStartScreen = NSEvent.mouseLocation
        dragStartFrame = window.frame
        didDrag = false
        if event.modifierFlags.contains(.control) {
            mode = .select
        } else {
            let point = convert(event.locationInWindow, from: nil)
            resizeEdges = edges(at: point)
            mode = resizeEdges.isEmpty ? .move : .resize
            if mode == .move { NSCursor.closedHand.set() }
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window, mode != .none else { return }
        let current = NSEvent.mouseLocation
        let delta = CGPoint(x: current.x - dragStartScreen.x, y: current.y - dragStartScreen.y)
        if hypot(delta.x, delta.y) > 2 { didDrag = true }

        switch mode {
        case .move:
            window.setFrameOrigin(NSPoint(
                x: dragStartFrame.origin.x + delta.x,
                y: dragStartFrame.origin.y + delta.y
            ))
        case .resize:
            window.setFrame(resizedFrame(start: dragStartFrame, delta: delta, edges: resizeEdges), display: true)
            window.contentView?.needsDisplay = true
        case .select:
            let rect = NSRect(
                x: min(dragStartScreen.x, current.x),
                y: min(dragStartScreen.y, current.y),
                width: abs(current.x - dragStartScreen.x),
                height: abs(current.y - dragStartScreen.y)
            )
            window.setFrame(rect, display: true)
        case .none:
            break
        }
    }

    override func mouseUp(with event: NSEvent) {
        guard let window else { return }
        let ending = mode
        mode = .none
        NSCursor.arrow.set()
        window.invalidateCursorRects(for: self)

        if ending == .select, !didDrag {
            delegate?.overlayDidRequestMenu(self, event: event)
            return
        }
        if ending == .select {
            var frame = window.frame
            frame.size.width = max(OverlaySettings.minWidth, frame.width)
            frame.size.height = max(OverlaySettings.minHeight, frame.height)
            window.setFrame(frame, display: true)
        }
        if ending != .none {
            delegate?.overlayDidChangeFrame(self)
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        delegate?.overlayDidRequestMenu(self, event: event)
    }

    override func magnify(with event: NSEvent) {
        guard let window else { return }
        let frame = window.frame
        let factor = 1 + event.magnification
        guard factor.isFinite, factor > 0 else { return }
        let width = min(OverlaySettings.maxExtent, max(OverlaySettings.minWidth, frame.width * factor))
        let height = min(OverlaySettings.maxExtent, max(OverlaySettings.minHeight, frame.height * factor))
        let next = NSRect(
            x: frame.midX - width / 2,
            y: frame.midY - height / 2,
            width: width,
            height: height
        )
        window.setFrame(next, display: true)
        if event.phase == .ended || event.phase == .cancelled || event.phase == [] {
            delegate?.overlayDidChangeFrame(self)
        }
    }
}
