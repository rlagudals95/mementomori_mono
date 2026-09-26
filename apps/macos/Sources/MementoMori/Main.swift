import AppKit
import SwiftUI
import CoreText
import Combine
import MementoCore

final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let store = Store()
    var panel: FloatingPanel!
    var settingsWindow: NSWindow?
    var statusItem: NSStatusItem!
    var observation: AnyCancellable?
    var isResizing = false
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let font = Bundle.main.url(forResource: "PretendardVariable", withExtension: "ttf") ?? Bundle.module.url(forResource: "PretendardVariable", withExtension: "ttf", subdirectory: "Resources") {
            CTFontManagerRegisterFontsForURL(font as CFURL, .process, nil)
        }
        NSApp.setActivationPolicy(.accessory)
        setupMenu()
        let variant = store.settings.widget.variant
        panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: variant.width, height: variant.height), styleMask: [.borderless, .nonactivatingPanel, .resizable], backing: .buffered, defer: false)
        panel.minSize = NSSize(width: 190, height: 84)
        panel.maxSize = NSSize(width: 1200, height: 1000)
        panel.title = "메멘토모리"; panel.level = .floating
        panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = true
        panel.hidesOnDeactivate = false; panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.delegate = self
        let host = NSHostingView(rootView: WidgetView(store: store, showSettings: { [weak self] in self?.showSettings() }))
        host.sizingOptions = []
        panel.contentView = host
        let savedWidth = UserDefaults.standard.double(forKey: "window.width")
        let savedHeight = UserDefaults.standard.double(forKey: "window.height")
        if savedWidth.isFinite && savedHeight.isFinite && savedWidth >= 190 && savedHeight >= 84 {
            panel.setContentSize(NSSize(width: min(savedWidth, 1200), height: min(savedHeight, 1000)))
        }
        restorePosition()
        panel.orderFrontRegardless()
        observation = store.$settings.map(\.widget.variant).removeDuplicates().dropFirst().sink { [weak self] variant in
            DispatchQueue.main.async { self?.resizeWidget(variant) }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(screensChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        if store.settings.state.profile == nil { showSettings() }
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        panel.orderFrontRegardless(); showSettings(); return true
    }
    func setupMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "hourglass", accessibilityDescription: "메멘토모리")
        let menu = NSMenu()
        let title = NSMenuItem(title: "메멘토모리", action: nil, keyEquivalent: ""); title.isEnabled = false; menu.addItem(title)
        add(menu, "작은 창 표시 / 숨기기", #selector(toggleWidget), "")
        add(menu, "설정…", #selector(showSettings), ",")
        add(menu, "기본 크기로 되돌리기", #selector(resetSize), "")
        add(menu, "창 위치 초기화", #selector(resetPosition), "")
        menu.addItem(.separator())
        add(menu, "종료", #selector(quit), "q")
        statusItem.menu = menu
        let main = NSMenu()
        let appMenu = NSMenu(); add(appMenu, "메멘토모리 종료", #selector(quit), "q")
        let appItem = NSMenuItem(); appItem.submenu = appMenu; main.addItem(appItem)
        let edit = NSMenu(title: "편집")
        for (name, action, key) in [("실행 취소", Selector(("undo:")), "z"), ("잘라내기", #selector(NSText.cut(_:)), "x"), ("복사", #selector(NSText.copy(_:)), "c"), ("붙여넣기", #selector(NSText.paste(_:)), "v"), ("모두 선택", #selector(NSText.selectAll(_:)), "a")] {
            edit.addItem(withTitle: name, action: action, keyEquivalent: key)
        }
        let editItem = NSMenuItem(); editItem.submenu = edit; main.addItem(editItem); NSApp.mainMenu = main
    }
    func add(_ menu: NSMenu, _ title: String, _ action: Selector, _ key: String) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key); item.target = self; menu.addItem(item)
    }
    @objc func showSettings() {
        if settingsWindow == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 710), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
            window.title = "메멘토모리 설정"; window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: SettingsView(store: store, showWidget: { [weak self] in self?.panel.orderFrontRegardless() }))
            window.center(); settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true); settingsWindow?.makeKeyAndOrderFront(nil)
    }
    @objc func toggleWidget() { if panel.isVisible { panel.orderOut(nil) } else { keepOnScreen(); panel.orderFrontRegardless() } }
    @objc func resetSize() { resizeWidget(store.settings.widget.variant) }
    @objc func quit() { NSApp.terminate(nil) }
    @objc func resetPosition() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        panel.setFrameOrigin(NSPoint(x: screen.visibleFrame.maxX - panel.frame.width - 28, y: screen.visibleFrame.minY + 28))
        panel.orderFrontRegardless(); savePosition()
    }
    func restorePosition() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "window.x") != nil {
            let x = defaults.double(forKey: "window.x"), y = defaults.double(forKey: "window.y")
            if x.isFinite && y.isFinite { panel.setFrameOrigin(NSPoint(x: x, y: y)); keepOnScreen(); return }
        }
        resetPosition()
    }
    func resizeWidget(_ variant: Variant) {
        guard panel != nil else { return }
        guard panel.frame.size != NSSize(width: variant.width, height: variant.height) else { keepOnScreen(); return }
        isResizing = true
        let frame = panel.frame
        panel.setFrame(NSRect(x: frame.minX, y: frame.maxY - variant.height, width: variant.width, height: variant.height), display: true)
        isResizing = false; keepOnScreen(); savePosition()
    }
    func keepOnScreen() {
        let frame = panel.frame
        let screen = NSScreen.screens.max { a, b in
            let x = a.visibleFrame.intersection(frame), y = b.visibleFrame.intersection(frame)
            return (x.isNull ? 0 : x.width * x.height) < (y.isNull ? 0 : y.width * y.height)
        }
        guard let bounds = screen?.visibleFrame else { return }
        if frame.width > bounds.width || frame.height > bounds.height {
            panel.setContentSize(NSSize(width: min(frame.width, bounds.width), height: min(frame.height, bounds.height)))
        }
        let adjusted = panel.frame
        panel.setFrameOrigin(NSPoint(x: max(bounds.minX, min(adjusted.minX, bounds.maxX - adjusted.width)), y: max(bounds.minY, min(adjusted.minY, bounds.maxY - adjusted.height))))
    }
    @objc func screensChanged() { keepOnScreen(); savePosition() }
    func windowDidEndLiveResize(_ notification: Notification) { keepOnScreen(); savePosition() }
    func windowDidResize(_ notification: Notification) { if !isResizing { savePosition() } }
    func windowDidMove(_ notification: Notification) { if !isResizing { savePosition() } }
    func savePosition() {
        guard panel != nil else { return }
        UserDefaults.standard.set(panel.frame.width, forKey: "window.width")
        UserDefaults.standard.set(panel.frame.height, forKey: "window.height")
        UserDefaults.standard.set(panel.frame.minX, forKey: "window.x")
        UserDefaults.standard.set(panel.frame.minY, forKey: "window.y")
    }
}

@main enum MementoMoriMain {
    @MainActor static func main() {
        let app = NSApplication.shared
        // A second launch should reveal the running app rather than create duplicate counters.
        if let identifier = Bundle.main.bundleIdentifier,
           let other = NSRunningApplication.runningApplications(withBundleIdentifier: identifier).first(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
            other.activate(options: [.activateIgnoringOtherApps]); return
        }
        let delegate = AppDelegate(); app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
}
