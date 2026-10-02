import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, OverlayViewDelegate {
    private var panel: NSPanel!
    private var overlay: OverlayView!
    private var settings: OverlaySettings = SettingsStore.load()
    private var settingsPanel: NSPanel?
    private var opacitySlider: NSSlider?
    private var sizeLabel: NSTextField?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let view = OverlayView(frame: NSRect(origin: .zero, size: settings.rect.size))
        view.fillColor = settings.color
        view.delegate = self
        overlay = view

        let panel = NSPanel(
            contentRect: settings.rect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = overlayLevel
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.isMovableByWindowBackground = false
        panel.isRestorable = false
        panel.contentView = view
        panel.setFrame(settings.rect, display: true)
        view.autoresizingMask = [.width, .height]
        panel.orderFrontRegardless()
        self.panel = panel

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(colorPanelChanged(_:)),
            name: NSColorPanel.colorDidChangeNotification,
            object: NSColorPanel.shared
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private var overlayLevel: NSWindow.Level {
        NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)))
    }

    private func persistFrame() {
        settings.apply(rect: panel.frame)
        SettingsStore.save(settings)
        refreshSizeLabel()
    }

    private func applyColor() {
        overlay.fillColor = settings.color
        overlay.needsDisplay = true
        SettingsStore.save(settings)
        opacitySlider?.doubleValue = settings.alpha * 100
    }

    func overlayDidChangeFrame(_ view: OverlayView) {
        persistFrame()
    }

    func overlayDidRequestSettings(_ view: OverlayView) {
        showSettings()
    }

    func overlayDidRequestMenu(_ view: OverlayView, event: NSEvent) {
        let menu = NSMenu()
        menu.addItem(item("设置…", #selector(showSettings)))
        menu.addItem(item("选择颜色…", #selector(pickColor)))
        menu.addItem(.separator())
        menu.addItem(item("重置大小", #selector(resetSize)))
        menu.addItem(item("水平居中", #selector(centerHorizontally)))
        menu.addItem(.separator())
        menu.addItem(item("使用说明", #selector(showHelp)))
        menu.addItem(item("退出", #selector(quit)))
        NSMenu.popUpContextMenu(menu, with: event, for: view)
    }

    private func item(_ title: String, _ action: Selector) -> NSMenuItem {
        NSMenuItem(title: title, action: action, keyEquivalent: "")
    }

    @objc private func showSettings() {
        if settingsPanel == nil {
            settingsPanel = makeSettingsPanel()
        }
        refreshSizeLabel()
        opacitySlider?.doubleValue = settings.alpha * 100
        settingsPanel?.level = NSWindow.Level(rawValue: overlayLevel.rawValue + 2)
        settingsPanel?.center()
        settingsPanel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func pickColor() {
        let panel = NSColorPanel.shared
        panel.color = settings.color
        panel.showsAlpha = true
        panel.isContinuous = true
        panel.level = NSWindow.Level(rawValue: overlayLevel.rawValue + 3)
        panel.orderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func colorPanelChanged(_ notification: Notification) {
        guard settingsPanel?.isVisible == true || NSColorPanel.shared.isVisible else { return }
        settings.apply(color: NSColorPanel.shared.color)
        applyColor()
    }

    @objc private func opacityChanged(_ sender: NSSlider) {
        let rgb = settings.color.usingColorSpace(.deviceRGB) ?? settings.color
        settings.apply(color: rgb.withAlphaComponent(sender.doubleValue / 100))
        applyColor()
    }

    @objc private func presetColor(_ sender: NSButton) {
        let presets: [NSColor] = [.black, .white, .darkGray, NSColor(calibratedRed: 0.07, green: 0.09, blue: 0.16, alpha: 1)]
        let index = min(max(0, sender.tag), presets.count - 1)
        let chosen = presets[index].withAlphaComponent(settings.alpha)
        settings.apply(color: chosen)
        applyColor()
        NSColorPanel.shared.color = settings.color
    }

    @objc private func resetSize() {
        var frame = panel.frame
        frame.size = NSSize(width: 720, height: 64)
        panel.setFrame(frame, display: true)
        persistFrame()
    }

    @objc private func centerHorizontally() {
        guard let screen = panel.screen ?? NSScreen.main else { return }
        var frame = panel.frame
        frame.origin.x = screen.visibleFrame.midX - frame.width / 2
        panel.setFrame(frame, display: true)
        persistFrame()
    }

    @objc private func showHelp() {
        let alert = NSAlert()
        alert.messageText = "Subtitle Cover"
        alert.informativeText = """
        拖动中间：移动遮挡条。
        拖动任意一条边或一个角：自由改变宽度和高度。
        触控板双指捏合：按比例缩放。
        按住 Control 再拖：直接画出一块新的遮挡区域。
        双击：打开设置。右键：打开菜单。
        """
        alert.addButton(withTitle: "好")
        alert.runModal()
    }

    @objc private func quit() {
        persistFrame()
        NSApp.terminate(nil)
    }

    private func refreshSizeLabel() {
        guard let panel else { return }
        let size = panel.frame.size
        sizeLabel?.stringValue = String(format: "当前大小  %.0f × %.0f", size.width, size.height)
    }

    private func makeSettingsPanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 228),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = "遮挡设置"
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false

        let content = NSView(frame: panel.contentView?.bounds ?? .zero)
        content.autoresizingMask = [.width, .height]

        let hint = label("拖任意边或角即可拉伸。触控板双指捏合可以按比例缩放。", y: 184, width: 308)
        hint.font = .systemFont(ofSize: 12)
        hint.textColor = .secondaryLabelColor
        content.addSubview(hint)

        sizeLabel = label("", y: 156, width: 308)
        sizeLabel?.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        content.addSubview(sizeLabel!)

        content.addSubview(label("不透明度", y: 122, width: 70))
        let slider = NSSlider(value: settings.alpha * 100, minValue: 10, maxValue: 100, target: self, action: #selector(opacityChanged(_:)))
        slider.frame = NSRect(x: 86, y: 120, width: 230, height: 24)
        slider.numberOfTickMarks = 0
        content.addSubview(slider)
        opacitySlider = slider

        content.addSubview(label("颜色", y: 78, width: 70))
        let names = ["黑色", "白色", "灰色", "深蓝"]
        for (index, name) in names.enumerated() {
            let button = NSButton(title: name, target: self, action: #selector(presetColor(_:)))
            button.tag = index
            button.bezelStyle = .rounded
            button.frame = NSRect(x: 86 + index * 60, y: 72, width: 56, height: 28)
            content.addSubview(button)
        }

        let custom = NSButton(title: "自定颜色…", target: self, action: #selector(pickColor))
        custom.bezelStyle = .rounded
        custom.frame = NSRect(x: 86, y: 32, width: 110, height: 28)
        content.addSubview(custom)

        let reset = NSButton(title: "重置大小", target: self, action: #selector(resetSize))
        reset.bezelStyle = .rounded
        reset.frame = NSRect(x: 206, y: 32, width: 110, height: 28)
        content.addSubview(reset)

        panel.contentView = content
        return panel
    }

    private func label(_ text: String, y: CGFloat, width: CGFloat) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.frame = NSRect(x: 16, y: y, width: width, height: 20)
        return field
    }
}
