import AppKit
import ServiceManagement
import UniformTypeIdentifiers

final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let settings = Settings.shared
    private var statusItem: NSStatusItem!
    private var panel: OverlayPanel!
    private var charmView: CharmView!
    private var physicsTimer: Timer?
    private var lastMouse: CGPoint?
    private var charms: [Charm] = []

    private var focusEnd: Date?
    private var focusTimer: Timer?

    private let mainMenu = NSMenu()
    private let charmMenu = NSMenu()
    private let styleMenu = NSMenu()
    private var toggleItem: NSMenuItem!
    private var loginItem: NSMenuItem!
    private var focusStopItem: NSMenuItem!

    // MARK: launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        CharmLibrary.ensureFolder()
        charms = CharmLibrary.all()
        applyLaunchArguments()
        setupPanel()
        setupStatusItem()

        let t = Timer(timeInterval: 1.0 / 60.0, target: self, selector: #selector(tick),
                      userInfo: nil, repeats: true)
        RunLoop.main.add(t, forMode: .common)   // keeps animating while the menu is open
        physicsTimer = t

        NotificationCenter.default.addObserver(self, selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)

        if settings.hidden { panel.orderOut(nil) } else { panel.orderFrontRegardless() }
    }

    private var screen: NSScreen { NSScreen.screens.first ?? NSScreen.main! }

    private func anchorPoint(in bounds: NSRect) -> CGPoint {
        let menuBar = max(screen.frame.maxY - screen.visibleFrame.maxY, 0)
        return CGPoint(x: bounds.width * CGFloat(settings.position), y: menuBar)
    }

    private func currentCharm() -> Charm {
        charms.first { $0.name.caseInsensitiveCompare(settings.charmName) == .orderedSame } ?? charms[0]
    }

    /// Supports:  MyCharm NIMBU_MIRCH   or   MyCharm --charm NIMBU_MIRCH
    private func applyLaunchArguments() {
        // Used by install.sh: start automatically at login.
        if CommandLine.arguments.contains("--enable-login-item"), SMAppService.mainApp.status != .enabled {
            try? SMAppService.mainApp.register()
        }
        let args = Array(CommandLine.arguments.dropFirst()).filter { !$0.hasPrefix("-NS") && !$0.hasPrefix("-Apple") }
        var name: String?
        if let i = args.firstIndex(of: "--charm"), i + 1 < args.count { name = args[i + 1] }
        else if let first = args.first, !first.hasPrefix("-") { name = first }
        guard let wanted = name else { return }
        if let c = charms.first(where: { $0.name.caseInsensitiveCompare(wanted) == .orderedSame }) {
            settings.charmName = c.name
        } else {
            print("Unknown charm '\(wanted)'. Available: \(charms.map(\.name).joined(separator: ", "))")
        }
    }

    private func setupPanel() {
        let frame = screen.frame
        panel = OverlayPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel],
                             backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        panel.ignoresMouseEvents = true
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false

        let bounds = NSRect(origin: .zero, size: frame.size)
        let rope = Rope(anchor: anchorPoint(in: bounds), length: CGFloat(settings.stringLength))
        charmView = CharmView(frame: bounds, rope: rope, charm: currentCharm(),
                              style: settings.style, size: CGFloat(settings.charmSize))
        panel.contentView = charmView
        panel.setFrame(frame, display: true)
    }

    @objc private func screensChanged() {
        let frame = screen.frame
        panel.setFrame(frame, display: true)
        charmView.frame = NSRect(origin: .zero, size: frame.size)
        charmView.rope.anchor = anchorPoint(in: charmView.bounds)
        charmView.rope.reset()
        charmView.needsDisplay = true
    }

    // MARK: frame loop

    @objc private func tick() {
        guard panel.isVisible else { return }
        let m = NSEvent.mouseLocation
        let f = panel.frame
        let p = CGPoint(x: m.x - f.minX, y: f.maxY - m.y)

        // Only catch clicks when the pointer is on the charm; everything else passes through.
        let over = charmView.hits(p)
        let ignore = !(over || charmView.dragging)
        if panel.ignoresMouseEvents != ignore { panel.ignoresMouseEvents = ignore }

        // Hovering over the charm brushes it along.
        if over, !charmView.dragging, let lp = lastMouse {
            let d = p - lp
            if d.length > 0.5 { charmView.nudge(d * 0.3) }
        }
        lastMouse = p
        charmView.tick(dt: 1.0 / 60.0)
    }

    // MARK: menu

    private func item(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let i = NSMenuItem(title: title, action: action, keyEquivalent: key)
        i.target = self
        return i
    }

    private func sliderItem(_ title: String, _ min: Double, _ max: Double,
                            _ value: Double, _ action: Selector) -> NSMenuItem {
        let v = NSView(frame: NSRect(x: 0, y: 0, width: 240, height: 46))
        let label = NSTextField(labelWithString: title)
        label.frame = NSRect(x: 20, y: 26, width: 200, height: 16)
        label.font = .menuFont(ofSize: 12)
        label.textColor = .secondaryLabelColor
        let s = NSSlider(value: value, minValue: min, maxValue: max, target: self, action: action)
        s.frame = NSRect(x: 18, y: 4, width: 204, height: 20)
        s.isContinuous = true
        v.addSubview(label)
        v.addSubview(s)
        let i = NSMenuItem()
        i.view = v
        return i
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let b = statusItem.button {
            b.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "My Charm")
            b.imagePosition = .imageLeading
            b.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        }

        toggleItem = item("Hide Charm", #selector(toggleCharm))
        mainMenu.addItem(toggleItem)
        mainMenu.addItem(item("Reset Swing", #selector(resetSwing)))
        mainMenu.addItem(.separator())

        let charmParent = NSMenuItem(title: "Charm", action: nil, keyEquivalent: "")
        charmMenu.delegate = self
        charmParent.submenu = charmMenu
        mainMenu.addItem(charmParent)

        let styleParent = NSMenuItem(title: "String", action: nil, keyEquivalent: "")
        for s in StringStyle.allCases {
            let i = item(s.title, #selector(pickStyle(_:)))
            i.representedObject = s.rawValue
            styleMenu.addItem(i)
        }
        styleParent.submenu = styleMenu
        mainMenu.addItem(styleParent)

        mainMenu.addItem(.separator())
        mainMenu.addItem(sliderItem("Charm Size", 40, 220, settings.charmSize, #selector(sizeChanged(_:))))
        mainMenu.addItem(sliderItem("String Length", 40, 500, settings.stringLength, #selector(lengthChanged(_:))))
        mainMenu.addItem(sliderItem("Position", 0.03, 0.97, settings.position, #selector(positionChanged(_:))))
        mainMenu.addItem(.separator())

        let focusParent = NSMenuItem(title: "Focus Timer", action: nil, keyEquivalent: "")
        let fm = NSMenu()
        for m in [5, 15, 25, 45, 60] {
            let i = item("\(m) minutes", #selector(startFocus(_:)))
            i.tag = m
            fm.addItem(i)
        }
        fm.addItem(.separator())
        focusStopItem = item("Stop Timer", #selector(stopFocusAction))
        fm.addItem(focusStopItem)
        fm.addItem(item("Test Chime", #selector(testChime)))
        focusParent.submenu = fm
        mainMenu.addItem(focusParent)

        mainMenu.addItem(.separator())
        loginItem = item("Launch at Login", #selector(toggleLogin))
        mainMenu.addItem(loginItem)
        mainMenu.addItem(item("Quit My Charm", #selector(quit), key: "q"))

        mainMenu.delegate = self
        statusItem.menu = mainMenu
        refreshMenuState()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        if menu === charmMenu { rebuildCharmMenu() }
        refreshMenuState()
    }

    private func refreshMenuState() {
        toggleItem.title = settings.hidden ? "Show Charm" : "Hide Charm"
        for i in styleMenu.items {
            i.state = (i.representedObject as? String) == settings.style.rawValue ? .on : .off
        }
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        focusStopItem.isHidden = focusEnd == nil
    }

    private func thumbnail(_ img: NSImage) -> NSImage {
        let s: CGFloat = 18
        let ar = img.size.width / max(img.size.height, 1)
        let size = ar > 1 ? NSSize(width: s, height: s / ar) : NSSize(width: s * ar, height: s)
        return NSImage(size: size, flipped: false) { r in
            img.draw(in: r)
            return true
        }
    }

    private func rebuildCharmMenu() {
        charmMenu.removeAllItems()
        charms = CharmLibrary.all()
        for (idx, c) in charms.enumerated() {
            let i = item(c.name, #selector(pickCharm(_:)))
            i.tag = idx
            i.state = c.name.caseInsensitiveCompare(settings.charmName) == .orderedSame ? .on : .off
            if let img = c.image { i.image = thumbnail(img) }
            charmMenu.addItem(i)
        }
        charmMenu.addItem(.separator())
        charmMenu.addItem(item("Add Image…", #selector(addImage)))
        charmMenu.addItem(item("Open Charms Folder", #selector(openFolder)))
    }

    // MARK: actions

    @objc private func toggleCharm() {
        settings.hidden.toggle()
        if settings.hidden {
            panel.orderOut(nil)
        } else {
            panel.orderFrontRegardless()
            charmView.needsDisplay = true
        }
        refreshMenuState()
    }

    @objc private func resetSwing() {
        charmView.rope.reset()
        charmView.needsDisplay = true
    }

    @objc private func pickCharm(_ sender: NSMenuItem) {
        guard charms.indices.contains(sender.tag) else { return }
        let c = charms[sender.tag]
        settings.charmName = c.name
        charmView.charm = c
    }

    @objc private func pickStyle(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let s = StringStyle(rawValue: raw) else { return }
        settings.style = s
        charmView.style = s
        refreshMenuState()
    }

    @objc private func sizeChanged(_ s: NSSlider) {
        settings.charmSize = s.doubleValue
        charmView.charmSize = CGFloat(s.doubleValue)
    }

    @objc private func lengthChanged(_ s: NSSlider) {
        settings.stringLength = s.doubleValue
        charmView.rope.setLength(CGFloat(s.doubleValue))
        charmView.needsDisplay = true
    }

    @objc private func positionChanged(_ s: NSSlider) {
        settings.position = s.doubleValue
        charmView.rope.anchor = anchorPoint(in: charmView.bounds)
        charmView.needsDisplay = true
    }

    @objc private func addImage() {
        NSApp.activate(ignoringOtherApps: true)
        let p = NSOpenPanel()
        p.allowedContentTypes = [.png, .jpeg, .heic, .tiff]
        p.allowsMultipleSelection = true
        p.message = "Pick transparent PNGs for the best look"
        guard p.runModal() == .OK else { return }
        var lastName: String?
        for url in p.urls {
            let dest = CharmLibrary.userFolder.appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.removeItem(at: dest)
            if (try? FileManager.default.copyItem(at: url, to: dest)) != nil {
                lastName = url.deletingPathExtension().lastPathComponent
            }
        }
        charms = CharmLibrary.all()
        if let n = lastName, let c = charms.first(where: { $0.name == n }) {
            settings.charmName = n
            charmView.charm = c
        }
    }

    @objc private func openFolder() {
        CharmLibrary.ensureFolder()
        NSWorkspace.shared.open(CharmLibrary.userFolder)
    }

    // MARK: focus timer

    @objc private func startFocus(_ sender: NSMenuItem) {
        focusEnd = Date().addingTimeInterval(TimeInterval(sender.tag * 60))
        focusTimer?.invalidate()
        let t = Timer(timeInterval: 1, target: self, selector: #selector(updateFocus),
                      userInfo: nil, repeats: true)
        RunLoop.main.add(t, forMode: .common)
        focusTimer = t
        updateFocus()
        refreshMenuState()
    }

    @objc private func updateFocus() {
        guard let end = focusEnd else { return }
        let left = Int(ceil(end.timeIntervalSinceNow))
        if left <= 0 {
            stopFocus()
            celebrate()
            return
        }
        let text = String(format: "%d:%02d", left / 60, left % 60)
        statusItem.button?.title = " " + text
        charmView.timerText = text            // widget hanging under the charm
    }

    private func stopFocus() {
        focusTimer?.invalidate()
        focusTimer = nil
        focusEnd = nil
        statusItem.button?.title = ""
        charmView.timerText = nil
        refreshMenuState()
    }

    @objc private func stopFocusAction() { stopFocus() }

    private func celebrate() {
        if settings.hidden { toggleCharm() }
        charmView.kick()
        Chime.play()
        charmView.timerText = "Done!"
        perform(#selector(clearDoneBadge), with: nil, afterDelay: 6)
    }

    @objc private func clearDoneBadge() {
        if focusEnd == nil { charmView.timerText = nil }   // don't hide a newly started timer
    }

    @objc private func testChime() {
        charmView.kick()
        Chime.play()
    }

    // MARK: misc

    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSApp.activate(ignoringOtherApps: true)
            let a = NSAlert()
            a.messageText = "Couldn't change the login setting"
            a.informativeText = "Move My Charm into your Applications folder and try again.\n\n\(error.localizedDescription)"
            a.runModal()
        }
        refreshMenuState()
    }

    @objc private func quit() { NSApp.terminate(nil) }
}
