import AppKit

let delegate = AppDelegate()
let app = NSApplication.shared

let alreadyRunning = NSRunningApplication.runningApplications(withBundleIdentifier: "com.subtitlecover.app")
    .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
if let existing = alreadyRunning.first {
    existing.activate(options: [.activateAllWindows])
    exit(0)
}

app.setActivationPolicy(.regular)
app.delegate = delegate
app.run()
